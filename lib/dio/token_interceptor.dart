import 'package:dio/dio.dart';
import 'package:fixify_admin/config/api_config.dart';
import 'package:fixify_admin/dio/token_manager.dart';

class TokenInterceptor extends QueuedInterceptor {
  final TokenManager tokenManager;
  bool _isRefreshing = false;

  // Static flag to communicate with UnauthorizedInterceptor
  static bool refreshFailed = false;

  TokenInterceptor({required this.tokenManager});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print(
      '🔄 [TokenInterceptor] onError - Status: ${err.response?.statusCode}',
    );
    print('🔄 [TokenInterceptor] Path: ${err.requestOptions.path}');

    // Not a 401 → let it pass
    if (err.response?.statusCode != 401) {
      print('🔄 [TokenInterceptor] Not a 401, passing through');
      return handler.next(err);
    }

    // Already retried → mark as refresh failed and let UnauthorizedInterceptor handle
    if (err.requestOptions.extra['isRetry'] == true) {
      print('🔄 [TokenInterceptor] Already retried, marking refresh as failed');
      refreshFailed = true;
      return handler.next(err);
    }

    final refreshToken = await tokenManager.getRefreshToken();
    print(
      '🔄 [TokenInterceptor] Refresh token exists: ${refreshToken != null}',
    );

    if (refreshToken == null || refreshToken.isEmpty) {
      print('🔄 [TokenInterceptor] No refresh token, marking as failed');
      refreshFailed = true;
      return handler.next(err);
    }

    // If refresh already running → wait for it to complete
    if (_isRefreshing) {
      print('🔄 [TokenInterceptor] Refresh already in progress, waiting...');
      // Wait for refresh to complete with longer timeout
      int attempts = 0;
      while (_isRefreshing && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }

      if (refreshFailed) {
        print('🔄 [TokenInterceptor] Previous refresh failed');
        return handler.next(err);
      }

      final token = await tokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        print('🔄 [TokenInterceptor] Using new token from completed refresh');
        final retryDio = Dio(
          BaseOptions(
            baseUrl: err.requestOptions.baseUrl,
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        err.requestOptions.extra['isRetry'] = true;

        try {
          final retryResponse = await retryDio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (retryErr) {
          print('🔄 [TokenInterceptor] Retry after wait failed: $retryErr');
          return handler.next(err);
        }
      }

      print('🔄 [TokenInterceptor] No token available after wait');
      return handler.next(err);
    }

    _isRefreshing = true;
    refreshFailed = false;
    print('🔄 [TokenInterceptor] Starting token refresh...');

    try {
      // ISOLATED DIO (NO INTERCEPTORS) for refresh call
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: err.requestOptions.baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      print('🔄 [TokenInterceptor] Calling refresh endpoint...');
      final response = await refreshDio.post(
        ApiConfig.partnerRefreshToken,
        data: {'refresh_token': refreshToken},
      );

      print('🔄 [TokenInterceptor] Refresh response: ${response.statusCode}');
      print('🔄 [TokenInterceptor] Refresh data: ${response.data}');

      // Handle different possible response structures
      final responseData = response.data;
      String? newAccess;
      String? newRefresh;

      if (responseData is Map) {
        // Try different possible key names
        newAccess =
            responseData['access_token'] ??
            responseData['token'] ??
            responseData['data']?['token'] ??
            responseData['data']?['access_token'];
        newRefresh =
            responseData['refresh_token'] ??
            responseData['data']?['refresh_token'];
      }

      if (newAccess == null || newAccess.isEmpty) {
        print('🔄 [TokenInterceptor] No access token in refresh response');
        refreshFailed = true;
        await tokenManager.clearTokens();
        return handler.next(err);
      }

      print('🔄 [TokenInterceptor] Token refresh successful!');
      await tokenManager.saveTokens(newAccess, newRefresh ?? refreshToken);

      // Retry original request with new token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      err.requestOptions.extra['isRetry'] = true;

      print('🔄 [TokenInterceptor] Retrying original request...');
      final retryResponse = await refreshDio.fetch(err.requestOptions);
      print('🔄 [TokenInterceptor] Retry successful!');

      return handler.resolve(retryResponse);
    } catch (e) {
      print('🔄 [TokenInterceptor] Refresh failed with error: $e');
      refreshFailed = true;
      await tokenManager.clearTokens();

      // Mark error as refresh-failed for UnauthorizedInterceptor
      err.requestOptions.extra['refreshFailed'] = true;
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}

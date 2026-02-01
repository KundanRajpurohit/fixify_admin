import 'package:dio/dio.dart';
import 'package:fixify_admin/dio/token_manager.dart';

class TokenInterceptor extends QueuedInterceptor {
  final TokenManager tokenManager;
  bool _isRefreshing = false;

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
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Not a 401 OR already retried → let it pass
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['isRetry'] == true) {
      return handler.next(err);
    }

    final refreshToken = await tokenManager.getRefreshToken();
    if (refreshToken == null) {
      return handler.next(err);
    }

    // If refresh already running → wait
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 300));
      final token = await tokenManager.getAccessToken();

      if (token != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        err.requestOptions.extra['isRetry'] = true;
        return handler.resolve(await Dio().fetch(err.requestOptions));
      }

      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      // ⚠️ ISOLATED DIO (NO INTERCEPTORS)
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: err.requestOptions.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        '/partner/refresh-token',
        data: {'refresh_token': refreshToken},
      );

      final newAccess = response.data['access_token'];
      final newRefresh = response.data['refresh_token'];

      await tokenManager.saveTokens(newAccess, newRefresh);

      err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess'
        ..extra['isRetry'] = true;

      return handler.resolve(
        await refreshDio.fetch(err.requestOptions),
      );
    } catch (e) {
      await tokenManager.clearTokens();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}

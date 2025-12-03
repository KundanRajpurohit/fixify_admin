// token_interceptor.dart
import 'package:dio/dio.dart';

import 'package:fixify_admin/dio/token_manager.dart';

class TokenInterceptor extends QueuedInterceptor {
  final Dio dio;
  final TokenManager tokenManager;
  final Function() onUnauthorized;
  
  bool _isRefreshing = false;

  TokenInterceptor({
    required this.dio,
    required this.tokenManager,
    required this.onUnauthorized,
  });

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
    if (err.response?.statusCode == 401) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        
        try {
          final refreshToken = await tokenManager.getRefreshToken();
          
          if (refreshToken == null) {
            onUnauthorized();
            return handler.reject(err);
          }

          // Refresh token API call
          final response = await dio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
          );

          final newAccessToken = response.data['access_token'];
          final newRefreshToken = response.data['refresh_token'];
          
          await tokenManager.saveTokens(newAccessToken, newRefreshToken);

          // Retry original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          
          final retryResponse = await dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
          
        } catch (e) {
          onUnauthorized();
          return handler.reject(err);
        } finally {
          _isRefreshing = false;
        }
      } else {
        // Wait for refresh to complete
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          final token = await tokenManager.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final retryResponse = await dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          return handler.reject(err);
        }
      }
    }
    
    handler.next(err);
  }
}

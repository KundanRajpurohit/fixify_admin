import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final List<String> protectedPaths;

  AuthInterceptor({required this.protectedPaths});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Check if the current path matches any protected path
      final shouldAddToken = protectedPaths.any(
        (path) => options.path.contains(path),
      );

      if (shouldAddToken) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authorization_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔑 [AuthInterceptor] Added Bearer token to ${options.path}');
        } else {
          print('⚠️ [AuthInterceptor] No token found for ${options.path}');
        }
      } else {
        print('🚫 [AuthInterceptor] Skipped token for ${options.path}');
      }
    } catch (e) {
      print('❌ [AuthInterceptor] Error while adding token: $e');
    }

    super.onRequest(options, handler);
  }
}

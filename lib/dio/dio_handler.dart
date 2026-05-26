import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fixify_admin/dio/resulr.dart';
import 'package:fixify_admin/dio/token_interceptor.dart';
import 'package:fixify_admin/dio/token_manager.dart';
import 'package:fpdart/fpdart.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiHandler {
  late final Dio _dio;
  final TokenManager _tokenManager;

  ApiHandler({required String baseUrl, required TokenManager tokenManager})
    : _tokenManager = tokenManager {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Logger
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );

    // ✅ Token attach + refresh ONLY
    _dio.interceptors.add(TokenInterceptor(tokenManager: _tokenManager));

    // ❗ UnauthorizedInterceptor is added OUTSIDE
    // (usually in main.dart so it has navigatorKey)
  }

  // ---------------- REQUESTS ----------------

  Future<ApiResult<T>> get<T>({
    required String endpoint,
    Map<String, dynamic>? queryParams,
    T Function(dynamic json)? parser,
  }) {
    return _handleRequest<T>(
      () => _dio.get(endpoint, queryParameters: queryParams),
      parser,
    );
  }

  Future<ApiResult<T>> post<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    T Function(dynamic json)? parser,
  }) {
    return _handleRequest<T>(() => _dio.post(endpoint, data: data), parser);
  }

  Future<ApiResult<T>> put<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    T Function(dynamic json)? parser,
  }) {
    return _handleRequest<T>(() => _dio.put(endpoint, data: data), parser);
  }

  Future<ApiResult<T>> delete<T>({
    required String endpoint,
    T Function(dynamic json)? parser,
  }) {
    return _handleRequest<T>(() => _dio.delete(endpoint), parser);
  }

  // ---------------- CORE HANDLER ----------------

  Future<ApiResult<T>> _handleRequest<T>(
    Future<Response> Function() request,
    T Function(dynamic json)? parser,
  ) async {
    try {
      final response = await request();

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        try {
          final data =
              parser != null ? parser(response.data) : response.data as T;
          return right(data);
        } catch (_) {
          return left(const ParseFailure());
        }
      }

      return left(
        ServerFailure(
          response.statusMessage ?? 'Server error',
          response.statusCode ?? 500,
        ),
      );
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } on SocketException {
      return left(const NetworkFailure());
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // ---------------- ERROR MAPPING ----------------

  ApiFailure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerFailure('Request timeout', 408);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final message =
            error.response?.data?['message'] ??
            error.response?.statusMessage ??
            'Server error';

        if (statusCode == 401) {
          return const UnauthorizedFailure();
        }

        return ServerFailure(message, statusCode);

      case DioExceptionType.cancel:
        return const UnknownFailure('Request cancelled');

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      default:
        return UnknownFailure(error.message ?? 'Unknown error');
    }
  }
}

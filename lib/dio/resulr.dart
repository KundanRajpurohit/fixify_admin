// result.dart
import 'package:fpdart/fpdart.dart';

typedef ApiResult<T> = Either<ApiFailure, T>;

sealed class ApiFailure {
  final String message;
  final int? statusCode;

  const ApiFailure(this.message, [this.statusCode]);
}

class NetworkFailure extends ApiFailure {
  const NetworkFailure() : super('No internet connection');
}

class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure() : super('Session expired', 401);
}

class ServerFailure extends ApiFailure {
  const ServerFailure(String message, int statusCode)
    : super(message, statusCode);
}

class ParseFailure extends ApiFailure {
  const ParseFailure() : super('Failed to parse response');
}

class UnknownFailure extends ApiFailure {
  const UnknownFailure(String message) : super(message);
}

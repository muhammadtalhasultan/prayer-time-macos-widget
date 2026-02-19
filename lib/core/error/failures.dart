import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Base failure class for all error handling
class Failure extends Equatable {
  final String message;
  final int? statusCode;
  final dynamic errorData;

  const Failure(this.message, {this.statusCode, this.errorData});

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => message;
}

/// Failure for server errors (5xx status codes)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode, super.errorData});
}

/// Failure for client errors (4xx status codes)
class ClientFailure extends Failure {
  const ClientFailure(super.message, {super.statusCode, super.errorData});
}

/// Failure for network connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.statusCode, super.errorData});
}

/// Failure for request cancellation
class CancellationFailure extends Failure {
  const CancellationFailure(super.message, {super.statusCode, super.errorData});
}

/// Failure for request timeout
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.statusCode, super.errorData});
}

/// Failure for authentication errors (401, 403)
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(
    super.message, {
    super.statusCode,
    super.errorData,
  });
}

/// Failure for validation errors (400)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.statusCode, super.errorData});
}

/// Failure for resource not found (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.statusCode, super.errorData});
}

/// Failure for unknown/unhandled errors
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.statusCode, super.errorData});
}

/// Failure for cache/local storage issues
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.statusCode, super.errorData});
}

// Legacy classes - kept for backward compatibility
// Represent failures from Server/Remote data source.
class RemoteFailure extends Failure {
  final DioExceptionType errorType;

  final int? errorCode;

  const RemoteFailure({
    this.errorCode,
    required String message,
    required this.errorType,
  }) : super(message, statusCode: errorCode);

  @override
  List<Object?> get props => [errorType, errorCode];
}

// Represent failures from Cache.
class LocalFailure extends Failure {
  final int error;
  final String? extraInfo;

  const LocalFailure({
    required String message,
    required this.error,
    this.extraInfo,
  }) : super(message);

  @override
  List<Object?> get props => [error, extraInfo];
}

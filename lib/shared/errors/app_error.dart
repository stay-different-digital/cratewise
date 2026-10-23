import 'dart:developer' as dev;

sealed class AppError implements Exception {
  const AppError();
}

class InvalidTokenError extends AppError {
  const InvalidTokenError();
}

class RateLimitedError extends AppError {
  const RateLimitedError();
}

class NetworkError extends AppError {
  const NetworkError();
}

class DiscogsUnavailableError extends AppError {
  const DiscogsUnavailableError();
}

class UnexpectedApiError extends AppError {
  const UnexpectedApiError(this.statusCode);
  final int statusCode;
}

class StorageError extends AppError {
  const StorageError();
}

class NoTokenError extends AppError {
  const NoTokenError();
}

/// Logs an error that a use case turns into a safe fallback (US-132), so
/// bugs show up in the debug log instead of vanishing. [AppError]s are
/// expected outcomes and are not logged.
void logSwallowed(Object error, StackTrace stack, String where) {
  if (error is AppError) return;
  dev.log(
    'Unexpected error in $where',
    name: 'cratewise',
    error: error,
    stackTrace: stack,
    level: 1000,
  );
}

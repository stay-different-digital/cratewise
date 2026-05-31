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

import '../../shared/errors/app_error.dart';

abstract interface class TokenStorage {
  Future<String?> loadToken();
  Future<String?> loadUsername();
  Future<void> saveCredentials({
    required String token,
    required String username,
  });
  Future<void> deleteCredentials();
}

/// Silently deletes stored credentials when a Discogs API call returns 401.
///
/// Call this whenever a service catches [InvalidTokenError] from a real API
/// call so that subsequent app launches show the disconnected state rather
/// than a stale "connected as @username" banner.
extension TokenRevocationGuard on TokenStorage {
  Future<void> clearIfRevoked(AppError error) async {
    if (error is! InvalidTokenError) return;
    try {
      await deleteCredentials();
    } catch (_) {}
  }
}

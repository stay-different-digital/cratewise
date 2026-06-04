import '../../domain/models/connection_status.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';
import 'token_validation_service.dart';

class DiscogsConnectionService {
  DiscogsConnectionService({
    TokenStorage? storage,
    TokenValidationService? validationService,
  }) : _storage = storage ?? DiscogsTokenStorage(),
       _validation = validationService ?? TokenValidationService();

  final TokenStorage _storage;
  final TokenValidationService _validation;

  /// Returns connected status with stored username, or disconnected on any
  /// storage failure (so the widget degrades gracefully in test environments).
  ///
  /// Both the token and the username must be present; a half-written credential
  /// pair (token without username, or vice versa) is treated as disconnected so
  /// the user is prompted to reconnect rather than silently failing later.
  Future<ConnectionStatus> loadStatus() async {
    try {
      final token = await _storage.loadToken();
      final username = await _storage.loadUsername();
      return (token != null && username != null)
          ? ConnectionStatus.connected(username)
          : const ConnectionStatus.disconnected();
    } catch (_) {
      return const ConnectionStatus.disconnected();
    }
  }

  /// Validates [token] against the Discogs API, then saves it.
  /// Throws [AppError] subtypes on validation failure, [StorageError] if the
  /// token validates but cannot be persisted.
  Future<String> connect(String token) async {
    final identity = await _validation.validateToken(token);
    await _storage.saveCredentials(token: token, username: identity.username);
    return identity.username;
  }

  Future<void> disconnect() => _storage.deleteCredentials();
}

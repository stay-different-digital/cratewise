import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/token_storage.dart';
import '../../shared/errors/app_error.dart';

class DiscogsTokenStorage implements TokenStorage {
  DiscogsTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'discogs_token';
  static const _usernameKey = 'discogs_username';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> loadToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      throw const StorageError();
    }
  }

  @override
  Future<String?> loadUsername() async {
    try {
      return await _storage.read(key: _usernameKey);
    } catch (_) {
      throw const StorageError();
    }
  }

  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _usernameKey, value: username);
    } catch (_) {
      throw const StorageError();
    }
  }

  @override
  Future<void> deleteCredentials() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _usernameKey);
    } catch (_) {
      throw const StorageError();
    }
  }
}

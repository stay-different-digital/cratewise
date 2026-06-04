import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/token_storage.dart';
import '../../shared/errors/app_error.dart';
import 'secure_key_value_store.dart';

class _FlutterSecureStorageAdapter implements SecureKeyValueStore {
  _FlutterSecureStorageAdapter() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

class DiscogsTokenStorage implements TokenStorage {
  DiscogsTokenStorage({SecureKeyValueStore? store})
    : _store = store ?? _FlutterSecureStorageAdapter();

  static const _tokenKey = 'discogs_token';
  static const _usernameKey = 'discogs_username';

  final SecureKeyValueStore _store;

  @override
  Future<String?> loadToken() async {
    try {
      return await _store.read(key: _tokenKey);
    } catch (_) {
      throw const StorageError();
    }
  }

  @override
  Future<String?> loadUsername() async {
    try {
      return await _store.read(key: _usernameKey);
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
      await _store.write(key: _tokenKey, value: token);
      await _store.write(key: _usernameKey, value: username);
      // Read back both values to guard against the iOS Keychain silent-write
      // bug where write() returns without error but nothing is stored.
      // Fix for the specific Keychain error code is pending device reproduction.
      final savedToken = await _store.read(key: _tokenKey);
      final savedUsername = await _store.read(key: _usernameKey);
      if (savedToken != token || savedUsername != username) {
        throw const StorageError();
      }
    } catch (e) {
      // Clean up any partial write so neither key is left behind.
      try {
        await _store.delete(key: _tokenKey);
        await _store.delete(key: _usernameKey);
      } catch (_) {}
      if (e is StorageError) rethrow;
      if (kDebugMode) {
        final detail = e is PlatformException ? ' code=${e.code}' : '';
        dev.log(
          'Keychain write failed: ${e.runtimeType}$detail',
          name: 'DiscogsTokenStorage',
          level: 900,
        );
      }
      throw const StorageError();
    }
  }

  @override
  Future<void> deleteCredentials() async {
    try {
      await _store.delete(key: _tokenKey);
      await _store.delete(key: _usernameKey);
    } catch (_) {
      throw const StorageError();
    }
  }
}

import 'dart:convert';

import 'package:cratewise/application/services/discogs_connection_service.dart';
import 'package:cratewise/application/services/token_validation_service.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeTokenStorage implements TokenStorage {
  String? _token;
  String? _username;
  bool throwOnSave = false;
  bool throwOnDelete = false;

  @override
  Future<String?> loadToken() async => _token;

  @override
  Future<String?> loadUsername() async => _username;

  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {
    if (throwOnSave) throw const StorageError();
    _token = token;
    _username = username;
  }

  @override
  Future<void> deleteCredentials() async {
    if (throwOnDelete) throw const StorageError();
    _token = null;
    _username = null;
  }
}

DiscogsConnectionService _makeService(
  http.Client httpClient, [
  _FakeTokenStorage? storage,
]) {
  return DiscogsConnectionService(
    storage: storage ?? _FakeTokenStorage(),
    validationService: TokenValidationService(
      apiClient: DiscogsApiClient(httpClient: httpClient),
    ),
  );
}

const _identityBody = {
  'username': 'vinyl_fan',
  'resource_url': 'https://api.discogs.com/users/vinyl_fan',
};

void main() {
  group('DiscogsConnectionService.loadStatus', () {
    test('returns disconnected when storage is empty', () async {
      final service = DiscogsConnectionService(storage: _FakeTokenStorage());
      final status = await service.loadStatus();
      expect(status.isConnected, isFalse);
      expect(status.username, isNull);
    });

    test('returns connected with username when credentials are saved',
        () async {
      final storage = _FakeTokenStorage();
      await storage.saveCredentials(token: 'tok', username: 'vinyl_fan');
      final service = DiscogsConnectionService(storage: storage);
      final status = await service.loadStatus();
      expect(status.isConnected, isTrue);
      expect(status.username, 'vinyl_fan');
    });

    test('returns disconnected when storage throws', () async {
      final service = DiscogsConnectionService(
        storage: _ThrowingStorage(),
      );
      final status = await service.loadStatus();
      expect(status.isConnected, isFalse);
    });
  });

  group('DiscogsConnectionService.connect', () {
    test('validates token and saves credentials, returns username', () async {
      final storage = _FakeTokenStorage();
      final service = _makeService(
        MockClient(
            (_) async => http.Response(jsonEncode(_identityBody), 200)),
        storage,
      );

      final username = await service.connect('my_token');

      expect(username, 'vinyl_fan');
      expect(storage._token, 'my_token');
      expect(storage._username, 'vinyl_fan');
    });

    test('propagates InvalidTokenError when API rejects the token', () async {
      final service = _makeService(
        MockClient((_) async => http.Response('', 401)),
      );
      expect(
        () => service.connect('bad_token'),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('propagates RateLimitedError on 429', () async {
      final service = _makeService(
        MockClient((_) async => http.Response('', 429)),
      );
      expect(
        () => service.connect('tok'),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('propagates NetworkError when HTTP client throws', () async {
      final service = _makeService(
        MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => service.connect('tok'),
        throwsA(isA<NetworkError>()),
      );
    });

    test('throws StorageError when token validates but storage fails',
        () async {
      final storage = _FakeTokenStorage()..throwOnSave = true;
      final service = _makeService(
        MockClient(
            (_) async => http.Response(jsonEncode(_identityBody), 200)),
        storage,
      );
      expect(
        () => service.connect('my_token'),
        throwsA(isA<StorageError>()),
      );
    });

    test('token value is not present in any thrown error message', () async {
      const sensitiveToken = 'super_secret_token_xyz_123';
      final service = _makeService(
        MockClient((_) async => http.Response('', 401)),
      );
      try {
        await service.connect(sensitiveToken);
        fail('expected InvalidTokenError');
      } on InvalidTokenError catch (e) {
        expect(e.toString(), isNot(contains(sensitiveToken)));
      }
    });
  });

  group('DiscogsConnectionService.disconnect', () {
    test('deletes credentials from storage', () async {
      final storage = _FakeTokenStorage();
      await storage.saveCredentials(token: 'tok', username: 'vinyl_fan');
      final service = DiscogsConnectionService(storage: storage);

      await service.disconnect();

      expect(storage._token, isNull);
      expect(storage._username, isNull);
    });

    test('propagates StorageError when storage delete fails', () async {
      final storage = _FakeTokenStorage()..throwOnDelete = true;
      final service = DiscogsConnectionService(storage: storage);
      expect(
        () => service.disconnect(),
        throwsA(isA<StorageError>()),
      );
    });
  });
}

/// Storage implementation that always throws on reads, simulating an
/// unavailable platform keychain.
class _ThrowingStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => throw const StorageError();
  @override
  Future<String?> loadUsername() async => throw const StorageError();
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async =>
      throw const StorageError();
  @override
  Future<void> deleteCredentials() async => throw const StorageError();
}

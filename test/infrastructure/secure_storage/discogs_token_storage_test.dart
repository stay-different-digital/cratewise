import 'package:cratewise/infrastructure/secure_storage/discogs_token_storage.dart';
import 'package:cratewise/infrastructure/secure_storage/secure_key_value_store.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

/// Succeeds on all writes except the [failOnWriteNumber]-th (1-based).
class _PartialWriteStore implements SecureKeyValueStore {
  _PartialWriteStore({required this.failOnWriteNumber});

  final int failOnWriteNumber;
  int _writeCount = 0;
  final Map<String, String> data = {};

  @override
  Future<String?> read({required String key}) async => data[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _writeCount++;
    if (_writeCount == failOnWriteNumber) throw Exception('simulated failure');
    data[key] = value;
  }

  @override
  Future<void> delete({required String key}) async => data.remove(key);
}

class _FakeStore implements SecureKeyValueStore {
  final Map<String, String> _data = {};
  bool throwOnWrite = false;
  bool throwOnRead = false;
  bool throwOnDelete = false;

  /// When true, write() returns without storing — simulates the iOS Keychain
  /// silent-write bug where the call succeeds but the value is never persisted.
  bool silentWriteFailure = false;

  @override
  Future<String?> read({required String key}) async {
    if (throwOnRead) throw Exception('simulated keychain read failure');
    return _data[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    if (throwOnWrite) throw Exception('simulated keychain write failure');
    if (!silentWriteFailure) _data[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    if (throwOnDelete) throw Exception('simulated keychain delete failure');
    _data.remove(key);
  }
}

const _fakeToken = 'fake_discogs_token';
const _fakeUsername = 'vinyl_fan';

void main() {
  group('DiscogsTokenStorage.saveCredentials', () {
    test(
      'stores token and username and read-back confirms the values',
      () async {
        final store = _FakeStore();
        final storage = DiscogsTokenStorage(store: store);

        await storage.saveCredentials(
          token: _fakeToken,
          username: _fakeUsername,
        );

        expect(store._data['discogs_token'], _fakeToken);
        expect(store._data['discogs_username'], _fakeUsername);
      },
    );

    test('throws StorageError when write throws', () async {
      final store = _FakeStore()..throwOnWrite = true;
      final storage = DiscogsTokenStorage(store: store);

      expect(
        () =>
            storage.saveCredentials(token: _fakeToken, username: _fakeUsername),
        throwsA(isA<StorageError>()),
      );
    });

    test(
      'throws StorageError when write silently fails '
      '(iOS Keychain bug: write returns success but value is not stored)',
      () async {
        final store = _FakeStore()..silentWriteFailure = true;
        final storage = DiscogsTokenStorage(store: store);

        expect(
          () => storage.saveCredentials(
            token: _fakeToken,
            username: _fakeUsername,
          ),
          throwsA(isA<StorageError>()),
        );
      },
    );

    test(
      'throws StorageError when read-back throws after successful write',
      () async {
        final store = _FakeStore();
        final storage = DiscogsTokenStorage(store: store);
        store.throwOnRead = true;

        expect(
          () => storage.saveCredentials(
            token: _fakeToken,
            username: _fakeUsername,
          ),
          throwsA(isA<StorageError>()),
        );
      },
    );

    test('StorageError does not contain the token value', () async {
      const sensitiveToken = 'super_secret_token_xyz_123';
      final store = _FakeStore()..throwOnWrite = true;
      final storage = DiscogsTokenStorage(store: store);

      try {
        await storage.saveCredentials(
          token: sensitiveToken,
          username: _fakeUsername,
        );
        fail('expected StorageError');
      } on StorageError catch (e) {
        expect(e.toString(), isNot(contains(sensitiveToken)));
      }
    });
  });

  group('saveCredentials atomicity', () {
    test('cleans up token when username write fails '
        '(no half-connected state after partial write)', () async {
      final store = _PartialWriteStore(failOnWriteNumber: 2);
      final storage = DiscogsTokenStorage(store: store);

      await expectLater(
        () =>
            storage.saveCredentials(token: _fakeToken, username: _fakeUsername),
        throwsA(isA<StorageError>()),
      );

      expect(store.data.containsKey('discogs_token'), isFalse);
      expect(store.data.containsKey('discogs_username'), isFalse);
    });

    test(
      'cleans up both keys when read-back throws after successful writes',
      () async {
        final store = _FakeStore()..throwOnRead = true;
        final storage = DiscogsTokenStorage(store: store);

        await expectLater(
          () => storage.saveCredentials(
            token: _fakeToken,
            username: _fakeUsername,
          ),
          throwsA(isA<StorageError>()),
        );

        expect(store._data.containsKey('discogs_token'), isFalse);
        expect(store._data.containsKey('discogs_username'), isFalse);
      },
    );
  });

  group('DiscogsTokenStorage.loadToken', () {
    test('returns the stored token after a successful save', () async {
      final store = _FakeStore();
      final storage = DiscogsTokenStorage(store: store);
      await storage.saveCredentials(token: _fakeToken, username: _fakeUsername);

      expect(await storage.loadToken(), _fakeToken);
    });

    test('returns null when no token has been stored', () async {
      final storage = DiscogsTokenStorage(store: _FakeStore());
      expect(await storage.loadToken(), isNull);
    });

    test('throws StorageError when read throws', () async {
      final store = _FakeStore()..throwOnRead = true;
      final storage = DiscogsTokenStorage(store: store);

      expect(() => storage.loadToken(), throwsA(isA<StorageError>()));
    });
  });

  group('DiscogsTokenStorage.loadUsername', () {
    test('returns the stored username after a successful save', () async {
      final store = _FakeStore();
      final storage = DiscogsTokenStorage(store: store);
      await storage.saveCredentials(token: _fakeToken, username: _fakeUsername);

      expect(await storage.loadUsername(), _fakeUsername);
    });

    test('returns null when no username has been stored', () async {
      final storage = DiscogsTokenStorage(store: _FakeStore());
      expect(await storage.loadUsername(), isNull);
    });

    test('throws StorageError when read throws', () async {
      final store = _FakeStore()..throwOnRead = true;
      final storage = DiscogsTokenStorage(store: store);

      expect(() => storage.loadUsername(), throwsA(isA<StorageError>()));
    });
  });

  group('DiscogsTokenStorage.deleteCredentials', () {
    test(
      'removes token and username so subsequent loads return null',
      () async {
        final store = _FakeStore();
        final storage = DiscogsTokenStorage(store: store);
        await storage.saveCredentials(
          token: _fakeToken,
          username: _fakeUsername,
        );

        await storage.deleteCredentials();

        expect(await storage.loadToken(), isNull);
        expect(await storage.loadUsername(), isNull);
      },
    );

    test('throws StorageError when delete throws', () async {
      final store = _FakeStore()..throwOnDelete = true;
      final storage = DiscogsTokenStorage(store: store);

      expect(() => storage.deleteCredentials(), throwsA(isA<StorageError>()));
    });
  });
}

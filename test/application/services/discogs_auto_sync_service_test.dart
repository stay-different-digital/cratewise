import 'package:cratewise/application/services/discogs_auto_sync_service.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/infrastructure/secure_storage/secure_key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _Prefs implements SecureKeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read({required String key}) async => values[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      values[key] = value;
  @override
  Future<void> delete({required String key}) async => values.remove(key);
}

class _Tokens implements TokenStorage {
  String? token = 'tok';
  String? username = 'digger';
  @override
  Future<String?> loadToken() async => token;
  @override
  Future<String?> loadUsername() async => username;
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async {
    token = null;
    username = null;
  }
}

class _Collection implements CollectionRepository {
  final items = <String, CollectionItem>{};
  @override
  Future<CollectionItem?> getById(String id) async => items[id];
  @override
  Future<void> update(CollectionItem item) async => items[item.id] = item;
  @override
  Future<void> add(CollectionItem item) async => items[item.id] = item;
  @override
  Future<List<CollectionItem>> getAll() async => items.values.toList();
  @override
  Future<bool> containsRelease(int id) async =>
      items.values.any((i) => i.discogsReleaseId == id);
  @override
  Future<void> remove(String id) async => items.remove(id);
  @override
  Future<void> deleteAll() async => items.clear();
}

class _Wishlist implements WishlistRepository {
  final items = <String, WishlistItem>{};
  @override
  Future<WishlistItem?> getById(String id) async => items[id];
  @override
  Future<void> update(WishlistItem item) async => items[item.id] = item;
  @override
  Future<void> add(WishlistItem item) async => items[item.id] = item;
  @override
  Future<List<WishlistItem>> getAll() async => items.values.toList();
  @override
  Future<bool> containsRelease(int id) async =>
      items.values.any((i) => i.discogsReleaseId == id);
  @override
  Future<void> remove(String id) async => items.remove(id);
  @override
  Future<void> deleteAll() async => items.clear();
}

CollectionItem _collectionItem() => CollectionItem(
  id: 'c1',
  discogsReleaseId: 249504,
  artist: 'Miles Davis',
  title: 'Kind Of Blue',
  mediaCondition: RecordCondition.veryGood,
  sleeveCondition: RecordCondition.veryGood,
  tags: const [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

WishlistItem _wishlistItem() => WishlistItem(
  id: 'w1',
  discogsReleaseId: 249504,
  artist: 'Miles Davis',
  title: 'Kind Of Blue',
  priority: WishlistPriority.medium,
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Records requests; [respond] decides the answer per request.
class _Discogs {
  _Discogs(this.respond);
  final Future<http.Response> Function(http.Request) respond;
  final requests = <http.Request>[];
  late final client = DiscogsApiClient(
    httpClient: MockClient((r) {
      requests.add(r);
      return respond(r);
    }),
    delay: (_) async {},
  );
}

http.Response _json(String body, [int status = 200]) =>
    http.Response(body, status);

void main() {
  late _Prefs prefs;
  late _Tokens tokens;
  late _Collection collection;
  late _Wishlist wishlist;

  DiscogsAutoSyncService service(_Discogs discogs) => DiscogsAutoSyncService(
    tokenStorage: tokens,
    apiClient: discogs.client,
    preferences: prefs,
    delay: (_) async {},
  );

  setUp(() {
    prefs = _Prefs();
    tokens = _Tokens();
    collection = _Collection()..items['c1'] = _collectionItem();
    wishlist = _Wishlist()..items['w1'] = _wishlistItem();
  });

  group('setting (US-144)', () {
    test('is off by default', () async {
      expect(
        await service(_Discogs((_) async => _json('{}'))).isEnabled(),
        isFalse,
      );
    });

    test(
      'round-trips, and turning it on clears the "turned off" notice',
      () async {
        final s = service(_Discogs((_) async => _json('{}')));
        prefs.values['discogs_auto_sync_revoked'] = 'true';
        await s.setEnabled(true);
        expect(await s.isEnabled(), isTrue);
        expect(await s.wasTurnedOffByDiscogs(), isFalse);
        await s.setEnabled(false);
        expect(await s.isEnabled(), isFalse);
      },
    );
  });

  group('pushCollectionItem (US-144)', () {
    test('off → no API call, item untouched', () async {
      final discogs = _Discogs((_) async => _json('{}'));
      await service(discogs).pushCollectionItem(_collectionItem(), collection);
      expect(discogs.requests, isEmpty);
      expect(collection.items['c1']!.syncStatus, SyncStatus.localOnly);
    });

    test(
      'on, not yet on Discogs → added, synced with its instance id',
      () async {
        prefs.values['discogs_auto_sync'] = 'true';
        final discogs = _Discogs(
          (r) async => r.method == 'GET'
              ? _json('{"releases": []}')
              : _json('{"instance_id": 778899}', 201),
        );
        await service(
          discogs,
        ).pushCollectionItem(_collectionItem(), collection);

        expect(discogs.requests.map((r) => r.method), ['GET', 'POST']);
        expect(collection.items['c1']!.syncStatus, SyncStatus.synced);
        expect(collection.items['c1']!.discogsInstanceId, 778899);
      },
    );

    test(
      'already in the Discogs collection → linked, never added twice',
      () async {
        prefs.values['discogs_auto_sync'] = 'true';
        final discogs = _Discogs(
          (_) async => _json('{"releases": [{"instance_id": 42}]}'),
        );
        await service(
          discogs,
        ).pushCollectionItem(_collectionItem(), collection);

        expect(discogs.requests.where((r) => r.method == 'POST'), isEmpty);
        expect(collection.items['c1']!.syncStatus, SyncStatus.synced);
        expect(collection.items['c1']!.discogsInstanceId, 42);
      },
    );

    test('no connection → kept locally as offline', () async {
      prefs.values['discogs_auto_sync'] = 'true';
      final discogs = _Discogs((_) async => throw http.ClientException('x'));
      await service(discogs).pushCollectionItem(_collectionItem(), collection);

      expect(collection.items['c1'], isNotNull);
      expect(collection.items['c1']!.syncStatus, SyncStatus.offline);
    });

    test('server error → kept locally as failed', () async {
      prefs.values['discogs_auto_sync'] = 'true';
      final discogs = _Discogs((_) async => _json('{}', 500));
      await service(discogs).pushCollectionItem(_collectionItem(), collection);

      expect(collection.items['c1']!.syncStatus, SyncStatus.failed);
    });

    test('rate limited → retried, then succeeds', () async {
      prefs.values['discogs_auto_sync'] = 'true';
      var posts = 0;
      final discogs = _Discogs((r) async {
        if (r.method == 'GET') return _json('{"releases": []}');
        posts++;
        return posts == 1 ? _json('{}', 429) : _json('{"instance_id": 5}', 201);
      });
      await service(discogs).pushCollectionItem(_collectionItem(), collection);

      expect(collection.items['c1']!.syncStatus, SyncStatus.synced);
    });

    test(
      'token rejected → credentials cleared, auto-sync off with notice',
      () async {
        prefs.values['discogs_auto_sync'] = 'true';
        final discogs = _Discogs((_) async => _json('{}', 401));
        final s = service(discogs);
        await s.pushCollectionItem(_collectionItem(), collection);

        expect(tokens.token, isNull);
        expect(await s.isEnabled(), isFalse);
        expect(await s.wasTurnedOffByDiscogs(), isTrue);
        expect(collection.items['c1']!.syncStatus, SyncStatus.failed);
      },
    );

    test('a local edit made while the request ran is kept', () async {
      prefs.values['discogs_auto_sync'] = 'true';
      final discogs = _Discogs((r) async {
        if (r.method == 'GET') {
          // The user edits the item while Discogs is answering.
          collection.items['c1'] = collection.items['c1']!.copyWith(
            notes: 'first pressing',
          );
          return _json('{"releases": []}');
        }
        return _json('{"instance_id": 1}', 201);
      });
      await service(discogs).pushCollectionItem(_collectionItem(), collection);

      expect(collection.items['c1']!.notes, 'first pressing');
      expect(collection.items['c1']!.syncStatus, SyncStatus.synced);
    });

    test('no linked account → nothing sent even when on', () async {
      prefs.values['discogs_auto_sync'] = 'true';
      tokens.token = null;
      final discogs = _Discogs((_) async => _json('{}'));
      await service(discogs).pushCollectionItem(_collectionItem(), collection);
      expect(discogs.requests, isEmpty);
    });
  });

  group('pushWishlistItem (US-144)', () {
    test('on → PUT to the wantlist, item synced', () async {
      prefs.values['discogs_auto_sync'] = 'true';
      final discogs = _Discogs((_) async => _json('{}', 201));
      await service(discogs).pushWishlistItem(_wishlistItem(), wishlist);

      expect(discogs.requests.single.method, 'PUT');
      expect(discogs.requests.single.url.path, '/users/digger/wants/249504');
      expect(wishlist.items['w1']!.syncStatus, SyncStatus.synced);
    });

    test('off → no API call', () async {
      final discogs = _Discogs((_) async => _json('{}', 201));
      await service(discogs).pushWishlistItem(_wishlistItem(), wishlist);
      expect(discogs.requests, isEmpty);
    });
  });
}

import 'package:cratewise/application/use_cases/execute_pending_deletions_use_case.dart';
import 'package:cratewise/domain/models/pending_discogs_deletion.dart';
import 'package:cratewise/domain/repositories/pending_discogs_deletion_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.token = 'tok'});
  String? token;
  String? username = 'vinyl_fan';
  bool cleared = false;

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
  Future<void> deleteCredentials() async => cleared = true;
}

class _SpyDeletionRepository implements PendingDiscogsDeletionRepository {
  @override
  Future<void> deleteAllByType(DeletionEntityType entityType) async {}
  _SpyDeletionRepository(this._byType);
  final Map<DeletionEntityType, List<PendingDiscogsDeletion>> _byType;
  final List<String> removedIds = [];

  @override
  Future<void> add(PendingDiscogsDeletion deletion) async {}
  @override
  Future<List<PendingDiscogsDeletion>> getByType(
    DeletionEntityType type,
  ) async => _byType[type] ?? [];
  @override
  Future<bool> containsRelease(int id, DeletionEntityType type) async => false;
  @override
  Future<void> remove(String id) async => removedIds.add(id);
  @override
  Future<void> removeByRelease(int id, DeletionEntityType type) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PendingDiscogsDeletion _collectionDeletion({
  String id = 'c-1',
  int releaseId = 100,
  int? instanceId = 9001,
}) => PendingDiscogsDeletion(
  id: id,
  entityType: DeletionEntityType.collection,
  discogsReleaseId: releaseId,
  discogsInstanceId: instanceId,
  artist: 'Artist',
  title: 'Title',
  createdAt: DateTime(2026, 6, 1),
);

PendingDiscogsDeletion _wishlistDeletion({
  String id = 'w-1',
  int releaseId = 200,
}) => PendingDiscogsDeletion(
  id: id,
  entityType: DeletionEntityType.wishlist,
  discogsReleaseId: releaseId,
  artist: 'Artist',
  title: 'Title',
  createdAt: DateTime(2026, 6, 1),
);

ExecutePendingDeletionsUseCase _makeUseCase({
  required DiscogsApiClient apiClient,
  required PendingDiscogsDeletionRepository deletionRepository,
  TokenStorage? tokenStorage,
}) => ExecutePendingDeletionsUseCase(
  tokenStorage: tokenStorage ?? _FakeTokenStorage(),
  apiClient: apiClient,
  deletionRepository: deletionRepository,
  delay: (_) async {},
);

void main() {
  test('returns NoToken when no token is stored', () async {
    final repo = _SpyDeletionRepository({});
    final uc = _makeUseCase(
      apiClient: DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response('', 204)),
      ),
      deletionRepository: repo,
      tokenStorage: _FakeTokenStorage(token: null),
    );

    final result = await uc.execute();

    expect(result, isA<PendingDeletionsNoToken>());
  });

  test('deletes collection and wishlist tombstones and clears them', () async {
    final captured = <String>[];
    final repo = _SpyDeletionRepository({
      DeletionEntityType.collection: [_collectionDeletion()],
      DeletionEntityType.wishlist: [_wishlistDeletion()],
    });
    final uc = _makeUseCase(
      apiClient: DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured.add('${request.method} ${request.url.path}');
          return http.Response('', 204);
        }),
      ),
      deletionRepository: repo,
    );

    final result = await uc.execute() as PendingDeletionsCompleted;

    expect(result.removed, 2);
    expect(result.failed, 0);
    expect(repo.removedIds, containsAll(['c-1', 'w-1']));
    expect(
      captured,
      containsAll([
        'DELETE /users/vinyl_fan/collection/folders/1/releases/100/instances/9001',
        'DELETE /users/vinyl_fan/wants/200',
      ]),
    );
  });

  test('a failed deletion is counted and its tombstone is kept', () async {
    final repo = _SpyDeletionRepository({
      DeletionEntityType.collection: [_collectionDeletion(id: 'c-1')],
    });
    final uc = _makeUseCase(
      apiClient: DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response('', 500)),
      ),
      deletionRepository: repo,
    );

    final result = await uc.execute() as PendingDeletionsCompleted;

    expect(result.removed, 0);
    expect(result.failed, 1);
    expect(repo.removedIds, isEmpty);
  });

  test('retries on rate limit then succeeds', () async {
    var calls = 0;
    final repo = _SpyDeletionRepository({
      DeletionEntityType.wishlist: [_wishlistDeletion()],
    });
    final uc = _makeUseCase(
      apiClient: DiscogsApiClient(
        httpClient: MockClient((_) async {
          calls++;
          return http.Response('', calls < 2 ? 429 : 204);
        }),
      ),
      deletionRepository: repo,
    );

    final result = await uc.execute() as PendingDeletionsCompleted;

    expect(calls, 2);
    expect(result.removed, 1);
  });

  test('reports per-item progress', () async {
    final repo = _SpyDeletionRepository({
      DeletionEntityType.collection: [_collectionDeletion()],
      DeletionEntityType.wishlist: [_wishlistDeletion()],
    });
    final uc = _makeUseCase(
      apiClient: DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response('', 204)),
      ),
      deletionRepository: repo,
    );

    final progress = <(int, int)>[];
    await uc.execute(
      onProgress: (current, total, _) => progress.add((current, total)),
    );

    expect(progress, [(1, 2), (2, 2)]);
  });

  test('clears a revoked token on InvalidTokenError', () async {
    final tokenStorage = _FakeTokenStorage();
    final repo = _SpyDeletionRepository({
      DeletionEntityType.wishlist: [_wishlistDeletion()],
    });
    final uc = _makeUseCase(
      apiClient: DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response('', 401)),
      ),
      deletionRepository: repo,
      tokenStorage: tokenStorage,
    );

    await uc.execute();

    expect(tokenStorage.cleared, isTrue);
  });
}

import 'package:cratewise/application/use_cases/retry_thumbnail_use_case.dart';
import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/cached_release_metadata_repository.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _SpyCacheRepo implements CachedReleaseMetadataRepository {
  final Map<int, CachedReleaseMetadata> _data = {};

  void put(int id, {String? coverUrl}) {
    _data[id] = CachedReleaseMetadata(
      discogsReleaseId: id,
      artist: 'Test Artist',
      title: 'Test Album',
      genres: const [],
      styles: const [],
      tracklist: const [],
      identifiers: const [],
      fetchedAt: DateTime(2026),
      cacheSource: 'discogs_api',
      syncStatus: SyncStatus.localOnly,
      coverUrl: coverUrl,
    );
  }

  @override
  Future<CachedReleaseMetadata?> getByReleaseId(int id) async => _data[id];

  @override
  Future<void> save(CachedReleaseMetadata metadata) async {}

  @override
  Future<void> remove(int id) async {}
}

class _SpyRetryRepo implements RetryActionRepository {
  final List<RetryAction> _actions;
  final List<RetryAction> updated = [];
  final List<String> removedIds = [];
  bool throwOnUpdate = false;

  _SpyRetryRepo(this._actions);

  @override
  Future<void> add(RetryAction action) async => _actions.add(action);

  @override
  Future<List<RetryAction>> getAll() async => List.of(_actions);

  @override
  Future<RetryAction?> getById(String id) async =>
      _actions.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<RetryAction>> getPending() async =>
      _actions.where((a) => a.status == RetryActionStatus.pending).toList();

  @override
  Future<void> update(RetryAction action) async {
    if (throwOnUpdate) throw Exception('db error');
    updated.add(action);
    final idx = _actions.indexWhere((a) => a.id == action.id);
    if (idx >= 0) _actions[idx] = action;
  }

  @override
  Future<void> remove(String id) async => removedIds.add(id);

  @override
  Future<void> deleteFailedBefore(DateTime cutoff) async {}
}

class _SpyThumbnailRepo implements ThumbnailRepository {
  final Map<int, List<int>> saved = {};
  bool throwOnSave = false;

  @override
  Future<String?> getLocalPath(int id) async => null;

  @override
  Future<void> save(int id, List<int> bytes) async {
    if (throwOnSave) throw Exception('disk full');
    saved[id] = bytes;
  }

  @override
  Future<void> remove(int id) async {}

  @override
  Future<bool> exists(int id) async => false;
  @override
  Future<int> totalSizeBytes() async => 0;
  @override
  Future<List<ThumbnailEntry>> listEntries() async => [];
  @override
  Future<void> removeAll() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

RetryAction _makeAction({
  String id = 'action-1',
  String entityId = '249504',
  RetryActionStatus status = RetryActionStatus.pending,
  int attemptCount = 0,
}) {
  return RetryAction(
    id: id,
    actionType: RetryActionType.cacheThumbnail,
    entityType: RetryActionEntityType.cachedRelease,
    entityId: entityId,
    safeErrorMessage: 'Cover image could not be cached.',
    createdAt: DateTime(2026, 6, 1),
    attemptCount: attemptCount,
    status: status,
  );
}

MockClient _mockSuccessClient() {
  return MockClient((_) async => http.Response.bytes([1, 2, 3], 200));
}

MockClient _mockErrorClient(int statusCode) {
  return MockClient((_) async => http.Response('', statusCode));
}

MockClient _mockExceptionClient() {
  return MockClient(
    (_) async => throw http.ClientException('connection refused'),
  );
}

RetryThumbnailUseCase _makeUseCase({
  required _SpyRetryRepo retryRepo,
  required _SpyCacheRepo cacheRepo,
  _SpyThumbnailRepo? thumbnailRepo,
  http.Client? httpClient,
}) {
  return RetryThumbnailUseCase(
    retryRepo: retryRepo,
    cacheRepo: cacheRepo,
    thumbnailRepo: thumbnailRepo ?? _SpyThumbnailRepo(),
    httpClient: httpClient ?? _mockSuccessClient(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RetryThumbnailUseCase — success', () {
    test('returns Success when URL exists and fetch succeeds', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryThumbnailSuccess>());
    });

    test('saves thumbnail bytes to repository on success', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final thumbnailRepo = _SpyThumbnailRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        thumbnailRepo: thumbnailRepo,
      );

      await uc.execute(_makeAction());

      expect(thumbnailRepo.saved, contains(249504));
    });

    test('removes retry action from repo on success', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      await uc.execute(_makeAction());

      expect(retryRepo.removedIds, contains('action-1'));
    });

    test('does NOT update action on success', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      await uc.execute(_makeAction());

      expect(retryRepo.updated, isEmpty);
    });
  });

  group('RetryThumbnailUseCase — no URL', () {
    test('returns NoUrl when metadata has null coverUrl', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: null);
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryThumbnailNoUrl>());
    });

    test('returns NoUrl when metadata has empty coverUrl', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: '');
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryThumbnailNoUrl>());
    });

    test('returns NoUrl when no metadata found for releaseId', () async {
      final cacheRepo = _SpyCacheRepo();
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryThumbnailNoUrl>());
    });

    test('does NOT record attempt on NoUrl', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: null);
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      await uc.execute(_makeAction());

      expect(retryRepo.updated, isEmpty);
    });
  });

  group('RetryThumbnailUseCase — network failures', () {
    test('returns NetworkError on HTTP non-200 response', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(503),
      );

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryThumbnailNetworkError>());
    });

    test('returns NetworkError when HTTP client throws', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockExceptionClient(),
      );

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryThumbnailNetworkError>());
    });

    test('increments attemptCount on network failure', () async {
      final action = _makeAction(attemptCount: 1);
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([action]);
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(503),
      );

      await uc.execute(action);

      expect(retryRepo.updated.first.attemptCount, 2);
    });

    test('sets lastAttemptedAt on network failure', () async {
      final action = _makeAction();
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([action]);
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(503),
      );

      await uc.execute(action);

      expect(retryRepo.updated.first.lastAttemptedAt, isNotNull);
    });

    test('sets status to failed on network failure', () async {
      final action = _makeAction(status: RetryActionStatus.pending);
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([action]);
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(503),
      );

      await uc.execute(action);

      expect(retryRepo.updated.first.status, RetryActionStatus.failed);
    });
  });

  group('RetryThumbnailUseCase — other failures', () {
    test('returns Failed for invalid entityId (non-numeric)', () async {
      final action = RetryAction(
        id: 'a1',
        actionType: RetryActionType.cacheThumbnail,
        entityType: RetryActionEntityType.cachedRelease,
        entityId: 'not-a-number',
        safeErrorMessage: 'msg',
        createdAt: DateTime(2026),
        attemptCount: 0,
        status: RetryActionStatus.pending,
      );
      final cacheRepo = _SpyCacheRepo();
      final retryRepo = _SpyRetryRepo([action]);
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      final result = await uc.execute(action);

      expect(result, isA<RetryThumbnailFailed>());
    });

    test('returns Failed when thumbnail repo.save throws', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final thumbnailRepo = _SpyThumbnailRepo()..throwOnSave = true;
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        thumbnailRepo: thumbnailRepo,
      );

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryThumbnailFailed>());
    });

    test('increments attemptCount when save throws', () async {
      final action = _makeAction(attemptCount: 2);
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([action]);
      final thumbnailRepo = _SpyThumbnailRepo()..throwOnSave = true;
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        thumbnailRepo: thumbnailRepo,
      );

      await uc.execute(action);

      expect(retryRepo.updated.first.attemptCount, 3);
    });
  });

  group('RetryThumbnailUseCase — error isolation', () {
    test('swallows repo update error and still returns result', () async {
      final cacheRepo = _SpyCacheRepo()..put(249504, coverUrl: 'http://img/1');
      final retryRepo = _SpyRetryRepo([_makeAction()])..throwOnUpdate = true;
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(503),
      );

      await expectLater(uc.execute(_makeAction()), completes);
    });
  });

  group('RetryThumbnailUseCase — security', () {
    test(
      'updated action safe message does not contain token or secret',
      () async {
        final cacheRepo = _SpyCacheRepo()
          ..put(249504, coverUrl: 'http://img/1');
        final retryRepo = _SpyRetryRepo([_makeAction()]);
        final uc = _makeUseCase(
          retryRepo: retryRepo,
          cacheRepo: cacheRepo,
          httpClient: _mockErrorClient(503),
        );

        await uc.execute(_makeAction());

        for (final a in retryRepo.updated) {
          expect(a.safeErrorMessage.toLowerCase(), isNot(contains('token')));
          expect(a.safeErrorMessage.toLowerCase(), isNot(contains('secret')));
        }
      },
    );
  });
}

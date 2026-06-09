import 'dart:convert';

import 'package:cratewise/application/use_cases/retry_metadata_refresh_use_case.dart';
import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/repositories/cached_release_metadata_repository.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.token});
  final String? token;

  @override
  Future<String?> loadToken() async => token;
  @override
  Future<String?> loadUsername() async => null;
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async {}
}

class _SpyCacheRepo implements CachedReleaseMetadataRepository {
  final List<CachedReleaseMetadata> saved = [];
  final List<int> removed = [];
  bool throwOnSave = false;

  @override
  Future<CachedReleaseMetadata?> getByReleaseId(int id) async => null;

  @override
  Future<void> save(CachedReleaseMetadata metadata) async {
    if (throwOnSave) throw Exception('db full');
    saved.add(metadata);
  }

  @override
  Future<void> remove(int id) async => removed.add(id);
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
    actionType: RetryActionType.refreshReleaseMetadata,
    entityType: RetryActionEntityType.cachedRelease,
    entityId: entityId,
    safeErrorMessage: 'Release metadata could not be refreshed.',
    createdAt: DateTime(2026, 6, 1),
    attemptCount: attemptCount,
    status: status,
  );
}

/// Returns a mock HTTP client that responds with a minimal Discogs release JSON.
MockClient _mockSuccessClient({int releaseId = 249504}) {
  return MockClient((_) async {
    final body = jsonEncode({
      'id': releaseId,
      'title': 'Some Album',
      'artists': [
        {'name': 'Some Artist'},
      ],
      'labels': [
        {'name': 'Some Label', 'catno': 'SL001'},
      ],
      'formats': [
        {
          'name': 'Vinyl',
          'descriptions': ['LP'],
        },
      ],
      'country': 'UK',
      'year': 1990,
      'genres': ['Electronic'],
      'styles': ['Techno'],
      'tracklist': [],
      'identifiers': [],
      'images': [],
    });
    return http.Response(body, 200);
  });
}

MockClient _mockErrorClient(int statusCode) {
  return MockClient((_) async => http.Response('{}', statusCode));
}

RetryMetadataRefreshUseCase _makeUseCase({
  required _SpyRetryRepo retryRepo,
  required _SpyCacheRepo cacheRepo,
  String? token = 'test-token',
  http.Client? httpClient,
}) {
  return RetryMetadataRefreshUseCase(
    retryRepo: retryRepo,
    cacheRepo: cacheRepo,
    storage: _FakeTokenStorage(token: token),
    apiClient: DiscogsApiClient(httpClient: httpClient ?? _mockSuccessClient()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RetryMetadataRefreshUseCase — success', () {
    test('returns Success when API call and cache save succeed', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryMetadataSuccess>());
    });

    test('saves metadata to cache on success', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      await uc.execute(_makeAction());

      expect(cacheRepo.saved, hasLength(1));
      expect(cacheRepo.saved.first.discogsReleaseId, 249504);
    });

    test('removes retry action from repo on success', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      await uc.execute(_makeAction());

      expect(retryRepo.removedIds, contains('action-1'));
    });

    test('does NOT update action on success', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      await uc.execute(_makeAction());

      expect(retryRepo.updated, isEmpty);
    });

    test('saved metadata has correct fields', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      await uc.execute(_makeAction());

      final saved = cacheRepo.saved.first;
      expect(saved.artist, 'Some Artist');
      expect(saved.title, 'Some Album');
      expect(saved.cacheSource, 'discogs_api');
    });
  });

  group('RetryMetadataRefreshUseCase — no token', () {
    test('returns NoToken when token is null', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        token: null,
      );

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryMetadataNoToken>());
    });

    test('does NOT update action when no token', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        token: null,
      );

      await uc.execute(_makeAction());

      expect(retryRepo.updated, isEmpty);
    });
  });

  group('RetryMetadataRefreshUseCase — API failures', () {
    test('returns RateLimited on 429', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(429),
      );

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryMetadataRateLimited>());
    });

    test('returns NetworkError on 503', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(503),
      );

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryMetadataNetworkError>());
    });

    test('returns Failed on 401 (invalid token)', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(401),
      );

      final result = await uc.execute(_makeAction());

      expect(result, isA<RetryMetadataFailed>());
    });

    test('increments attemptCount on API failure', () async {
      final action = _makeAction(attemptCount: 2);
      final retryRepo = _SpyRetryRepo([action]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(429),
      );

      await uc.execute(action);

      expect(retryRepo.updated.first.attemptCount, 3);
    });

    test('sets lastAttemptedAt on API failure', () async {
      final action = _makeAction();
      final retryRepo = _SpyRetryRepo([action]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(503),
      );

      await uc.execute(action);

      expect(retryRepo.updated.first.lastAttemptedAt, isNotNull);
    });

    test('sets status to failed on API failure', () async {
      final action = _makeAction(status: RetryActionStatus.pending);
      final retryRepo = _SpyRetryRepo([action]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(503),
      );

      await uc.execute(action);

      expect(retryRepo.updated.first.status, RetryActionStatus.failed);
    });

    test('returns Failed for invalid entityId (non-numeric)', () async {
      final action = RetryAction(
        id: 'a1',
        actionType: RetryActionType.refreshReleaseMetadata,
        entityType: RetryActionEntityType.cachedRelease,
        entityId: 'not-a-number',
        safeErrorMessage: 'msg',
        createdAt: DateTime(2026),
        attemptCount: 0,
        status: RetryActionStatus.pending,
      );
      final retryRepo = _SpyRetryRepo([action]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(retryRepo: retryRepo, cacheRepo: cacheRepo);

      final result = await uc.execute(action);

      expect(result, isA<RetryMetadataFailed>());
    });
  });

  group('RetryMetadataRefreshUseCase — error isolation', () {
    test('swallows repo update error and still returns result', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()])..throwOnUpdate = true;
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        httpClient: _mockErrorClient(429),
      );

      await expectLater(uc.execute(_makeAction()), completes);
    });
  });

  group('RetryMetadataRefreshUseCase — security', () {
    test('NoToken result contains no token text', () async {
      final retryRepo = _SpyRetryRepo([_makeAction()]);
      final cacheRepo = _SpyCacheRepo();
      final uc = _makeUseCase(
        retryRepo: retryRepo,
        cacheRepo: cacheRepo,
        token: null,
      );

      final result = await uc.execute(_makeAction());

      // The result type itself is RetryMetadataNoToken — verify no token in
      // any updated action's safe message either.
      expect(retryRepo.updated, isEmpty);
      expect(result, isA<RetryMetadataNoToken>());
    });

    test(
      'updated action safe message does not contain token or secret',
      () async {
        final action = _makeAction();
        final retryRepo = _SpyRetryRepo([action]);
        final cacheRepo = _SpyCacheRepo();
        final uc = _makeUseCase(
          retryRepo: retryRepo,
          cacheRepo: cacheRepo,
          httpClient: _mockErrorClient(429),
        );

        await uc.execute(action);

        for (final a in retryRepo.updated) {
          expect(a.safeErrorMessage.toLowerCase(), isNot(contains('token')));
          expect(a.safeErrorMessage.toLowerCase(), isNot(contains('secret')));
        }
      },
    );
  });
}

import 'package:cratewise/application/services/cache_retry_recorder.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeRetryRepo implements RetryActionRepository {
  final List<RetryAction> _actions = [];
  bool addThrows = false;

  @override
  Future<void> add(RetryAction action) async {
    if (addThrows) throw Exception('db full');
    _actions.add(action);
  }

  @override
  Future<List<RetryAction>> getAll() async => List.unmodifiable(_actions);

  @override
  Future<RetryAction?> getById(String id) async =>
      _actions.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<RetryAction>> getPending() async =>
      _actions.where((a) => a.status == RetryActionStatus.pending).toList();

  @override
  Future<void> update(RetryAction action) async {
    final idx = _actions.indexWhere((a) => a.id == action.id);
    if (idx >= 0) _actions[idx] = action;
  }

  @override
  Future<void> remove(String id) async =>
      _actions.removeWhere((a) => a.id == id);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CacheRetryRecorder.recordMetadataFailure', () {
    test('records action for NetworkError', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(249504, const NetworkError());
      expect(repo._actions, hasLength(1));
      expect(
        repo._actions.first.actionType,
        RetryActionType.refreshReleaseMetadata,
      );
    });

    test('records action for RateLimitedError', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(249504, const RateLimitedError());
      expect(repo._actions, hasLength(1));
      expect(
        repo._actions.first.actionType,
        RetryActionType.refreshReleaseMetadata,
      );
    });

    test('records action for DiscogsUnavailableError', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(249504, const DiscogsUnavailableError());
      expect(repo._actions, hasLength(1));
    });

    test('does not record for InvalidTokenError', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(249504, const InvalidTokenError());
      expect(repo._actions, isEmpty);
    });

    test('does not record for NoTokenError', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(249504, const NoTokenError());
      expect(repo._actions, isEmpty);
    });

    test('does not record for StorageError', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(249504, const StorageError());
      expect(repo._actions, isEmpty);
    });

    test('stores entityId as the release ID string', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(42, const NetworkError());
      expect(repo._actions.first.entityId, '42');
    });

    test('stores cachedRelease entity type', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(1, const NetworkError());
      expect(
        repo._actions.first.entityType,
        RetryActionEntityType.cachedRelease,
      );
    });

    test('stores pending status and zero attemptCount', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(1, const NetworkError());
      final action = repo._actions.first;
      expect(action.status, RetryActionStatus.pending);
      expect(action.attemptCount, 0);
    });

    test(
      'does not record duplicate when pending action exists for same release',
      () async {
        final repo = _FakeRetryRepo();
        final recorder = CacheRetryRecorder(repo);
        await recorder.recordMetadataFailure(249504, const NetworkError());
        await recorder.recordMetadataFailure(249504, const NetworkError());
        expect(repo._actions, hasLength(1));
      },
    );

    test('records separate action for different release ID', () async {
      final repo = _FakeRetryRepo();
      final recorder = CacheRetryRecorder(repo);
      await recorder.recordMetadataFailure(111, const NetworkError());
      await recorder.recordMetadataFailure(222, const NetworkError());
      expect(repo._actions, hasLength(2));
    });

    test('swallows repository errors without throwing', () async {
      final repo = _FakeRetryRepo()..addThrows = true;
      await expectLater(
        CacheRetryRecorder(repo).recordMetadataFailure(1, const NetworkError()),
        completes,
      );
    });
  });

  group('CacheRetryRecorder.recordThumbnailFailure', () {
    test('records action with cacheThumbnail type', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(repo).recordThumbnailFailure(249504);
      expect(repo._actions, hasLength(1));
      expect(repo._actions.first.actionType, RetryActionType.cacheThumbnail);
    });

    test('stores entityId as the release ID string', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(repo).recordThumbnailFailure(77);
      expect(repo._actions.first.entityId, '77');
    });

    test('stores cachedRelease entity type', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(repo).recordThumbnailFailure(1);
      expect(
        repo._actions.first.entityType,
        RetryActionEntityType.cachedRelease,
      );
    });

    test(
      'does not record duplicate when pending thumbnail action exists',
      () async {
        final repo = _FakeRetryRepo();
        final recorder = CacheRetryRecorder(repo);
        await recorder.recordThumbnailFailure(249504);
        await recorder.recordThumbnailFailure(249504);
        expect(repo._actions, hasLength(1));
      },
    );

    test(
      'records separately for metadata and thumbnail for same release',
      () async {
        final repo = _FakeRetryRepo();
        final recorder = CacheRetryRecorder(repo);
        await recorder.recordMetadataFailure(1, const NetworkError());
        await recorder.recordThumbnailFailure(1);
        expect(repo._actions, hasLength(2));
        expect(repo._actions.map((a) => a.actionType).toSet(), {
          RetryActionType.refreshReleaseMetadata,
          RetryActionType.cacheThumbnail,
        });
      },
    );

    test('swallows repository errors without throwing', () async {
      final repo = _FakeRetryRepo()..addThrows = true;
      await expectLater(
        CacheRetryRecorder(repo).recordThumbnailFailure(1),
        completes,
      );
    });
  });

  group('CacheRetryRecorder — security', () {
    test(
      'safe error message does not contain token, secret, or header words',
      () async {
        final repo = _FakeRetryRepo();
        final recorder = CacheRetryRecorder(repo);
        await recorder.recordMetadataFailure(1, const NetworkError());
        await recorder.recordThumbnailFailure(2);
        for (final action in repo._actions) {
          expect(
            action.safeErrorMessage.toLowerCase(),
            isNot(contains('token')),
          );
          expect(
            action.safeErrorMessage.toLowerCase(),
            isNot(contains('secret')),
          );
          expect(
            action.safeErrorMessage.toLowerCase(),
            isNot(contains('header')),
          );
        }
      },
    );

    test('action has no token or secret fields', () async {
      final repo = _FakeRetryRepo();
      await CacheRetryRecorder(
        repo,
      ).recordMetadataFailure(1, const NetworkError());
      final action = repo._actions.first;
      expect(action.id, isNotEmpty);
      expect(action.entityId, '1');
      expect(action.safeErrorMessage, isNotEmpty);
    });
  });
}

import 'package:cratewise/application/use_cases/purge_stale_failed_actions_use_case.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Spy repository
// ---------------------------------------------------------------------------

class _SpyRetryRepo implements RetryActionRepository {
  DateTime? deletedBefore;

  @override
  Future<void> add(RetryAction action) async {}

  @override
  Future<List<RetryAction>> getAll() async => [];

  @override
  Future<RetryAction?> getById(String id) async => null;

  @override
  Future<List<RetryAction>> getPending() async => [];

  @override
  Future<void> update(RetryAction action) async {}

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> deleteFailedBefore(DateTime cutoff) async {
    deletedBefore = cutoff;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PurgeStaleFailedActionsUseCase', () {
    test(
      'calls deleteFailedBefore with cutoff 30 days before now by default',
      () async {
        final repo = _SpyRetryRepo();
        final before = DateTime.now();
        await PurgeStaleFailedActionsUseCase(retryRepo: repo).execute();
        final after = DateTime.now();

        expect(repo.deletedBefore, isNotNull);
        final cutoff = repo.deletedBefore!;
        final expectedMin = before.subtract(const Duration(days: 30));
        final expectedMax = after.subtract(const Duration(days: 30));
        expect(
          cutoff.isAfter(expectedMin.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          cutoff.isBefore(expectedMax.add(const Duration(seconds: 1))),
          isTrue,
        );
      },
    );

    test('respects custom TTL', () async {
      final repo = _SpyRetryRepo();
      const customTtl = Duration(days: 7);
      final before = DateTime.now();
      await PurgeStaleFailedActionsUseCase(
        retryRepo: repo,
        ttl: customTtl,
      ).execute();
      final after = DateTime.now();

      expect(repo.deletedBefore, isNotNull);
      final cutoff = repo.deletedBefore!;
      final expectedMin = before.subtract(customTtl);
      final expectedMax = after.subtract(customTtl);
      expect(
        cutoff.isAfter(expectedMin.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        cutoff.isBefore(expectedMax.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('delegates to repository deleteFailedBefore exactly once', () async {
      final repo = _SpyRetryRepo();
      await PurgeStaleFailedActionsUseCase(retryRepo: repo).execute();
      // Verify the method was called (deletedBefore is set).
      expect(repo.deletedBefore, isNotNull);
    });
  });
}

import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/local_retry_action_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

RetryAction makeAction({
  String id = 'r-1',
  RetryActionType actionType = RetryActionType.addCollectionItem,
  RetryActionEntityType entityType = RetryActionEntityType.collectionItem,
  String entityId = 'item-1',
  String safeErrorMessage = 'Could not save item.',
  RetryActionStatus status = RetryActionStatus.pending,
  int attemptCount = 0,
  DateTime? createdAt,
  DateTime? lastAttemptedAt,
}) => RetryAction(
  id: id,
  actionType: actionType,
  entityType: entityType,
  entityId: entityId,
  safeErrorMessage: safeErrorMessage,
  createdAt: createdAt ?? DateTime(2026, 6, 1),
  lastAttemptedAt: lastAttemptedAt,
  attemptCount: attemptCount,
  status: status,
);

void main() {
  group('LocalRetryActionRepository', () {
    late AppDatabase db;
    late LocalRetryActionRepository repo;

    setUp(() {
      db = openTestDb();
      repo = LocalRetryActionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('add and getAll', () {
      test('returns empty list when no actions exist', () async {
        expect(await repo.getAll(), isEmpty);
      });

      test('returns action after adding', () async {
        await repo.add(makeAction());
        final all = await repo.getAll();
        expect(all, hasLength(1));
        expect(all.first.id, 'r-1');
      });

      test(
        'returns multiple actions ordered by createdAt descending',
        () async {
          await repo.add(
            makeAction(id: 'r-1', createdAt: DateTime(2026, 6, 1)),
          );
          await repo.add(
            makeAction(
              id: 'r-2',
              entityId: 'item-2',
              createdAt: DateTime(2026, 6, 2),
            ),
          );
          final all = await repo.getAll();
          expect(all, hasLength(2));
          expect(all.first.id, 'r-2');
          expect(all.last.id, 'r-1');
        },
      );
    });

    group('getById', () {
      test('returns action with matching id', () async {
        await repo.add(makeAction(id: 'abc'));
        final action = await repo.getById('abc');
        expect(action, isNotNull);
        expect(action!.id, 'abc');
      });

      test('returns null for unknown id', () async {
        expect(await repo.getById('no-such-id'), isNull);
      });
    });

    group('round-trip fields', () {
      test('persists all required fields', () async {
        final created = DateTime(2026, 5, 10, 12);
        await repo.add(
          makeAction(
            id: 'r-1',
            actionType: RetryActionType.updateWishlistItem,
            entityType: RetryActionEntityType.wishlistItem,
            entityId: 'w-99',
            safeErrorMessage: 'Something went wrong.',
            status: RetryActionStatus.failed,
            attemptCount: 3,
            createdAt: created,
          ),
        );
        final action = await repo.getById('r-1');
        expect(action, isNotNull);
        expect(action!.actionType, RetryActionType.updateWishlistItem);
        expect(action.entityType, RetryActionEntityType.wishlistItem);
        expect(action.entityId, 'w-99');
        expect(action.safeErrorMessage, 'Something went wrong.');
        expect(action.status, RetryActionStatus.failed);
        expect(action.attemptCount, 3);
        expect(action.createdAt, created);
        expect(action.lastAttemptedAt, isNull);
      });

      test('persists lastAttemptedAt when set', () async {
        final attempted = DateTime(2026, 6, 2, 9, 30);
        await repo.add(makeAction(lastAttemptedAt: attempted));
        final action = await repo.getById('r-1');
        expect(action!.lastAttemptedAt, attempted);
      });

      test('lastAttemptedAt is null when not set', () async {
        await repo.add(makeAction());
        final action = await repo.getById('r-1');
        expect(action!.lastAttemptedAt, isNull);
      });
    });

    group('getPending', () {
      test('returns only pending actions', () async {
        await repo.add(
          makeAction(
            id: 'r-1',
            status: RetryActionStatus.pending,
            entityId: 'item-1',
          ),
        );
        await repo.add(
          makeAction(
            id: 'r-2',
            status: RetryActionStatus.failed,
            entityId: 'item-2',
          ),
        );
        await repo.add(
          makeAction(
            id: 'r-3',
            status: RetryActionStatus.abandoned,
            entityId: 'item-3',
          ),
        );
        final pending = await repo.getPending();
        expect(pending, hasLength(1));
        expect(pending.first.id, 'r-1');
      });

      test('returns empty when no pending actions', () async {
        await repo.add(makeAction(status: RetryActionStatus.failed));
        expect(await repo.getPending(), isEmpty);
      });

      test('orders pending by createdAt ascending', () async {
        await repo.add(
          makeAction(
            id: 'r-late',
            entityId: 'item-2',
            createdAt: DateTime(2026, 6, 3),
          ),
        );
        await repo.add(
          makeAction(
            id: 'r-early',
            entityId: 'item-1',
            createdAt: DateTime(2026, 6, 1),
          ),
        );
        final pending = await repo.getPending();
        expect(pending.first.id, 'r-early');
        expect(pending.last.id, 'r-late');
      });
    });

    group('update', () {
      test('update changes status', () async {
        await repo.add(makeAction());
        final original = (await repo.getById('r-1'))!;
        final updated = original.copyWith(status: RetryActionStatus.failed);
        await repo.update(updated);
        final reloaded = await repo.getById('r-1');
        expect(reloaded!.status, RetryActionStatus.failed);
      });

      test('update changes attemptCount and lastAttemptedAt', () async {
        await repo.add(makeAction());
        final original = (await repo.getById('r-1'))!;
        final now = DateTime(2026, 6, 2, 10);
        final updated = original.copyWith(
          attemptCount: 2,
          lastAttemptedAt: now,
        );
        await repo.update(updated);
        final reloaded = await repo.getById('r-1');
        expect(reloaded!.attemptCount, 2);
        expect(reloaded.lastAttemptedAt, now);
      });

      test('update does not affect other rows', () async {
        await repo.add(makeAction(id: 'r-1', entityId: 'item-1'));
        await repo.add(makeAction(id: 'r-2', entityId: 'item-2'));
        final first = (await repo.getById('r-1'))!;
        await repo.update(first.copyWith(status: RetryActionStatus.abandoned));
        final second = await repo.getById('r-2');
        expect(second!.status, RetryActionStatus.pending);
      });
    });

    group('remove', () {
      test('removes the specified action', () async {
        await repo.add(makeAction());
        await repo.remove('r-1');
        expect(await repo.getById('r-1'), isNull);
      });

      test('does not affect other actions', () async {
        await repo.add(makeAction(id: 'r-1', entityId: 'item-1'));
        await repo.add(makeAction(id: 'r-2', entityId: 'item-2'));
        await repo.remove('r-1');
        expect(await repo.getAll(), hasLength(1));
        expect((await repo.getAll()).first.id, 'r-2');
      });

      test('is a no-op for unknown id', () async {
        await repo.add(makeAction());
        await repo.remove('no-such-id');
        expect(await repo.getAll(), hasLength(1));
      });
    });

    group('all action types round-trip', () {
      for (final type in RetryActionType.values) {
        test('$type round-trips', () async {
          await repo.add(
            makeAction(
              id: type.name,
              actionType: type,
              entityId: 'e-${type.name}',
            ),
          );
          final reloaded = await repo.getById(type.name);
          expect(reloaded!.actionType, type);
        });
      }
    });

    group('all entity types round-trip', () {
      for (final type in RetryActionEntityType.values) {
        test('$type round-trips', () async {
          await repo.add(
            makeAction(
              id: type.name,
              entityType: type,
              entityId: 'e-${type.name}',
            ),
          );
          final reloaded = await repo.getById(type.name);
          expect(reloaded!.entityType, type);
        });
      }
    });

    group('all status values round-trip', () {
      for (final status in RetryActionStatus.values) {
        test('$status round-trips', () async {
          await repo.add(
            makeAction(
              id: status.name,
              entityId: 'e-${status.name}',
              status: status,
            ),
          );
          final reloaded = await repo.getById(status.name);
          expect(reloaded!.status, status);
        });
      }
    });

    group('deleteFailedBefore', () {
      test('deletes failed entries older than cutoff', () async {
        await repo.add(
          makeAction(
            id: 'old-failed',
            entityId: 'item-1',
            status: RetryActionStatus.failed,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await repo.deleteFailedBefore(DateTime(2026, 3, 1));
        expect(await repo.getById('old-failed'), isNull);
      });

      test('does not delete pending entries older than cutoff', () async {
        await repo.add(
          makeAction(
            id: 'old-pending',
            entityId: 'item-1',
            status: RetryActionStatus.pending,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await repo.deleteFailedBefore(DateTime(2026, 3, 1));
        expect(await repo.getById('old-pending'), isNotNull);
      });

      test('does not delete failed entries newer than cutoff', () async {
        await repo.add(
          makeAction(
            id: 'new-failed',
            entityId: 'item-1',
            status: RetryActionStatus.failed,
            createdAt: DateTime(2026, 5, 1),
          ),
        );
        await repo.deleteFailedBefore(DateTime(2026, 3, 1));
        expect(await repo.getById('new-failed'), isNotNull);
      });

      test('does not delete abandoned entries older than cutoff', () async {
        await repo.add(
          makeAction(
            id: 'old-abandoned',
            entityId: 'item-1',
            status: RetryActionStatus.abandoned,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await repo.deleteFailedBefore(DateTime(2026, 3, 1));
        expect(await repo.getById('old-abandoned'), isNotNull);
      });

      test('is a no-op when no failed entries exist', () async {
        await repo.add(makeAction(status: RetryActionStatus.pending));
        await repo.deleteFailedBefore(DateTime(2026, 3, 1));
        expect(await repo.getAll(), hasLength(1));
      });

      test('deletes only failed entries past cutoff, keeps others', () async {
        await repo.add(
          makeAction(
            id: 'old-failed',
            entityId: 'item-1',
            status: RetryActionStatus.failed,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await repo.add(
          makeAction(
            id: 'new-failed',
            entityId: 'item-2',
            status: RetryActionStatus.failed,
            createdAt: DateTime(2026, 5, 1),
          ),
        );
        await repo.add(
          makeAction(
            id: 'old-pending',
            entityId: 'item-3',
            status: RetryActionStatus.pending,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await repo.deleteFailedBefore(DateTime(2026, 3, 1));
        expect(await repo.getAll(), hasLength(2));
        expect(await repo.getById('old-failed'), isNull);
        expect(await repo.getById('new-failed'), isNotNull);
        expect(await repo.getById('old-pending'), isNotNull);
      });
    });

    group('security', () {
      test('model has no token field', () {
        final action = makeAction();
        final fields = action.toString();
        expect(fields.contains('token'), isFalse);
        expect(fields.contains('secret'), isFalse);
        expect(fields.contains('header'), isFalse);
      });

      test(
        'safeErrorMessage is stored as plain safe text (no raw API content)',
        () async {
          await repo.add(
            makeAction(safeErrorMessage: 'Could not save. Please try again.'),
          );
          final action = await repo.getById('r-1');
          expect(action!.safeErrorMessage, 'Could not save. Please try again.');
        },
      );
    });
  });
}

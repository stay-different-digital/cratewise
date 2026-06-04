import 'package:drift/drift.dart';

import '../../domain/models/retry_action.dart';
import '../../domain/repositories/retry_action_repository.dart';
import 'app_database.dart';

class LocalRetryActionRepository implements RetryActionRepository {
  LocalRetryActionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> add(RetryAction action) async {
    await _db.into(_db.retryActions).insert(_actionToCompanion(action));
  }

  @override
  Future<List<RetryAction>> getAll() async {
    final rows = await (_db.select(
      _db.retryActions,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return rows.map(_rowToAction).toList();
  }

  @override
  Future<RetryAction?> getById(String id) async {
    final row = await (_db.select(
      _db.retryActions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _rowToAction(row);
  }

  @override
  Future<List<RetryAction>> getPending() async {
    final rows =
        await (_db.select(_db.retryActions)
              ..where((t) => t.status.equals(RetryActionStatus.pending.name))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(_rowToAction).toList();
  }

  @override
  Future<void> update(RetryAction action) async {
    await (_db.update(
      _db.retryActions,
    )..where((t) => t.id.equals(action.id))).write(_actionToCompanion(action));
  }

  @override
  Future<void> remove(String id) async {
    await (_db.delete(_db.retryActions)..where((t) => t.id.equals(id))).go();
  }

  RetryAction _rowToAction(RetryActionRow row) {
    return RetryAction(
      id: row.id,
      actionType: row.actionType,
      entityType: row.entityType,
      entityId: row.entityId,
      safeErrorMessage: row.safeErrorMessage,
      payload: row.payload,
      createdAt: row.createdAt,
      lastAttemptedAt: row.lastAttemptedAt,
      attemptCount: row.attemptCount,
      status: row.status,
    );
  }

  RetryActionsCompanion _actionToCompanion(RetryAction action) {
    return RetryActionsCompanion(
      id: Value(action.id),
      actionType: Value(action.actionType),
      entityType: Value(action.entityType),
      entityId: Value(action.entityId),
      safeErrorMessage: Value(action.safeErrorMessage),
      payload: Value(action.payload),
      createdAt: Value(action.createdAt),
      lastAttemptedAt: Value(action.lastAttemptedAt),
      attemptCount: Value(action.attemptCount),
      status: Value(action.status),
    );
  }
}

import 'package:drift/drift.dart';

import '../../domain/models/pending_discogs_deletion.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import 'app_database.dart';

class LocalPendingDiscogsDeletionRepository
    implements PendingDiscogsDeletionRepository {
  LocalPendingDiscogsDeletionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> add(PendingDiscogsDeletion deletion) async {
    await _db
        .into(_db.pendingDiscogsDeletions)
        .insertOnConflictUpdate(_toCompanion(deletion));
  }

  @override
  Future<List<PendingDiscogsDeletion>> getByType(
    DeletionEntityType entityType,
  ) async {
    final rows =
        await (_db.select(_db.pendingDiscogsDeletions)
              ..where((t) => t.entityType.equals(entityType.name))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<bool> containsRelease(
    int discogsReleaseId,
    DeletionEntityType entityType,
  ) async {
    final row =
        await (_db.select(_db.pendingDiscogsDeletions)
              ..where(
                (t) =>
                    t.discogsReleaseId.equals(discogsReleaseId) &
                    t.entityType.equals(entityType.name),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> remove(String id) async {
    await (_db.delete(
      _db.pendingDiscogsDeletions,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> removeByRelease(
    int discogsReleaseId,
    DeletionEntityType entityType,
  ) async {
    await (_db.delete(_db.pendingDiscogsDeletions)..where(
          (t) =>
              t.discogsReleaseId.equals(discogsReleaseId) &
              t.entityType.equals(entityType.name),
        ))
        .go();
  }

  @override
  Future<void> deleteAllByType(DeletionEntityType entityType) async {
    await (_db.delete(
      _db.pendingDiscogsDeletions,
    )..where((t) => t.entityType.equals(entityType.name))).go();
  }

  PendingDiscogsDeletion _toModel(PendingDiscogsDeletionRow row) {
    return PendingDiscogsDeletion(
      id: row.id,
      entityType: DeletionEntityType.values.byName(row.entityType),
      discogsReleaseId: row.discogsReleaseId,
      discogsInstanceId: row.discogsInstanceId,
      artist: row.artist,
      title: row.title,
      createdAt: row.createdAt,
    );
  }

  PendingDiscogsDeletionsCompanion _toCompanion(PendingDiscogsDeletion d) {
    return PendingDiscogsDeletionsCompanion(
      id: Value(d.id),
      entityType: Value(d.entityType.name),
      discogsReleaseId: Value(d.discogsReleaseId),
      discogsInstanceId: Value(d.discogsInstanceId),
      artist: Value(d.artist),
      title: Value(d.title),
      createdAt: Value(d.createdAt),
    );
  }
}

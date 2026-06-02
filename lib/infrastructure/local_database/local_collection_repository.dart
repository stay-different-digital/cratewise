import 'package:drift/drift.dart';

import '../../domain/models/collection_item.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/collection_repository.dart';
import 'app_database.dart';

class LocalCollectionRepository implements CollectionRepository {
  LocalCollectionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<CollectionItem>> getAll() async {
    final rows = await (_db.select(_db.collectionItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_rowToItem).toList();
  }

  @override
  Future<CollectionItem?> getById(String id) async {
    final row = await (_db.select(_db.collectionItems)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _rowToItem(row);
  }

  @override
  Future<bool> containsRelease(int discogsReleaseId) async {
    final row = await (_db.select(_db.collectionItems)
          ..where((t) => t.discogsReleaseId.equals(discogsReleaseId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> add(CollectionItem item) async {
    await _db.into(_db.collectionItems).insert(_itemToCompanion(item));
  }

  @override
  Future<void> update(CollectionItem item) async {
    await (_db.update(_db.collectionItems)
          ..where((t) => t.id.equals(item.id)))
        .write(_itemToCompanion(item));
  }

  @override
  Future<void> remove(String id) async {
    await (_db.delete(_db.collectionItems)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  CollectionItem _rowToItem(CollectionRow row) {
    return CollectionItem(
      id: row.id,
      discogsReleaseId: row.discogsReleaseId,
      artist: row.artist,
      title: row.title,
      label: row.label,
      catno: row.catno,
      format: row.format,
      country: row.country,
      year: row.year,
      coverUrl: row.coverUrl,
      mediaCondition: row.mediaCondition,
      sleeveCondition: row.sleeveCondition,
      notes: row.notes,
      tags: row.tags,
      storageLocation: row.storageLocation,
      syncStatus: row.syncStatus ?? SyncStatus.localOnly,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  CollectionItemsCompanion _itemToCompanion(CollectionItem item) {
    return CollectionItemsCompanion(
      id: Value(item.id),
      discogsReleaseId: Value(item.discogsReleaseId),
      artist: Value(item.artist),
      title: Value(item.title),
      label: Value(item.label),
      catno: Value(item.catno),
      format: Value(item.format),
      country: Value(item.country),
      year: Value(item.year),
      coverUrl: Value(item.coverUrl),
      mediaCondition: Value(item.mediaCondition),
      sleeveCondition: Value(item.sleeveCondition),
      notes: Value(item.notes),
      tags: Value(item.tags),
      storageLocation: Value(item.storageLocation),
      syncStatus: Value(item.syncStatus),
      createdAt: Value(item.createdAt),
      updatedAt: Value(item.updatedAt),
    );
  }
}

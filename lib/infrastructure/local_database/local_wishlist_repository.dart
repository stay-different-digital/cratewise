import 'package:drift/drift.dart';

import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import 'app_database.dart';

class LocalWishlistRepository implements WishlistRepository {
  LocalWishlistRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<WishlistItem>> getAll() async {
    final rows = await (_db.select(
      _db.wishlistItems,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return rows.map(_rowToItem).toList();
  }

  @override
  Future<WishlistItem?> getById(String id) async {
    final row = await (_db.select(
      _db.wishlistItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _rowToItem(row);
  }

  @override
  Future<bool> containsRelease(int discogsReleaseId) async {
    final row =
        await (_db.select(_db.wishlistItems)
              ..where((t) => t.discogsReleaseId.equals(discogsReleaseId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> add(WishlistItem item) async {
    await _db.into(_db.wishlistItems).insert(_itemToCompanion(item));
  }

  @override
  Future<void> update(WishlistItem item) async {
    await (_db.update(
      _db.wishlistItems,
    )..where((t) => t.id.equals(item.id))).write(_itemToCompanion(item));
  }

  @override
  Future<void> remove(String id) async {
    await (_db.delete(_db.wishlistItems)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_db.wishlistItems).go();
  }

  WishlistItem _rowToItem(WishlistRow row) {
    return WishlistItem(
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
      targetPrice: row.targetPrice,
      priority: row.priority,
      notes: row.notes,
      syncStatus: row.syncStatus ?? SyncStatus.localOnly,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  WishlistItemsCompanion _itemToCompanion(WishlistItem item) {
    return WishlistItemsCompanion(
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
      targetPrice: Value(item.targetPrice),
      priority: Value(item.priority),
      notes: Value(item.notes),
      syncStatus: Value(item.syncStatus),
      createdAt: Value(item.createdAt),
      updatedAt: Value(item.updatedAt),
    );
  }
}

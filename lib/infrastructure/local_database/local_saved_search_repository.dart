import 'package:drift/drift.dart';

import '../../domain/models/saved_search.dart';
import '../../domain/repositories/saved_search_repository.dart';
import 'app_database.dart';

class LocalSavedSearchRepository implements SavedSearchRepository {
  LocalSavedSearchRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<SavedSearch>> getAll() async {
    final rows = await (_db.select(_db.savedSearches)
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  @override
  Future<List<SavedSearch>> getByType(SavedSearchType type) async {
    final rows = await (_db.select(_db.savedSearches)
          ..where((t) => t.type.equalsValue(type))
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  @override
  Future<void> save(SavedSearch search) async {
    await _db.into(_db.savedSearches).insertOnConflictUpdate(
      SavedSearchesCompanion(
        id: Value(search.id),
        name: Value(search.name),
        type: Value(search.type),
        payloadJson: Value(search.payloadJson),
        schemaVersion: Value(search.schemaVersion),
        createdAt: Value(search.createdAt),
        lastUsedAt: Value(search.lastUsedAt),
      ),
    );
  }

  @override
  Future<void> updateName(String id, String name) async {
    await (_db.update(_db.savedSearches)..where((t) => t.id.equals(id)))
        .write(SavedSearchesCompanion(name: Value(name)));
  }

  @override
  Future<void> updateLastUsed(String id, DateTime lastUsedAt) async {
    await (_db.update(_db.savedSearches)..where((t) => t.id.equals(id)))
        .write(SavedSearchesCompanion(lastUsedAt: Value(lastUsedAt)));
  }

  @override
  Future<void> remove(String id) async {
    await (_db.delete(_db.savedSearches)..where((t) => t.id.equals(id))).go();
  }

  SavedSearch _rowToModel(SavedSearchRow row) => SavedSearch(
    id: row.id,
    name: row.name,
    type: row.type,
    payloadJson: row.payloadJson,
    schemaVersion: row.schemaVersion,
    createdAt: row.createdAt,
    lastUsedAt: row.lastUsedAt,
  );
}

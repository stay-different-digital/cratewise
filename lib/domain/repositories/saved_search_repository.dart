import '../models/saved_search.dart';

abstract interface class SavedSearchRepository {
  Future<List<SavedSearch>> getAll();
  Future<List<SavedSearch>> getByType(SavedSearchType type);
  Future<void> save(SavedSearch search);
  Future<void> updateName(String id, String name);
  Future<void> updateLastUsed(String id, DateTime lastUsedAt);
  Future<void> remove(String id);
}

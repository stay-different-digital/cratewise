import '../models/collection_item.dart';

abstract interface class CollectionRepository {
  Future<List<CollectionItem>> getAll();
  Future<CollectionItem?> getById(String id);
  Future<bool> containsRelease(int discogsReleaseId);
  Future<void> add(CollectionItem item);
  Future<void> update(CollectionItem item);
  Future<void> remove(String id);

  /// Removes every collection item in a single transactional delete (US-82).
  Future<void> deleteAll();
}

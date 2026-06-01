import '../models/wishlist_item.dart';

abstract interface class WishlistRepository {
  Future<List<WishlistItem>> getAll();
  Future<WishlistItem?> getById(String id);
  Future<bool> containsRelease(int discogsReleaseId);
  Future<void> add(WishlistItem item);
  Future<void> update(WishlistItem item);
  Future<void> remove(String id);
}

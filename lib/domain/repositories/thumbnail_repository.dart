abstract interface class ThumbnailRepository {
  Future<String?> getLocalPath(int releaseId);
  Future<void> save(int releaseId, List<int> bytes);
  Future<void> remove(int releaseId);
  Future<bool> exists(int releaseId);
}

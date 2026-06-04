import '../models/thumbnail_entry.dart';

abstract interface class ThumbnailRepository {
  Future<String?> getLocalPath(int releaseId);
  Future<void> save(int releaseId, List<int> bytes);
  Future<void> remove(int releaseId);
  Future<bool> exists(int releaseId);
  Future<int> totalSizeBytes();
  Future<List<ThumbnailEntry>> listEntries();
  Future<void> removeAll();
}

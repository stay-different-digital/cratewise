import '../../domain/repositories/thumbnail_repository.dart';

const int kDefaultThumbnailCacheLimitBytes = 200 * 1024 * 1024; // 200 MB

class ThumbnailEvictionService {
  const ThumbnailEvictionService({required this._repository});

  final ThumbnailRepository _repository;

  Future<int> currentSizeBytes() => _repository.totalSizeBytes();

  Future<void> clearAll() => _repository.removeAll();

  Future<void> evictIfNeeded({
    int maxBytes = kDefaultThumbnailCacheLimitBytes,
  }) async {
    final total = await _repository.totalSizeBytes();
    if (total <= maxBytes) return;

    final entries = await _repository.listEntries();
    entries.sort((a, b) => a.lastModified.compareTo(b.lastModified));

    var remaining = total;
    for (final entry in entries) {
      if (remaining <= maxBytes) break;
      await _repository.remove(entry.releaseId);
      remaining -= entry.sizeBytes;
    }
  }
}

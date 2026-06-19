import '../models/cached_release_metadata.dart';

abstract interface class CachedReleaseMetadataRepository {
  Future<CachedReleaseMetadata?> getByReleaseId(int discogsReleaseId);
  Future<List<CachedReleaseMetadata>> getAll();
  Future<void> save(CachedReleaseMetadata metadata);
  Future<void> remove(int discogsReleaseId);
}

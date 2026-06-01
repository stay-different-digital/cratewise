import '../models/cached_release_metadata.dart';

abstract interface class CachedReleaseMetadataRepository {
  Future<CachedReleaseMetadata?> getByReleaseId(int discogsReleaseId);
  Future<void> save(CachedReleaseMetadata metadata);
  Future<void> remove(int discogsReleaseId);
}

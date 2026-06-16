import '../models/pending_discogs_deletion.dart';

/// Stores tombstones for items deleted locally that are still on Discogs,
/// pending propagation on the next export (US-72).
abstract interface class PendingDiscogsDeletionRepository {
  Future<void> add(PendingDiscogsDeletion deletion);

  /// All pending deletions for [entityType], oldest first.
  Future<List<PendingDiscogsDeletion>> getByType(DeletionEntityType entityType);

  /// Whether a pending deletion exists for [discogsReleaseId] in [entityType]
  /// (used to flag re-import conflicts).
  Future<bool> containsRelease(
    int discogsReleaseId,
    DeletionEntityType entityType,
  );

  Future<void> remove(String id);

  /// Clears any pending deletion for [discogsReleaseId] in [entityType] —
  /// e.g. when the user re-adds the same record locally.
  Future<void> removeByRelease(
    int discogsReleaseId,
    DeletionEntityType entityType,
  );

  /// Drops every pending deletion for [entityType] — used when the local list
  /// is cleared wholesale (US-82), so no orphaned tombstones remain.
  Future<void> deleteAllByType(DeletionEntityType entityType);
}

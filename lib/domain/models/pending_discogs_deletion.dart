/// Which Discogs list a deletion applies to.
enum DeletionEntityType { collection, wishlist }

/// A record that the user removed locally while it was still linked to
/// Discogs. It is kept as a "tombstone" so the change can be propagated to
/// Discogs on the next export (US-72) — and so a re-import surfaces it as a
/// conflict rather than silently re-adding the record.
class PendingDiscogsDeletion {
  const PendingDiscogsDeletion({
    required this.id,
    required this.entityType,
    required this.discogsReleaseId,
    required this.artist,
    required this.title,
    required this.createdAt,
    this.discogsInstanceId,
  });

  final String id;
  final DeletionEntityType entityType;
  final int discogsReleaseId;

  /// The Discogs collection instance id to delete. Required for collection
  /// deletions; null for wantlist deletions (which address by release id).
  final int? discogsInstanceId;

  final String artist;
  final String title;
  final DateTime createdAt;

  PendingDiscogsDeletion copyWith({
    String? id,
    DeletionEntityType? entityType,
    int? discogsReleaseId,
    int? discogsInstanceId,
    String? artist,
    String? title,
    DateTime? createdAt,
  }) {
    return PendingDiscogsDeletion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
      discogsInstanceId: discogsInstanceId ?? this.discogsInstanceId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

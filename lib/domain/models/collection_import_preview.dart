sealed class CollectionImportRow {
  const CollectionImportRow({
    required this.releaseId,
    required this.title,
    required this.artist,
    this.year,
    this.thumbUrl,
    this.instanceId,
  });

  final int releaseId;
  final String title;
  final String artist;
  final int? year;
  final String? thumbUrl;

  /// Discogs collection instance id for this row (US-72), carried through so
  /// imported and linked items can later be removed from Discogs.
  final int? instanceId;
}

/// Item is not yet in the local collection and has valid metadata.
class NewCollectionRow extends CollectionImportRow {
  const NewCollectionRow({
    required super.releaseId,
    required super.title,
    required super.artist,
    super.year,
    super.thumbUrl,
    super.instanceId,
  });
}

/// Item is already present in the local collection (matched by Discogs release ID).
class DuplicateCollectionRow extends CollectionImportRow {
  const DuplicateCollectionRow({
    required super.releaseId,
    required super.title,
    required super.artist,
    super.year,
    super.thumbUrl,
    super.instanceId,
    this.linkTargetId,
  });

  /// Local item this Discogs instance will be linked to; null when the
  /// instance is already linked (US-129).
  final String? linkTargetId;
}

/// Item cannot be imported because required metadata is missing or invalid.
/// [reason] is a safe, user-facing message — never contains tokens or secrets.
class InvalidCollectionRow extends CollectionImportRow {
  const InvalidCollectionRow({
    required super.releaseId,
    required super.title,
    required super.artist,
    required this.reason,
    super.year,
    super.thumbUrl,
  });

  final String reason;
}

/// Item is still on Discogs but was deleted locally and is awaiting removal
/// from Discogs (a pending-deletion tombstone exists, US-72). Re-importing it
/// would undo the user's deletion, so it is surfaced as a conflict and never
/// imported automatically.
class ConflictCollectionRow extends CollectionImportRow {
  const ConflictCollectionRow({
    required super.releaseId,
    required super.title,
    required super.artist,
    super.year,
    super.thumbUrl,
    super.instanceId,
  });
}

class CollectionImportPreview {
  const CollectionImportPreview({required this.rows});

  final List<CollectionImportRow> rows;

  int get totalCount => rows.length;
  int get newCount => rows.whereType<NewCollectionRow>().length;
  int get duplicateCount => rows.whereType<DuplicateCollectionRow>().length;
  int get invalidCount => rows.whereType<InvalidCollectionRow>().length;
  int get conflictCount => rows.whereType<ConflictCollectionRow>().length;
}

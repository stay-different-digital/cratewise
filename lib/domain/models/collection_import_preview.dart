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
  });
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

class CollectionImportPreview {
  const CollectionImportPreview({required this.rows});

  final List<CollectionImportRow> rows;

  int get totalCount => rows.length;
  int get newCount => rows.whereType<NewCollectionRow>().length;
  int get duplicateCount => rows.whereType<DuplicateCollectionRow>().length;
  int get invalidCount => rows.whereType<InvalidCollectionRow>().length;
}

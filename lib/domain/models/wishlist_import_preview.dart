import 'discogs_import_preview.dart';

sealed class WishlistImportRow {
  const WishlistImportRow({
    required this.releaseId,
    required this.title,
    required this.artist,
    this.year,
    this.thumbUrl,
  });

  final int releaseId;
  final String title;
  final String artist;
  final int? year;
  final String? thumbUrl;
}

/// Item is not yet in the local wishlist and has valid metadata.
class NewWishlistRow extends WishlistImportRow {
  const NewWishlistRow({
    required super.releaseId,
    required super.title,
    required super.artist,
    super.year,
    super.thumbUrl,
  });
}

/// Item is already present in the local wishlist (matched by Discogs release ID).
class DuplicateWishlistRow extends WishlistImportRow {
  const DuplicateWishlistRow({
    required super.releaseId,
    required super.title,
    required super.artist,
    super.year,
    super.thumbUrl,
  });
}

/// Item cannot be imported because required metadata is missing or invalid.
/// [reason] is a safe, user-facing message — never contains tokens or secrets.
class InvalidWishlistRow extends WishlistImportRow {
  const InvalidWishlistRow({
    required super.releaseId,
    required super.title,
    required super.artist,
    required this.reason,
    super.year,
    super.thumbUrl,
  });

  final String reason;
}

/// Item is still on the user's Discogs wantlist but was deleted locally and is
/// awaiting removal from Discogs (a pending-deletion tombstone exists, US-72).
/// Re-importing it would undo the user's deletion, so it is surfaced as a
/// conflict and never imported automatically (US-79).
class ConflictWishlistRow extends WishlistImportRow {
  const ConflictWishlistRow({
    required super.releaseId,
    required super.title,
    required super.artist,
    super.year,
    super.thumbUrl,
  });
}

class WishlistImportPreview implements DiscogsImportPreview {
  const WishlistImportPreview({required this.rows});

  final List<WishlistImportRow> rows;

  @override
  int get totalCount => rows.length;
  @override
  int get newCount => rows.whereType<NewWishlistRow>().length;
  @override
  int get duplicateCount => rows.whereType<DuplicateWishlistRow>().length;
  @override
  int get invalidCount => rows.whereType<InvalidWishlistRow>().length;
  @override
  int get conflictCount => rows.whereType<ConflictWishlistRow>().length;
}

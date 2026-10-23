import 'discogs_export_preview.dart';
import 'sync_status.dart';
import 'wishlist_item.dart';

sealed class WishlistExportRow {
  const WishlistExportRow({
    required this.itemId,
    required this.releaseId,
    required this.artist,
    required this.title,
    this.year,
    this.coverUrl,
  });

  final String itemId;
  final int releaseId;
  final String artist;
  final String title;
  final int? year;
  final String? coverUrl;
}

/// Item has a valid Discogs release ID and is not yet marked as synced.
/// It is ready to be exported to Discogs.
class EligibleWishlistExportRow extends WishlistExportRow {
  const EligibleWishlistExportRow({
    required super.itemId,
    required super.releaseId,
    required super.artist,
    required super.title,
    super.year,
    super.coverUrl,
  });
}

/// Item has a valid Discogs release ID and is already marked as synced,
/// indicating it was previously exported to or imported from Discogs.
class AlreadySyncedWishlistExportRow extends WishlistExportRow {
  const AlreadySyncedWishlistExportRow({
    required super.itemId,
    required super.releaseId,
    required super.artist,
    required super.title,
    super.year,
    super.coverUrl,
  });
}

/// Item cannot be exported. [reason] is safe for display — never a token or secret.
class InvalidWishlistExportRow extends WishlistExportRow {
  const InvalidWishlistExportRow({
    required super.itemId,
    required super.releaseId,
    required super.artist,
    required super.title,
    required this.reason,
    super.year,
    super.coverUrl,
  });

  final String reason;
}

/// Classifies [item] into the appropriate [WishlistExportRow] subtype.
WishlistExportRow classifyWishlistItemForExport(WishlistItem item) {
  if (item.discogsReleaseId <= 0) {
    return InvalidWishlistExportRow(
      itemId: item.id,
      releaseId: item.discogsReleaseId,
      artist: item.artist,
      title: item.title,
      year: item.year,
      coverUrl: item.coverUrl,
      reason: 'Missing Discogs release ID',
    );
  }
  if (item.syncStatus == SyncStatus.synced) {
    return AlreadySyncedWishlistExportRow(
      itemId: item.id,
      releaseId: item.discogsReleaseId,
      artist: item.artist,
      title: item.title,
      year: item.year,
      coverUrl: item.coverUrl,
    );
  }
  return EligibleWishlistExportRow(
    itemId: item.id,
    releaseId: item.discogsReleaseId,
    artist: item.artist,
    title: item.title,
    year: item.year,
    coverUrl: item.coverUrl,
  );
}

class WishlistExportPreview implements DiscogsExportPreview {
  const WishlistExportPreview({required this.rows});

  final List<WishlistExportRow> rows;

  @override
  int get totalCount => rows.length;
  @override
  int get eligibleCount => rows.whereType<EligibleWishlistExportRow>().length;
  @override
  int get alreadySyncedCount =>
      rows.whereType<AlreadySyncedWishlistExportRow>().length;
  @override
  int get invalidCount => rows.whereType<InvalidWishlistExportRow>().length;
}

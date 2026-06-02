import 'collection_item.dart';
import 'sync_status.dart';

sealed class CollectionExportRow {
  const CollectionExportRow({
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
class EligibleExportRow extends CollectionExportRow {
  const EligibleExportRow({
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
class AlreadySyncedExportRow extends CollectionExportRow {
  const AlreadySyncedExportRow({
    required super.itemId,
    required super.releaseId,
    required super.artist,
    required super.title,
    super.year,
    super.coverUrl,
  });
}

/// Item cannot be exported. [reason] is safe for display — never a token or secret.
class InvalidExportRow extends CollectionExportRow {
  const InvalidExportRow({
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

/// Classifies [item] into the appropriate [CollectionExportRow] subtype.
CollectionExportRow classifyForExport(CollectionItem item) {
  if (item.discogsReleaseId <= 0) {
    return InvalidExportRow(
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
    return AlreadySyncedExportRow(
      itemId: item.id,
      releaseId: item.discogsReleaseId,
      artist: item.artist,
      title: item.title,
      year: item.year,
      coverUrl: item.coverUrl,
    );
  }
  return EligibleExportRow(
    itemId: item.id,
    releaseId: item.discogsReleaseId,
    artist: item.artist,
    title: item.title,
    year: item.year,
    coverUrl: item.coverUrl,
  );
}

class CollectionExportPreview {
  const CollectionExportPreview({required this.rows});

  final List<CollectionExportRow> rows;

  int get totalCount => rows.length;
  int get eligibleCount => rows.whereType<EligibleExportRow>().length;
  int get alreadySyncedCount => rows.whereType<AlreadySyncedExportRow>().length;
  int get invalidCount => rows.whereType<InvalidExportRow>().length;
}

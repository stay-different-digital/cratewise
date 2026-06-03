import 'import_export_row_result.dart';
import 'wishlist_item.dart';

/// A single data row from a wishlist CSV that passed all validation checks.
class CsvWishlistImportRow {
  const CsvWishlistImportRow({
    required this.rowIndex,
    required this.artist,
    required this.title,
    required this.discogsReleaseId,
    required this.priority,
    this.label,
    this.catno,
    this.format,
    this.country,
    this.year,
    this.targetPrice,
    this.notes,
  });

  final int rowIndex;
  final String artist;
  final String title;
  final int discogsReleaseId;
  final WishlistPriority priority;
  final String? label;
  final String? catno;
  final String? format;
  final String? country;
  final int? year;
  final double? targetPrice;
  final String? notes;

  String get displayName => '$artist – $title';
}

/// Result of validating a wishlist CSV file.
///
/// [validRows] are ready to import, [skippedRows] had duplicate release IDs
/// within the file, and [failedRows] had validation errors.
class CsvWishlistImportPreview {
  const CsvWishlistImportPreview({
    required this.validRows,
    required this.skippedRows,
    required this.failedRows,
  });

  final List<CsvWishlistImportRow> validRows;
  final List<SkippedRow> skippedRows;
  final List<FailedRow> failedRows;

  int get validCount => validRows.length;
  int get skippedCount => skippedRows.length;
  int get failedCount => failedRows.length;
  int get totalCount => validCount + skippedCount + failedCount;
}

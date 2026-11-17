import 'csv_import_preview.dart';
import 'collection_item.dart';
import 'import_export_row_result.dart';

/// A single data row from a collection CSV that passed all validation checks.
class CsvCollectionImportRow {
  const CsvCollectionImportRow({
    required this.rowIndex,
    required this.artist,
    required this.title,
    required this.discogsReleaseId,
    required this.mediaCondition,
    required this.sleeveCondition,
    required this.tags,
    this.label,
    this.catno,
    this.format,
    this.country,
    this.year,
    this.notes,
    this.storageLocation,
  });

  final int rowIndex;
  final String artist;
  final String title;
  final int discogsReleaseId;
  final RecordCondition mediaCondition;
  final RecordCondition sleeveCondition;
  final List<String> tags;
  final String? label;
  final String? catno;
  final String? format;
  final String? country;
  final int? year;
  final String? notes;
  final String? storageLocation;

  String get displayName => '$artist – $title';
}

/// Result of validating a collection CSV file.
///
/// [validRows] are ready to import, [skippedRows] had duplicate release IDs
/// within the file, and [failedRows] had validation errors.
class CsvCollectionImportPreview implements CsvImportPreview {
  const CsvCollectionImportPreview({
    required this.validRows,
    required this.skippedRows,
    required this.failedRows,
  });

  final List<CsvCollectionImportRow> validRows;
  final List<SkippedRow> skippedRows;
  @override
  final List<FailedRow> failedRows;

  @override
  int get validCount => validRows.length;
  @override
  int get skippedCount => skippedRows.length;
  @override
  int get failedCount => failedRows.length;
  @override
  int get totalCount => validCount + skippedCount + failedCount;
}

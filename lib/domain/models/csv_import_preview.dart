import 'import_export_row_result.dart';

/// What collection and wishlist CSV imports have in common, so one preview
/// screen serves both (US-130).
abstract interface class CsvImportPreview {
  List<FailedRow> get failedRows;
  int get validCount;
  int get skippedCount;
  int get failedCount;
  int get totalCount;
}

abstract interface class CsvImportDone {
  int get imported;
  int get skipped;
  int get failed;
}

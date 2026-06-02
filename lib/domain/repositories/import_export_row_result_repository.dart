import '../models/import_export_row_result.dart';

abstract interface class ImportExportRowResultRepository {
  /// Stores a validation, preview, or error result for [jobId].
  Future<void> addResult(String jobId, ImportExportRowResult result);

  /// Returns all results for [jobId], ordered by [ImportExportRowResult.rowIndex] ascending.
  Future<List<ImportExportRowResult>> getResults(String jobId);

  Future<void> removeAllForJob(String jobId);
}

import 'package:drift/drift.dart';

import '../../domain/models/import_export_row_result.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';
import 'app_database.dart';

class LocalImportExportRowResultRepository
    implements ImportExportRowResultRepository {
  LocalImportExportRowResultRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> addResult(String jobId, ImportExportRowResult result) async {
    await _db
        .into(_db.importExportRowResults)
        .insert(_resultToCompanion(jobId, result));
  }

  @override
  Future<List<ImportExportRowResult>> getResults(String jobId) async {
    final rows = await (_db.select(_db.importExportRowResults)
          ..where((t) => t.jobId.equals(jobId))
          ..orderBy([(t) => OrderingTerm.asc(t.rowIndex)]))
        .get();
    return rows.map(_rowToResult).toList();
  }

  @override
  Future<void> removeAllForJob(String jobId) async {
    await (_db.delete(_db.importExportRowResults)
          ..where((t) => t.jobId.equals(jobId)))
        .go();
  }

  ImportExportRowResult _rowToResult(ImportExportRowResultRow row) {
    return switch (row.resultType) {
      'valid' => ValidRow(
          rowIndex: row.rowIndex,
          description: row.description!,
        ),
      'skipped' => SkippedRow(
          rowIndex: row.rowIndex,
          reason: row.reason!,
        ),
      'failed' => FailedRow(
          rowIndex: row.rowIndex,
          safeErrorMessage: row.safeErrorMessage!,
        ),
      _ => throw StateError('Unknown result type: ${row.resultType}'),
    };
  }

  ImportExportRowResultsCompanion _resultToCompanion(
    String jobId,
    ImportExportRowResult result,
  ) {
    return switch (result) {
      ValidRow() => ImportExportRowResultsCompanion(
          jobId: Value(jobId),
          resultType: const Value('valid'),
          rowIndex: Value(result.rowIndex),
          description: Value(result.description),
          reason: const Value(null),
          safeErrorMessage: const Value(null),
        ),
      SkippedRow() => ImportExportRowResultsCompanion(
          jobId: Value(jobId),
          resultType: const Value('skipped'),
          rowIndex: Value(result.rowIndex),
          description: const Value(null),
          reason: Value(result.reason),
          safeErrorMessage: const Value(null),
        ),
      FailedRow() => ImportExportRowResultsCompanion(
          jobId: Value(jobId),
          resultType: const Value('failed'),
          rowIndex: Value(result.rowIndex),
          description: const Value(null),
          reason: const Value(null),
          safeErrorMessage: Value(result.safeErrorMessage),
        ),
    };
  }
}

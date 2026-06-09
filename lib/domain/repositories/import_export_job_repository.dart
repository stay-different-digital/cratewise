import '../models/import_export_job.dart';

abstract interface class ImportExportJobRepository {
  Future<void> add(ImportExportJob job);
  Future<void> update(ImportExportJob job);
  Future<ImportExportJob?> getById(String id);

  /// Returns jobs ordered by [ImportExportJob.createdAt] descending.
  Future<List<ImportExportJob>> getRecent({int limit = 20, int offset = 0});

  /// Returns the total number of stored jobs.
  Future<int> count();

  Future<void> remove(String id);
}

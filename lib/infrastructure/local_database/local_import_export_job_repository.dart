import 'package:drift/drift.dart';

import '../../domain/models/import_export_job.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import 'app_database.dart';

class LocalImportExportJobRepository implements ImportExportJobRepository {
  LocalImportExportJobRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> add(ImportExportJob job) async {
    await _db.into(_db.importExportJobs).insert(_jobToCompanion(job));
  }

  @override
  Future<void> update(ImportExportJob job) async {
    await (_db.update(
      _db.importExportJobs,
    )..where((t) => t.id.equals(job.id))).write(_jobToCompanion(job));
  }

  @override
  Future<ImportExportJob?> getById(String id) async {
    final row = await (_db.select(
      _db.importExportJobs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _rowToJob(row);
  }

  @override
  Future<List<ImportExportJob>> getRecent({
    int limit = 20,
    int offset = 0,
  }) async {
    final rows =
        await (_db.select(_db.importExportJobs)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(limit, offset: offset))
            .get();
    return rows.map(_rowToJob).toList();
  }

  @override
  Future<int> count() async {
    final countExpr = _db.importExportJobs.id.count();
    final row = await (_db.selectOnly(
      _db.importExportJobs,
    )..addColumns([countExpr])).getSingle();
    return row.read(countExpr) ?? 0;
  }

  @override
  Future<void> remove(String id) async {
    await (_db.delete(
      _db.importExportJobs,
    )..where((t) => t.id.equals(id))).go();
  }

  ImportExportJob _rowToJob(ImportExportJobRow row) {
    return ImportExportJob(
      id: row.id,
      jobType: row.jobType,
      source: row.source,
      target: row.target,
      status: row.status,
      totalItems: row.totalItems,
      validItems: row.validItems,
      skippedItems: row.skippedItems,
      failedItems: row.failedItems,
      safeErrorMessage: row.safeErrorMessage,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ImportExportJobsCompanion _jobToCompanion(ImportExportJob job) {
    return ImportExportJobsCompanion(
      id: Value(job.id),
      jobType: Value(job.jobType),
      source: Value(job.source),
      target: Value(job.target),
      status: Value(job.status),
      totalItems: Value(job.totalItems),
      validItems: Value(job.validItems),
      skippedItems: Value(job.skippedItems),
      failedItems: Value(job.failedItems),
      safeErrorMessage: Value(job.safeErrorMessage),
      createdAt: Value(job.createdAt),
      updatedAt: Value(job.updatedAt),
    );
  }
}

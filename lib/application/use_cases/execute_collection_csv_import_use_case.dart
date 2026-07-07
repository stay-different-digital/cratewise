import 'package:uuid/uuid.dart';

import '../../domain/models/collection_item.dart';
import '../../domain/models/csv_collection_import_preview.dart';
import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';

sealed class ExecuteCollectionCsvImportResult {
  const ExecuteCollectionCsvImportResult();
}

class ExecuteCollectionCsvImportCompleted
    extends ExecuteCollectionCsvImportResult {
  const ExecuteCollectionCsvImportCompleted({
    required this.jobId,
    required this.imported,
    required this.skipped,
    required this.failed,
  });

  final String jobId;
  final int imported;
  final int skipped;
  final int failed;
}

class ExecuteCollectionCsvImportFailed
    extends ExecuteCollectionCsvImportResult {
  const ExecuteCollectionCsvImportFailed(this.safeMessage);

  final String safeMessage;
}

class ExecuteCollectionCsvImportUseCase {
  ExecuteCollectionCsvImportUseCase({
    required this._collectionRepository,
    required this._jobRepository,
    required this._rowResultRepository,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? _newUuid;

  static String _newUuid() => const Uuid().v4();

  final CollectionRepository _collectionRepository;
  final ImportExportJobRepository _jobRepository;
  final ImportExportRowResultRepository _rowResultRepository;
  final String Function() _idGenerator;

  Future<ExecuteCollectionCsvImportResult> execute(
    CsvCollectionImportPreview preview,
  ) async {
    final jobId = _idGenerator();
    final now = DateTime.now();

    final job = ImportExportJob(
      id: jobId,
      jobType: ImportExportJobType.csvCollectionImport,
      source: 'CSV file',
      target: 'Local collection',
      status: ImportExportStatus.running,
      totalItems: preview.totalCount,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _jobRepository.add(job);

      var imported = 0;
      var skipped = 0;
      var failed = 0;

      for (final row in preview.validRows) {
        try {
          final exists = await _collectionRepository.containsRelease(
            row.discogsReleaseId,
          );
          if (exists) {
            await _rowResultRepository.addResult(
              jobId,
              SkippedRow(
                rowIndex: row.rowIndex,
                reason: 'Already in collection',
              ),
            );
            skipped++;
          } else {
            await _collectionRepository.add(_buildItem(row));
            await _rowResultRepository.addResult(
              jobId,
              ValidRow(rowIndex: row.rowIndex, description: row.displayName),
            );
            imported++;
          }
        } catch (_) {
          await _rowResultRepository.addResult(
            jobId,
            FailedRow(
              rowIndex: row.rowIndex,
              safeErrorMessage: 'Could not save item',
            ),
          );
          failed++;
        }
      }

      for (final row in preview.skippedRows) {
        await _rowResultRepository.addResult(jobId, row);
        skipped++;
      }

      for (final row in preview.failedRows) {
        await _rowResultRepository.addResult(jobId, row);
        failed++;
      }

      final finalStatus = failed > 0
          ? ImportExportStatus.completedWithErrors
          : ImportExportStatus.completed;

      await _jobRepository.update(
        job.copyWith(
          status: finalStatus,
          validItems: imported,
          skippedItems: skipped,
          failedItems: failed,
          updatedAt: DateTime.now(),
        ),
      );

      return ExecuteCollectionCsvImportCompleted(
        jobId: jobId,
        imported: imported,
        skipped: skipped,
        failed: failed,
      );
    } catch (_) {
      try {
        await _jobRepository.update(
          job.copyWith(
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Import could not be completed',
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {}
      return const ExecuteCollectionCsvImportFailed(
        'Import could not be completed',
      );
    }
  }

  CollectionItem _buildItem(CsvCollectionImportRow row) {
    final now = DateTime.now();
    return CollectionItem(
      id: _idGenerator(),
      discogsReleaseId: row.discogsReleaseId,
      artist: row.artist,
      title: row.title,
      label: row.label,
      catno: row.catno,
      format: row.format,
      country: row.country,
      year: row.year,
      mediaCondition: row.mediaCondition,
      sleeveCondition: row.sleeveCondition,
      notes: row.notes,
      tags: row.tags,
      storageLocation: row.storageLocation,
      syncStatus: SyncStatus.localOnly,
      createdAt: now,
      updatedAt: now,
      bpm: row.bpm,
      musicalKey: row.musicalKey,
      energyLevel: row.energyLevel,
      gigCrates: row.gigCrates,
    );
  }
}

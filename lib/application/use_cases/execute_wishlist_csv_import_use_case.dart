import 'package:uuid/uuid.dart';

import '../../domain/models/csv_wishlist_import_preview.dart';
import '../../domain/models/csv_import_preview.dart';
import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../shared/errors/app_error.dart';

sealed class ExecuteWishlistCsvImportResult {
  const ExecuteWishlistCsvImportResult();
}

class ExecuteWishlistCsvImportCompleted extends ExecuteWishlistCsvImportResult
    implements CsvImportDone {
  const ExecuteWishlistCsvImportCompleted({
    required this.jobId,
    required this.imported,
    required this.skipped,
    required this.failed,
  });

  final String jobId;
  @override
  final int imported;
  @override
  final int skipped;
  @override
  final int failed;
}

class ExecuteWishlistCsvImportFailed extends ExecuteWishlistCsvImportResult {
  const ExecuteWishlistCsvImportFailed(this.safeMessage);

  final String safeMessage;
}

class ExecuteWishlistCsvImportUseCase {
  ExecuteWishlistCsvImportUseCase({
    required this._wishlistRepository,
    required this._jobRepository,
    required this._rowResultRepository,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? _newUuid;

  static String _newUuid() => const Uuid().v4();

  final WishlistRepository _wishlistRepository;
  final ImportExportJobRepository _jobRepository;
  final ImportExportRowResultRepository _rowResultRepository;
  final String Function() _idGenerator;

  Future<ExecuteWishlistCsvImportResult> execute(
    CsvWishlistImportPreview preview,
  ) async {
    final jobId = _idGenerator();
    final now = DateTime.now();

    final job = ImportExportJob(
      id: jobId,
      jobType: ImportExportJobType.csvWishlistImport,
      source: 'CSV file',
      target: 'Local wishlist',
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
          final exists = await _wishlistRepository.containsRelease(
            row.discogsReleaseId,
          );
          if (exists) {
            await _rowResultRepository.addResult(
              jobId,
              SkippedRow(rowIndex: row.rowIndex, reason: 'Already in wishlist'),
            );
            skipped++;
          } else {
            await _wishlistRepository.add(_buildItem(row));
            await _rowResultRepository.addResult(
              jobId,
              ValidRow(rowIndex: row.rowIndex, description: row.displayName),
            );
            imported++;
          }
        } catch (e, st) {
          logSwallowed(e, st, 'ExecuteWishlistCsvImportUseCase');
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

      return ExecuteWishlistCsvImportCompleted(
        jobId: jobId,
        imported: imported,
        skipped: skipped,
        failed: failed,
      );
    } catch (e, st) {
      logSwallowed(e, st, 'ExecuteWishlistCsvImportUseCase');
      try {
        await _jobRepository.update(
          job.copyWith(
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Import could not be completed',
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {
        // best-effort: a failure here must not mask the original outcome
      }
      return const ExecuteWishlistCsvImportFailed(
        'Import could not be completed',
      );
    }
  }

  WishlistItem _buildItem(CsvWishlistImportRow row) {
    final now = DateTime.now();
    return WishlistItem(
      id: _idGenerator(),
      discogsReleaseId: row.discogsReleaseId,
      artist: row.artist,
      title: row.title,
      label: row.label,
      catno: row.catno,
      format: row.format,
      country: row.country,
      year: row.year,
      targetPrice: row.targetPrice,
      priority: row.priority,
      notes: row.notes,
      syncStatus: SyncStatus.localOnly,
      createdAt: now,
      updatedAt: now,
    );
  }
}

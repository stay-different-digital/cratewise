import 'package:uuid/uuid.dart';

import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_import_preview.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';

sealed class ExecuteWishlistImportResult {
  const ExecuteWishlistImportResult();
}

class ExecuteWishlistImportCompleted extends ExecuteWishlistImportResult {
  const ExecuteWishlistImportCompleted({
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

class ExecuteWishlistImportFailed extends ExecuteWishlistImportResult {
  const ExecuteWishlistImportFailed(this.safeMessage);

  final String safeMessage;
}

class ExecuteWishlistImportUseCase {
  ExecuteWishlistImportUseCase({
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

  Future<ExecuteWishlistImportResult> execute(
    WishlistImportPreview preview,
  ) async {
    final jobId = _idGenerator();
    final now = DateTime.now();

    final job = ImportExportJob(
      id: jobId,
      jobType: ImportExportJobType.importWishlistFromDiscogs,
      source: 'Discogs',
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

      for (var i = 0; i < preview.rows.length; i++) {
        final row = preview.rows[i];
        switch (row) {
          case NewWishlistRow():
            try {
              await _wishlistRepository.add(_buildItem(row));
              await _rowResultRepository.addResult(
                jobId,
                ValidRow(
                  rowIndex: i,
                  description: '${row.artist} – ${row.title}',
                ),
              );
              imported++;
            } catch (_) {
              await _rowResultRepository.addResult(
                jobId,
                FailedRow(rowIndex: i, safeErrorMessage: 'Could not save item'),
              );
              failed++;
            }
          case DuplicateWishlistRow():
            await _rowResultRepository.addResult(
              jobId,
              SkippedRow(rowIndex: i, reason: 'Already in wishlist'),
            );
            skipped++;
          case InvalidWishlistRow():
            await _rowResultRepository.addResult(
              jobId,
              SkippedRow(rowIndex: i, reason: 'Missing information'),
            );
            skipped++;
        }
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

      return ExecuteWishlistImportCompleted(
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
      return const ExecuteWishlistImportFailed('Import could not be completed');
    }
  }

  WishlistItem _buildItem(NewWishlistRow row) {
    final now = DateTime.now();
    return WishlistItem(
      id: _idGenerator(),
      discogsReleaseId: row.releaseId,
      artist: row.artist,
      title: row.title,
      year: row.year,
      coverUrl: row.thumbUrl,
      priority: WishlistPriority.medium,
      syncStatus: SyncStatus.localOnly,
      createdAt: now,
      updatedAt: now,
    );
  }
}

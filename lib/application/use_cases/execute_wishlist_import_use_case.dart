import 'package:uuid/uuid.dart';

import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_import_preview.dart';
import '../../domain/models/discogs_import_preview.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';
import '../../domain/repositories/transaction_runner.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../shared/errors/app_error.dart';

sealed class ExecuteWishlistImportResult {
  const ExecuteWishlistImportResult();
}

class ExecuteWishlistImportCompleted extends ExecuteWishlistImportResult
    implements DiscogsImportDone {
  const ExecuteWishlistImportCompleted({
    required this.jobId,
    required this.imported,
    required this.skipped,
    required this.failed,
    this.linked = 0,
  });

  final String jobId;
  @override
  final int imported;
  @override
  final int skipped;
  @override
  final int failed;
  @override
  final int linked;
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
    this._transactionRunner,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? _newUuid;

  static String _newUuid() => const Uuid().v4();

  final WishlistRepository _wishlistRepository;
  final ImportExportJobRepository _jobRepository;
  final ImportExportRowResultRepository _rowResultRepository;
  final TransactionRunner? _transactionRunner;
  final String Function() _idGenerator;

  /// Runs [action] inside a single transaction when a [TransactionRunner] is
  /// available, so the import is one fast commit instead of thousands of
  /// per-insert transactions. Without one, runs the action directly.
  Future<T> _maybeTransaction<T>(Future<T> Function() action) =>
      _transactionRunner?.run(action) ?? action();

  Future<ExecuteWishlistImportResult> execute(
    WishlistImportPreview preview, {
    void Function(int current, int total, String description)? onProgress,
  }) async {
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

    var imported = 0;
    var skipped = 0;
    var failed = 0;
    var linked = 0;

    try {
      await _maybeTransaction(() async {
        await _jobRepository.add(job);

        // Build release-ID lookup for duplicate-linking in one getAll() call.
        final hasDuplicates = preview.rows.any(
          (r) => r is DuplicateWishlistRow,
        );
        final Map<int, WishlistItem> existingByReleaseId = {};
        if (hasDuplicates) {
          for (final item in await _wishlistRepository.getAll()) {
            existingByReleaseId[item.discogsReleaseId] = item;
          }
        }

        for (var i = 0; i < preview.rows.length; i++) {
          final row = preview.rows[i];
          onProgress?.call(i + 1, preview.rows.length, _rowLabel(row));
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
              } catch (e, st) {
                logSwallowed(e, st, 'ExecuteWishlistImportUseCase');
                await _rowResultRepository.addResult(
                  jobId,
                  FailedRow(
                    rowIndex: i,
                    safeErrorMessage: 'Could not save item',
                  ),
                );
                failed++;
              }
            case DuplicateWishlistRow():
              final existing = existingByReleaseId[row.releaseId];
              if (existing != null &&
                  existing.syncStatus != SyncStatus.synced) {
                try {
                  await _wishlistRepository.update(
                    existing.copyWith(
                      syncStatus: SyncStatus.synced,
                      updatedAt: DateTime.now(),
                    ),
                  );
                  await _rowResultRepository.addResult(
                    jobId,
                    ValidRow(
                      rowIndex: i,
                      description: 'Linked: ${row.artist} – ${row.title}',
                    ),
                  );
                  linked++;
                } catch (e, st) {
                  logSwallowed(e, st, 'ExecuteWishlistImportUseCase');
                  await _rowResultRepository.addResult(
                    jobId,
                    FailedRow(
                      rowIndex: i,
                      safeErrorMessage: 'Could not link item',
                    ),
                  );
                  failed++;
                }
              } else {
                await _rowResultRepository.addResult(
                  jobId,
                  SkippedRow(rowIndex: i, reason: 'Already linked to Discogs'),
                );
                skipped++;
              }
            case ConflictWishlistRow():
              await _rowResultRepository.addResult(
                jobId,
                SkippedRow(
                  rowIndex: i,
                  reason: 'Deleted locally — kept off Discogs',
                ),
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
            validItems: imported + linked,
            skippedItems: skipped,
            failedItems: failed,
            updatedAt: DateTime.now(),
          ),
        );
      });

      return ExecuteWishlistImportCompleted(
        jobId: jobId,
        imported: imported,
        skipped: skipped,
        failed: failed,
        linked: linked,
      );
    } catch (e, st) {
      logSwallowed(e, st, 'ExecuteWishlistImportUseCase');
      // The transaction rolled back, so nothing was persisted — record a
      // failed job (add, not update: the running record was rolled back too).
      try {
        await _jobRepository.add(
          job.copyWith(
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Import could not be completed',
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {
        // best-effort: a failure here must not mask the original outcome
      }
      return const ExecuteWishlistImportFailed('Import could not be completed');
    }
  }

  String _rowLabel(WishlistImportRow row) => switch (row) {
    NewWishlistRow(:final artist, :final title) => '$artist – $title',
    DuplicateWishlistRow(:final artist, :final title) => '$artist – $title',
    ConflictWishlistRow(:final artist, :final title) => '$artist – $title',
    InvalidWishlistRow() => 'Skipped row',
  };

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
      syncStatus: SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
    );
  }
}

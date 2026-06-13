import 'package:uuid/uuid.dart';

import '../../domain/models/collection_import_preview.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';
import '../../domain/repositories/transaction_runner.dart';

sealed class ExecuteCollectionImportResult {
  const ExecuteCollectionImportResult();
}

class ExecuteImportCompleted extends ExecuteCollectionImportResult {
  const ExecuteImportCompleted({
    required this.jobId,
    required this.imported,
    required this.skipped,
    required this.failed,
    this.linked = 0,
  });

  final String jobId;
  final int imported;
  final int skipped;
  final int failed;
  final int linked;
}

class ExecuteImportFailed extends ExecuteCollectionImportResult {
  const ExecuteImportFailed(this.safeMessage);

  final String safeMessage;
}

class ExecuteCollectionImportUseCase {
  ExecuteCollectionImportUseCase({
    required this._collectionRepository,
    required this._jobRepository,
    required this._rowResultRepository,
    this._transactionRunner,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? _newUuid;

  static String _newUuid() => const Uuid().v4();

  final CollectionRepository _collectionRepository;
  final ImportExportJobRepository _jobRepository;
  final ImportExportRowResultRepository _rowResultRepository;
  final TransactionRunner? _transactionRunner;
  final String Function() _idGenerator;

  /// Runs [action] inside a single transaction when a [TransactionRunner] is
  /// available, so the import is one fast commit instead of thousands of
  /// per-insert transactions. Without one, runs the action directly.
  Future<T> _maybeTransaction<T>(Future<T> Function() action) =>
      _transactionRunner?.run(action) ?? action();

  Future<ExecuteCollectionImportResult> execute(
    CollectionImportPreview preview, {
    void Function(int current, int total, String description)? onProgress,
  }) async {
    final jobId = _idGenerator();
    final now = DateTime.now();

    final job = ImportExportJob(
      id: jobId,
      jobType: ImportExportJobType.importCollectionFromDiscogs,
      source: 'Discogs',
      target: 'Local collection',
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
          (r) => r is DuplicateCollectionRow,
        );
        final Map<int, CollectionItem> existingByReleaseId = {};
        if (hasDuplicates) {
          for (final item in await _collectionRepository.getAll()) {
            existingByReleaseId[item.discogsReleaseId] = item;
          }
        }

        for (var i = 0; i < preview.rows.length; i++) {
          final row = preview.rows[i];
          onProgress?.call(i + 1, preview.rows.length, _rowLabel(row));
          switch (row) {
            case NewCollectionRow():
              try {
                await _collectionRepository.add(_buildItem(row));
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
                  FailedRow(
                    rowIndex: i,
                    safeErrorMessage: 'Could not save item',
                  ),
                );
                failed++;
              }
            case DuplicateCollectionRow():
              final existing = existingByReleaseId[row.releaseId];
              if (existing != null &&
                  existing.syncStatus != SyncStatus.synced) {
                try {
                  await _collectionRepository.update(
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
                } catch (_) {
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
            case InvalidCollectionRow():
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

      return ExecuteImportCompleted(
        jobId: jobId,
        imported: imported,
        skipped: skipped,
        failed: failed,
        linked: linked,
      );
    } catch (_) {
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
      } catch (_) {}
      return const ExecuteImportFailed('Import could not be completed');
    }
  }

  String _rowLabel(CollectionImportRow row) => switch (row) {
    NewCollectionRow(:final artist, :final title) => '$artist – $title',
    DuplicateCollectionRow(:final artist, :final title) => '$artist – $title',
    InvalidCollectionRow() => 'Skipped row',
  };

  CollectionItem _buildItem(NewCollectionRow row) {
    final now = DateTime.now();
    return CollectionItem(
      id: _idGenerator(),
      discogsReleaseId: row.releaseId,
      artist: row.artist,
      title: row.title,
      year: row.year,
      coverUrl: row.thumbUrl,
      mediaCondition: RecordCondition.notSet,
      sleeveCondition: RecordCondition.notSet,
      tags: const [],
      syncStatus: SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
    );
  }
}

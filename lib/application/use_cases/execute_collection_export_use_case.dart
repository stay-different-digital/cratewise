import 'package:uuid/uuid.dart';

import '../../domain/models/collection_export_preview.dart';
import '../../domain/models/discogs_export_preview.dart';
import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../shared/errors/app_error.dart';
import 'check_collection_export_capability_use_case.dart';

const _kRateLimitRetryDelay = Duration(seconds: 60);
const _kMaxItemRetries = 3;

sealed class ExecuteCollectionExportResult {
  const ExecuteCollectionExportResult();
}

class ExecuteExportCompleted extends ExecuteCollectionExportResult
    implements DiscogsExportDone {
  const ExecuteExportCompleted({
    required this.jobId,
    required this.exported,
    required this.skipped,
    required this.failed,
  });

  final String jobId;
  @override
  final int exported;
  @override
  final int skipped;
  @override
  final int failed;
}

/// Export to Discogs is not supported by the current API client.
/// [reason] is a safe, user-facing message.
class ExecuteExportNotSupported extends ExecuteCollectionExportResult {
  const ExecuteExportNotSupported(this.reason);

  final String reason;
}

/// No token or username is stored; the user must connect their Discogs account.
class ExecuteExportNoToken extends ExecuteCollectionExportResult {
  const ExecuteExportNoToken();
}

class ExecuteExportFailed extends ExecuteCollectionExportResult {
  const ExecuteExportFailed(this.safeMessage);

  final String safeMessage;
}

class ExecuteCollectionExportUseCase {
  ExecuteCollectionExportUseCase({
    required this._capabilityUseCase,
    required this._tokenStorage,
    required this._apiClient,
    required this._collectionRepository,
    required this._jobRepository,
    required this._rowResultRepository,
    String Function()? idGenerator,
    Future<void> Function(Duration)? delay,
    int? maxItemRetries,
  }) : _idGenerator = idGenerator ?? _newUuid,
       _delay = delay ?? ((d) => Future.delayed(d)),
       _maxItemRetries = maxItemRetries ?? _kMaxItemRetries;

  static String _newUuid() => const Uuid().v4();

  final CheckCollectionExportCapabilityUseCase _capabilityUseCase;
  final TokenStorage _tokenStorage;
  final DiscogsApiClient _apiClient;
  final CollectionRepository _collectionRepository;
  final ImportExportJobRepository _jobRepository;
  final ImportExportRowResultRepository _rowResultRepository;
  final String Function() _idGenerator;
  final Future<void> Function(Duration) _delay;
  final int _maxItemRetries;

  Future<ExecuteCollectionExportResult> execute(
    CollectionExportPreview preview, {
    void Function(int current, int total, String description)? onProgress,
  }) async {
    final capability = _capabilityUseCase.execute();
    if (capability is CollectionExportNotSupported) {
      return ExecuteExportNotSupported(capability.reason);
    }

    final String token;
    final String username;
    try {
      final t = await _tokenStorage.loadToken();
      final u = await _tokenStorage.loadUsername();
      if (t == null || t.isEmpty || u == null || u.isEmpty) {
        return const ExecuteExportNoToken();
      }
      token = t;
      username = u;
    } catch (e, st) {
      logSwallowed(e, st, 'ExecuteCollectionExportUseCase');
      return const ExecuteExportNoToken();
    }

    final jobId = _idGenerator();
    final now = DateTime.now();

    final job = ImportExportJob(
      id: jobId,
      jobType: ImportExportJobType.exportCollectionToDiscogs,
      source: 'Local collection',
      target: 'Discogs',
      status: ImportExportStatus.running,
      totalItems: preview.totalCount,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _jobRepository.add(job);

      var exported = 0;
      var skipped = 0;
      var failed = 0;
      var eligibleIndex = 0;
      final eligibleTotal = preview.eligibleCount;

      for (var i = 0; i < preview.rows.length; i++) {
        final row = preview.rows[i];
        switch (row) {
          case EligibleExportRow():
            eligibleIndex++;
            onProgress?.call(
              eligibleIndex,
              eligibleTotal,
              '${row.artist} – ${row.title}',
            );
            try {
              final instanceId = await _addToCollectionWithRetry(
                username,
                row.releaseId,
                token,
              );
              final item = await _collectionRepository.getById(row.itemId);
              if (item != null) {
                await _collectionRepository.update(
                  item.copyWith(
                    syncStatus: SyncStatus.synced,
                    discogsInstanceId: instanceId,
                    updatedAt: DateTime.now(),
                  ),
                );
              }
              await _rowResultRepository.addResult(
                jobId,
                ValidRow(
                  rowIndex: i,
                  description: '${row.artist} – ${row.title}',
                ),
              );
              exported++;
            } catch (e) {
              if (e is AppError) await _tokenStorage.clearIfRevoked(e);
              try {
                final failedItem = await _collectionRepository.getById(
                  row.itemId,
                );
                if (failedItem != null) {
                  await _collectionRepository.update(
                    failedItem.copyWith(
                      syncStatus: SyncStatus.failed,
                      updatedAt: DateTime.now(),
                    ),
                  );
                }
              } catch (_) {
                // best-effort: a failure here must not mask the original outcome
              }
              await _rowResultRepository.addResult(
                jobId,
                FailedRow(
                  rowIndex: i,
                  safeErrorMessage: 'Could not export item',
                ),
              );
              failed++;
            }
          case AlreadySyncedExportRow():
            await _rowResultRepository.addResult(
              jobId,
              SkippedRow(rowIndex: i, reason: 'Already linked to Discogs'),
            );
            skipped++;
          case InvalidExportRow():
            await _rowResultRepository.addResult(
              jobId,
              SkippedRow(rowIndex: i, reason: 'Missing Discogs release ID'),
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
          validItems: exported,
          skippedItems: skipped,
          failedItems: failed,
          updatedAt: DateTime.now(),
        ),
      );

      return ExecuteExportCompleted(
        jobId: jobId,
        exported: exported,
        skipped: skipped,
        failed: failed,
      );
    } catch (e, st) {
      logSwallowed(e, st, 'ExecuteCollectionExportUseCase');
      try {
        await _jobRepository.update(
          job.copyWith(
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Export could not be completed',
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {
        // best-effort: a failure here must not mask the original outcome
      }
      return const ExecuteExportFailed('Export could not be completed');
    }
  }

  Future<int?> _addToCollectionWithRetry(
    String username,
    int releaseId,
    String token,
  ) async {
    var attempts = 0;
    while (true) {
      try {
        return await _apiClient.addToCollection(username, releaseId, token);
      } on RateLimitedError {
        if (attempts >= _maxItemRetries) rethrow;
        attempts++;
        await _delay(_kRateLimitRetryDelay);
      }
    }
  }
}

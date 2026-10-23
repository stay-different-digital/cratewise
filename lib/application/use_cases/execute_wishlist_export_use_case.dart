import 'package:uuid/uuid.dart';

import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_export_preview.dart';
import '../../domain/models/discogs_export_preview.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';
import '../../domain/repositories/token_storage.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../shared/errors/app_error.dart';
import 'check_wishlist_export_capability_use_case.dart';

const _kRateLimitRetryDelay = Duration(seconds: 60);
const _kMaxItemRetries = 3;

sealed class ExecuteWishlistExportResult {
  const ExecuteWishlistExportResult();
}

class ExecuteWishlistExportCompleted extends ExecuteWishlistExportResult
    implements DiscogsExportDone {
  const ExecuteWishlistExportCompleted({
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
class ExecuteWishlistExportNotSupported extends ExecuteWishlistExportResult {
  const ExecuteWishlistExportNotSupported(this.reason);

  final String reason;
}

/// No token or username is stored; the user must connect their Discogs account.
class ExecuteWishlistExportNoToken extends ExecuteWishlistExportResult {
  const ExecuteWishlistExportNoToken();
}

class ExecuteWishlistExportFailed extends ExecuteWishlistExportResult {
  const ExecuteWishlistExportFailed(this.safeMessage);

  final String safeMessage;
}

class ExecuteWishlistExportUseCase {
  ExecuteWishlistExportUseCase({
    required this._capabilityUseCase,
    required this._tokenStorage,
    required this._apiClient,
    required this._wishlistRepository,
    required this._jobRepository,
    required this._rowResultRepository,
    String Function()? idGenerator,
    Future<void> Function(Duration)? delay,
    int? maxItemRetries,
  }) : _idGenerator = idGenerator ?? _newUuid,
       _delay = delay ?? ((d) => Future.delayed(d)),
       _maxItemRetries = maxItemRetries ?? _kMaxItemRetries;

  static String _newUuid() => const Uuid().v4();

  final CheckWishlistExportCapabilityUseCase _capabilityUseCase;
  final TokenStorage _tokenStorage;
  final DiscogsApiClient _apiClient;
  final WishlistRepository _wishlistRepository;
  final ImportExportJobRepository _jobRepository;
  final ImportExportRowResultRepository _rowResultRepository;
  final String Function() _idGenerator;
  final Future<void> Function(Duration) _delay;
  final int _maxItemRetries;

  Future<ExecuteWishlistExportResult> execute(
    WishlistExportPreview preview, {
    void Function(int current, int total, String description)? onProgress,
  }) async {
    final capability = _capabilityUseCase.execute();
    if (capability is WishlistExportNotSupported) {
      return ExecuteWishlistExportNotSupported(capability.reason);
    }

    final String token;
    final String username;
    try {
      final t = await _tokenStorage.loadToken();
      final u = await _tokenStorage.loadUsername();
      if (t == null || t.isEmpty || u == null || u.isEmpty) {
        return const ExecuteWishlistExportNoToken();
      }
      token = t;
      username = u;
    } catch (_) {
      return const ExecuteWishlistExportNoToken();
    }

    final jobId = _idGenerator();
    final now = DateTime.now();

    final job = ImportExportJob(
      id: jobId,
      jobType: ImportExportJobType.exportWishlistToDiscogs,
      source: 'Local wishlist',
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
          case EligibleWishlistExportRow():
            eligibleIndex++;
            onProgress?.call(
              eligibleIndex,
              eligibleTotal,
              '${row.artist} – ${row.title}',
            );
            try {
              await _addToWantlistWithRetry(username, row.releaseId, token);
              final item = await _wishlistRepository.getById(row.itemId);
              if (item != null) {
                await _wishlistRepository.update(
                  item.copyWith(
                    syncStatus: SyncStatus.synced,
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
                final failedItem = await _wishlistRepository.getById(
                  row.itemId,
                );
                if (failedItem != null) {
                  await _wishlistRepository.update(
                    failedItem.copyWith(
                      syncStatus: SyncStatus.failed,
                      updatedAt: DateTime.now(),
                    ),
                  );
                }
              } catch (_) {}
              await _rowResultRepository.addResult(
                jobId,
                FailedRow(
                  rowIndex: i,
                  safeErrorMessage: 'Could not export item',
                ),
              );
              failed++;
            }
          case AlreadySyncedWishlistExportRow():
            await _rowResultRepository.addResult(
              jobId,
              SkippedRow(rowIndex: i, reason: 'Already in Discogs wantlist'),
            );
            skipped++;
          case InvalidWishlistExportRow():
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

      return ExecuteWishlistExportCompleted(
        jobId: jobId,
        exported: exported,
        skipped: skipped,
        failed: failed,
      );
    } catch (_) {
      try {
        await _jobRepository.update(
          job.copyWith(
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Export could not be completed',
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {}
      return const ExecuteWishlistExportFailed('Export could not be completed');
    }
  }

  Future<void> _addToWantlistWithRetry(
    String username,
    int releaseId,
    String token,
  ) async {
    var attempts = 0;
    while (true) {
      try {
        await _apiClient.addToWantlist(username, releaseId, token);
        return;
      } on RateLimitedError {
        if (attempts >= _maxItemRetries) rethrow;
        attempts++;
        await _delay(_kRateLimitRetryDelay);
      }
    }
  }
}

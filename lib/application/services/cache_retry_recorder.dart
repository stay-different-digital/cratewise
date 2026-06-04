import 'package:uuid/uuid.dart';

import '../../domain/models/retry_action.dart';
import '../../domain/repositories/retry_action_repository.dart';
import '../../shared/errors/app_error.dart';

/// Records retry actions for failed release metadata refresh and thumbnail
/// cache operations.
///
/// All public methods swallow their own errors — failure to record a retry
/// action must never crash the main flow.
class CacheRetryRecorder {
  CacheRetryRecorder(this._repo);

  final RetryActionRepository _repo;

  /// Records a pending retry action for a failed metadata refresh, but only
  /// if [error] is retryable (network or server-side transient failure) and
  /// no pending action for this release already exists.
  Future<void> recordMetadataFailure(int releaseId, AppError error) async {
    if (!_isRetryable(error)) return;
    await _recordIfNoDuplicate(
      releaseId: releaseId,
      actionType: RetryActionType.refreshReleaseMetadata,
      safeErrorMessage: 'Release metadata could not be refreshed.',
    );
  }

  /// Records a pending retry action for a failed thumbnail cache attempt, if
  /// no pending action for this release already exists.
  Future<void> recordThumbnailFailure(int releaseId) async {
    await _recordIfNoDuplicate(
      releaseId: releaseId,
      actionType: RetryActionType.cacheThumbnail,
      safeErrorMessage: 'Cover image could not be cached.',
    );
  }

  bool _isRetryable(AppError error) =>
      error is NetworkError ||
      error is RateLimitedError ||
      error is DiscogsUnavailableError;

  Future<void> _recordIfNoDuplicate({
    required int releaseId,
    required RetryActionType actionType,
    required String safeErrorMessage,
  }) async {
    try {
      final entityId = '$releaseId';
      final pending = await _repo.getPending();
      final hasDuplicate = pending.any(
        (a) => a.entityId == entityId && a.actionType == actionType,
      );
      if (hasDuplicate) return;
      await _repo.add(
        RetryAction(
          id: const Uuid().v4(),
          actionType: actionType,
          entityType: RetryActionEntityType.cachedRelease,
          entityId: entityId,
          safeErrorMessage: safeErrorMessage,
          createdAt: DateTime.now(),
          attemptCount: 0,
          status: RetryActionStatus.pending,
        ),
      );
    } catch (_) {
      // failure to record must never crash the main flow
    }
  }
}

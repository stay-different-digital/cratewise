import 'package:http/http.dart' as http;

import '../services/thumbnail_cache_service.dart';
import '../../domain/models/retry_action.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/retry_action_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../shared/errors/app_error.dart';

// ---------------------------------------------------------------------------
// Result type
// ---------------------------------------------------------------------------

sealed class RetryThumbnailResult {
  const RetryThumbnailResult();
}

class RetryThumbnailSuccess extends RetryThumbnailResult {
  const RetryThumbnailSuccess();
}

/// No cover URL is stored in cached metadata — permanent condition, not retryable.
class RetryThumbnailNoUrl extends RetryThumbnailResult {
  const RetryThumbnailNoUrl();
}

/// Network or service unreachable — transient, safe to retry later.
class RetryThumbnailNetworkError extends RetryThumbnailResult {
  const RetryThumbnailNetworkError();
}

/// Non-retryable or unexpected failure.
class RetryThumbnailFailed extends RetryThumbnailResult {
  const RetryThumbnailFailed();
}

// ---------------------------------------------------------------------------
// Use case
// ---------------------------------------------------------------------------

class RetryThumbnailUseCase {
  RetryThumbnailUseCase({
    required this.retryRepo,
    required this.cacheRepo,
    ThumbnailRepository? thumbnailRepo,
    http.Client? httpClient,
  }) : _thumbnailRepo = thumbnailRepo ?? LocalThumbnailRepository(),
       _httpClient = httpClient ?? http.Client();

  final RetryActionRepository retryRepo;
  final CachedReleaseMetadataRepository cacheRepo;
  final ThumbnailRepository _thumbnailRepo;
  final http.Client _httpClient;

  Future<RetryThumbnailResult> execute(RetryAction action) async {
    final releaseId = int.tryParse(action.entityId);
    if (releaseId == null) {
      await _recordAttempt(action);
      return const RetryThumbnailFailed();
    }

    final metadata = await cacheRepo.getByReleaseId(releaseId);
    final coverUrl = metadata?.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      return const RetryThumbnailNoUrl();
    }

    final bytes = await downloadImage(_httpClient, coverUrl);
    if (bytes == null) {
      await _recordAttempt(action);
      return const RetryThumbnailNetworkError();
    }

    try {
      await _thumbnailRepo.save(releaseId, bytes);
      await retryRepo.remove(action.id);
      return const RetryThumbnailSuccess();
    } catch (e, st) {
      logSwallowed(e, st, 'RetryThumbnailUseCase');
      await _recordAttempt(action);
      return const RetryThumbnailFailed();
    }
  }

  Future<void> _recordAttempt(RetryAction action) async {
    try {
      await retryRepo.update(
        action.copyWith(
          attemptCount: action.attemptCount + 1,
          lastAttemptedAt: DateTime.now(),
          status: RetryActionStatus.failed,
        ),
      );
    } catch (e, st) {
      logSwallowed(e, st, 'RetryThumbnailUseCase');
      // update failure must never crash the caller
    }
  }
}

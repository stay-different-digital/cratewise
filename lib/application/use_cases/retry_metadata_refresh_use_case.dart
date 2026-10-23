import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/retry_action.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/retry_action_repository.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_release.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';

// ---------------------------------------------------------------------------
// Result type
// ---------------------------------------------------------------------------

sealed class RetryMetadataResult {
  const RetryMetadataResult();
}

class RetryMetadataSuccess extends RetryMetadataResult {
  const RetryMetadataSuccess();
}

/// No Discogs token is saved — user must reconnect their account.
class RetryMetadataNoToken extends RetryMetadataResult {
  const RetryMetadataNoToken();
}

/// Discogs rate limit hit — caller should wait before retrying.
class RetryMetadataRateLimited extends RetryMetadataResult {
  const RetryMetadataRateLimited();
}

/// Network or service unreachable — transient, safe to retry later.
class RetryMetadataNetworkError extends RetryMetadataResult {
  const RetryMetadataNetworkError();
}

/// Non-retryable or unexpected failure.
class RetryMetadataFailed extends RetryMetadataResult {
  const RetryMetadataFailed();
}

// ---------------------------------------------------------------------------
// Use case
// ---------------------------------------------------------------------------

class RetryMetadataRefreshUseCase {
  RetryMetadataRefreshUseCase({
    required this.retryRepo,
    required this.cacheRepo,
    TokenStorage? storage,
    DiscogsApiClient? apiClient,
  }) : _storage = storage ?? DiscogsTokenStorage(),
       _apiClient = apiClient ?? DiscogsApiClient.shared;

  final RetryActionRepository retryRepo;
  final CachedReleaseMetadataRepository cacheRepo;
  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;

  Future<RetryMetadataResult> execute(RetryAction action) async {
    final releaseId = int.tryParse(action.entityId);
    if (releaseId == null) {
      await _recordAttempt(action);
      return const RetryMetadataFailed();
    }

    final token = await _storage.loadToken();
    if (token == null) return const RetryMetadataNoToken();

    try {
      final dto = await _apiClient.fetchRelease(releaseId, token);
      await cacheRepo.save(_toMetadata(dto));
      await retryRepo.remove(action.id);
      return const RetryMetadataSuccess();
    } on NoTokenError {
      return const RetryMetadataNoToken();
    } on RateLimitedError {
      await _recordAttempt(action);
      return const RetryMetadataRateLimited();
    } on NetworkError {
      await _recordAttempt(action);
      return const RetryMetadataNetworkError();
    } on DiscogsUnavailableError {
      await _recordAttempt(action);
      return const RetryMetadataNetworkError();
    } on AppError {
      await _recordAttempt(action);
      return const RetryMetadataFailed();
    } catch (_) {
      await _recordAttempt(action);
      return const RetryMetadataFailed();
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
    } catch (_) {
      // update failure must never crash the caller
    }
  }

  CachedReleaseMetadata _toMetadata(DiscogsReleaseDto dto) {
    return CachedReleaseMetadata(
      discogsReleaseId: dto.id,
      artist: dto.artist,
      title: dto.title,
      label: dto.label.isEmpty ? null : dto.label,
      catno: dto.catno.isEmpty ? null : dto.catno,
      format: dto.format.isEmpty ? null : dto.format,
      country: dto.country.isEmpty ? null : dto.country,
      year: dto.year,
      genres: dto.genres,
      styles: dto.styles,
      tracklist: dto.tracklist
          .map(
            (t) => ReleaseTrack(
              position: t.position,
              title: t.title,
              duration: t.duration,
            ),
          )
          .toList(),
      notes: dto.notes,
      identifiers: dto.identifiers
          .map((i) => ReleaseIdentifier(type: i.type, value: i.value))
          .toList(),
      coverUrl: dto.coverUrl,
      fetchedAt: DateTime.now(),
      cacheSource: 'discogs_api',
      syncStatus: SyncStatus.localOnly,
    );
  }
}

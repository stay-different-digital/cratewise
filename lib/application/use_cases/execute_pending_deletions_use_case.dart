import '../../domain/models/pending_discogs_deletion.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../shared/errors/app_error.dart';

const _kRateLimitRetryDelay = Duration(seconds: 60);
const _kMaxItemRetries = 3;

sealed class ExecutePendingDeletionsResult {
  const ExecutePendingDeletionsResult();
}

class PendingDeletionsCompleted extends ExecutePendingDeletionsResult {
  const PendingDeletionsCompleted({
    required this.removed,
    required this.failed,
  });

  final int removed;
  final int failed;
}

class PendingDeletionsNoToken extends ExecutePendingDeletionsResult {
  const PendingDeletionsNoToken();
}

/// Propagates locally-recorded deletions (tombstones) to Discogs (US-72):
/// for each pending deletion it issues the matching DELETE, then clears the
/// tombstone on success. Rate limits are retried with back-off; other
/// failures leave the tombstone in place to retry next time.
class ExecutePendingDeletionsUseCase {
  ExecutePendingDeletionsUseCase({
    required this._tokenStorage,
    required this._apiClient,
    required this._deletionRepository,
    Future<void> Function(Duration)? delay,
    int? maxItemRetries,
  }) : _delay = delay ?? ((d) => Future.delayed(d)),
       _maxItemRetries = maxItemRetries ?? _kMaxItemRetries;

  final TokenStorage _tokenStorage;
  final DiscogsApiClient _apiClient;
  final PendingDiscogsDeletionRepository _deletionRepository;
  final Future<void> Function(Duration) _delay;
  final int _maxItemRetries;

  Future<ExecutePendingDeletionsResult> execute({
    void Function(int current, int total, String description)? onProgress,
  }) async {
    final String token;
    final String username;
    try {
      final t = await _tokenStorage.loadToken();
      final u = await _tokenStorage.loadUsername();
      if (t == null || t.isEmpty || u == null || u.isEmpty) {
        return const PendingDeletionsNoToken();
      }
      token = t;
      username = u;
    } catch (e, st) {
      logSwallowed(e, st, 'ExecutePendingDeletionsUseCase');
      return const PendingDeletionsNoToken();
    }

    final pending = [
      ...await _deletionRepository.getByType(DeletionEntityType.collection),
      ...await _deletionRepository.getByType(DeletionEntityType.wishlist),
    ];

    var removed = 0;
    var failed = 0;
    for (var i = 0; i < pending.length; i++) {
      final deletion = pending[i];
      onProgress?.call(
        i + 1,
        pending.length,
        '${deletion.artist} – ${deletion.title}',
      );
      try {
        await _deleteWithRetry(deletion, username, token);
        await _deletionRepository.remove(deletion.id);
        removed++;
      } catch (e) {
        if (e is AppError) await _tokenStorage.clearIfRevoked(e);
        failed++;
      }
    }

    return PendingDeletionsCompleted(removed: removed, failed: failed);
  }

  Future<void> _deleteWithRetry(
    PendingDiscogsDeletion deletion,
    String username,
    String token,
  ) async {
    var attempts = 0;
    while (true) {
      try {
        await _delete(deletion, username, token);
        return;
      } on UnexpectedApiError catch (e) {
        // 404: already gone on Discogs — the deletion's goal is met.
        if (e.statusCode == 404) return;
        rethrow;
      } on RateLimitedError {
        if (attempts >= _maxItemRetries) rethrow;
        attempts++;
        await _delay(_kRateLimitRetryDelay);
      }
    }
  }

  Future<void> _delete(
    PendingDiscogsDeletion deletion,
    String username,
    String token,
  ) async {
    switch (deletion.entityType) {
      case DeletionEntityType.collection:
        final instanceId =
            deletion.discogsInstanceId ??
            await _resolveInstanceId(deletion, username, token);
        if (instanceId == null) return; // not in the Discogs collection
        return _apiClient.removeFromCollection(
          username,
          deletion.discogsReleaseId,
          instanceId,
          token,
        );
      case DeletionEntityType.wishlist:
        return _apiClient.removeFromWantlist(
          username,
          deletion.discogsReleaseId,
          token,
        );
    }
  }

  /// Looks up the instance id for tombstones recorded without one (US-124).
  /// Returns null when Discogs has no copy (nothing left to delete). With
  /// several copies we can't tell which one was meant, so the tombstone
  /// stays and is reported as failed.
  Future<int?> _resolveInstanceId(
    PendingDiscogsDeletion deletion,
    String username,
    String token,
  ) async {
    final ids = await _apiClient.fetchCollectionInstanceIds(
      username,
      deletion.discogsReleaseId,
      token,
    );
    if (ids.length > 1) throw const UnexpectedApiError(0);
    return ids.isEmpty ? null : ids.single;
  }
}

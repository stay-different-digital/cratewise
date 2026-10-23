import '../../domain/models/collection_item.dart';
import '../../domain/models/retry_action.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/retry_action_repository.dart';
import '../../shared/errors/app_error.dart';

// ---------------------------------------------------------------------------
// Result type
// ---------------------------------------------------------------------------

sealed class RetryAddCollectionItemResult {
  const RetryAddCollectionItemResult();
}

class RetryAddCollectionItemSuccess extends RetryAddCollectionItemResult {
  const RetryAddCollectionItemSuccess();
}

/// Item was already in the collection — desired state achieved; action removed.
class RetryAddCollectionItemAlreadyExists extends RetryAddCollectionItemResult {
  const RetryAddCollectionItemAlreadyExists();
}

/// Payload could not be decoded; action is marked failed.
class RetryAddCollectionItemInvalidPayload
    extends RetryAddCollectionItemResult {
  const RetryAddCollectionItemInvalidPayload();
}

/// Storage is still failing; attempt count incremented.
class RetryAddCollectionItemStorageError extends RetryAddCollectionItemResult {
  const RetryAddCollectionItemStorageError();
}

// ---------------------------------------------------------------------------
// Use case
// ---------------------------------------------------------------------------

class RetryAddCollectionItemUseCase {
  RetryAddCollectionItemUseCase({
    required this.retryRepo,
    required this.collectionRepo,
  });

  final RetryActionRepository retryRepo;
  final CollectionRepository collectionRepo;

  Future<RetryAddCollectionItemResult> execute(RetryAction action) async {
    final encoded = action.payload;
    if (encoded == null) {
      await _recordAttempt(action);
      return const RetryAddCollectionItemInvalidPayload();
    }

    final item = CollectionItem.tryFromJson(encoded);
    if (item == null) {
      await _recordAttempt(action);
      return const RetryAddCollectionItemInvalidPayload();
    }

    try {
      if (await collectionRepo.containsRelease(item.discogsReleaseId)) {
        await retryRepo.remove(action.id);
        return const RetryAddCollectionItemAlreadyExists();
      }
      await collectionRepo.add(item);
      await retryRepo.remove(action.id);
      return const RetryAddCollectionItemSuccess();
    } catch (e, st) {
      logSwallowed(e, st, 'RetryAddCollectionItemUseCase');
      await _recordAttempt(action);
      return const RetryAddCollectionItemStorageError();
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
      logSwallowed(e, st, 'RetryAddCollectionItemUseCase');
      // update failure must never crash the caller
    }
  }
}

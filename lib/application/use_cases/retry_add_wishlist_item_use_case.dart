import '../../domain/models/retry_action.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/retry_action_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';

// ---------------------------------------------------------------------------
// Result type
// ---------------------------------------------------------------------------

sealed class RetryAddWishlistItemResult {
  const RetryAddWishlistItemResult();
}

class RetryAddWishlistItemSuccess extends RetryAddWishlistItemResult {
  const RetryAddWishlistItemSuccess();
}

/// Item was already in the wishlist — desired state achieved; action removed.
class RetryAddWishlistItemAlreadyExists extends RetryAddWishlistItemResult {
  const RetryAddWishlistItemAlreadyExists();
}

/// Payload could not be decoded; action is marked failed.
class RetryAddWishlistItemInvalidPayload extends RetryAddWishlistItemResult {
  const RetryAddWishlistItemInvalidPayload();
}

/// Storage is still failing; attempt count incremented.
class RetryAddWishlistItemStorageError extends RetryAddWishlistItemResult {
  const RetryAddWishlistItemStorageError();
}

// ---------------------------------------------------------------------------
// Use case
// ---------------------------------------------------------------------------

class RetryAddWishlistItemUseCase {
  RetryAddWishlistItemUseCase({
    required this.retryRepo,
    required this.wishlistRepo,
  });

  final RetryActionRepository retryRepo;
  final WishlistRepository wishlistRepo;

  Future<RetryAddWishlistItemResult> execute(RetryAction action) async {
    final encoded = action.payload;
    if (encoded == null) {
      await _recordAttempt(action);
      return const RetryAddWishlistItemInvalidPayload();
    }

    final item = WishlistItem.tryFromJson(encoded);
    if (item == null) {
      await _recordAttempt(action);
      return const RetryAddWishlistItemInvalidPayload();
    }

    try {
      if (await wishlistRepo.containsRelease(item.discogsReleaseId)) {
        await retryRepo.remove(action.id);
        return const RetryAddWishlistItemAlreadyExists();
      }
      await wishlistRepo.add(item);
      await retryRepo.remove(action.id);
      return const RetryAddWishlistItemSuccess();
    } catch (_) {
      await _recordAttempt(action);
      return const RetryAddWishlistItemStorageError();
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
}

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/models/release_detail.dart';
import '../../domain/models/retry_action.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/retry_action_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';

sealed class AddToWishlistResult {
  const AddToWishlistResult();
}

class AddToWishlistSuccess extends AddToWishlistResult {
  AddToWishlistSuccess(this.item);
  final WishlistItem item;
}

class AddToWishlistDuplicate extends AddToWishlistResult {
  const AddToWishlistDuplicate();
}

/// The repository write failed; a retry action has been queued.
class AddToWishlistStorageError extends AddToWishlistResult {
  const AddToWishlistStorageError();
}

class AddToWishlistUseCase {
  AddToWishlistUseCase(
    this._repository, {
    String Function()? idGenerator,
    RetryActionRepository? retryRepository,
  }) : _idGenerator = idGenerator ?? _newUuid,
       _retryRepository = retryRepository;

  static String _newUuid() => const Uuid().v4();

  final WishlistRepository _repository;
  final String Function() _idGenerator;
  final RetryActionRepository? _retryRepository;

  Future<AddToWishlistResult> execute(ReleaseDetail release) async {
    if (await _repository.containsRelease(release.id)) {
      return const AddToWishlistDuplicate();
    }
    final now = DateTime.now();
    final item = WishlistItem(
      id: _idGenerator(),
      discogsReleaseId: release.id,
      artist: release.artist,
      title: release.title,
      label: release.label.isEmpty ? null : release.label,
      catno: release.catno.isEmpty ? null : release.catno,
      format: release.format.isEmpty ? null : release.format,
      country: release.country.isEmpty ? null : release.country,
      year: release.year,
      coverUrl: release.coverUrl,
      priority: WishlistPriority.medium,
      syncStatus: SyncStatus.localOnly,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _repository.add(item);
      return AddToWishlistSuccess(item);
    } catch (_) {
      await _recordRetry(item);
      return const AddToWishlistStorageError();
    }
  }

  Future<void> _recordRetry(WishlistItem item) async {
    if (_retryRepository == null) return;
    try {
      final entityId = '${item.discogsReleaseId}';
      final pending = await _retryRepository.getPending();
      final hasDuplicate = pending.any(
        (a) =>
            a.entityId == entityId &&
            a.actionType == RetryActionType.addWishlistItem,
      );
      if (hasDuplicate) return;
      await _retryRepository.add(
        RetryAction(
          id: const Uuid().v4(),
          actionType: RetryActionType.addWishlistItem,
          entityType: RetryActionEntityType.wishlistItem,
          entityId: entityId,
          payload: jsonEncode(item.toJson()),
          safeErrorMessage: "Could not save '${item.title}' to wishlist.",
          createdAt: DateTime.now(),
          attemptCount: 0,
          status: RetryActionStatus.pending,
        ),
      );
    } catch (_) {
      // recording failure must never crash the main flow
    }
  }
}

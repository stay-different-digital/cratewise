enum RetryActionType {
  addCollectionItem,
  updateCollectionItem,
  removeCollectionItem,
  addWishlistItem,
  updateWishlistItem,
  removeWishlistItem,
  refreshReleaseMetadata,
  cacheThumbnail,
}

enum RetryActionEntityType { collectionItem, wishlistItem, cachedRelease }

enum RetryActionStatus { pending, failed, abandoned }

class RetryAction {
  RetryAction({
    required this.id,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.safeErrorMessage,
    required this.createdAt,
    required this.attemptCount,
    required this.status,
    this.lastAttemptedAt,
    this.payload,
  });

  final String id;
  final RetryActionType actionType;
  final RetryActionEntityType entityType;
  final String entityId;

  /// A safe, user-facing description of why the action failed.
  /// Must never contain tokens, secrets, or raw API headers.
  final String safeErrorMessage;

  /// JSON-encoded item payload used by write-retry use cases to reconstruct
  /// the item that failed to be persisted.  Null for non-write actions.
  final String? payload;

  final DateTime createdAt;
  final DateTime? lastAttemptedAt;
  final int attemptCount;
  final RetryActionStatus status;

  RetryAction copyWith({
    String? id,
    RetryActionType? actionType,
    RetryActionEntityType? entityType,
    String? entityId,
    String? safeErrorMessage,
    String? payload,
    DateTime? createdAt,
    DateTime? lastAttemptedAt,
    int? attemptCount,
    RetryActionStatus? status,
    bool clearLastAttemptedAt = false,
  }) {
    return RetryAction(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      safeErrorMessage: safeErrorMessage ?? this.safeErrorMessage,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptedAt: clearLastAttemptedAt
          ? null
          : (lastAttemptedAt ?? this.lastAttemptedAt),
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
    );
  }
}

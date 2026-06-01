enum SyncStatus {
  /// Data exists only locally; sync has never been attempted.
  localOnly,

  /// Last sync completed successfully; local and remote are in agreement.
  synced,

  /// A sync is queued or currently in progress.
  pending,

  /// The most recent sync attempt failed; data may be stale.
  failed,

  /// Local and remote versions differ and require resolution.
  conflict,

  /// Device is offline; sync has been deferred.
  offline,
}

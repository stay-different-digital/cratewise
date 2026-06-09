import 'package:flutter/material.dart';

import '../../application/use_cases/retry_add_collection_item_use_case.dart';
import '../../application/use_cases/retry_add_wishlist_item_use_case.dart';
import '../../application/use_cases/retry_metadata_refresh_use_case.dart';
import '../../application/use_cases/retry_thumbnail_use_case.dart';
import '../../domain/models/retry_action.dart';
import '../../domain/repositories/retry_action_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_retry_action_repository.dart';
import '../../shared/utils/date_format_utils.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _FailedActionsState {
  const _FailedActionsState();
}

class _Loading extends _FailedActionsState {
  const _Loading();
}

class _Loaded extends _FailedActionsState {
  const _Loaded(this.actions);
  final List<RetryAction> actions;
}

class _LoadError extends _FailedActionsState {
  const _LoadError();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class FailedActionsScreen extends StatefulWidget {
  const FailedActionsScreen({
    super.key,
    this.repository,
    this.retryUseCase,
    this.thumbnailUseCase,
    this.addCollectionUseCase,
    this.addWishlistUseCase,
  });

  final RetryActionRepository? repository;
  final RetryMetadataRefreshUseCase? retryUseCase;
  final RetryThumbnailUseCase? thumbnailUseCase;
  final RetryAddCollectionItemUseCase? addCollectionUseCase;
  final RetryAddWishlistItemUseCase? addWishlistUseCase;

  @override
  State<FailedActionsScreen> createState() => _FailedActionsScreenState();
}

class _FailedActionsScreenState extends State<FailedActionsScreen> {
  late final RetryActionRepository _repository;
  AppDatabase? _ownedDb;
  _FailedActionsState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repository = widget.repository!;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _repository = LocalRetryActionRepository(db);
    }
    _load();
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all failed actions?'),
        content: const Text(
          'All failed action entries will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            key: const Key('clear-all-confirm-button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _repository.deleteAll();
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final all = await _repository.getAll();
      final visible = all
          .where((a) => a.status != RetryActionStatus.abandoned)
          .toList();
      if (!mounted) return;
      setState(() => _state = _Loaded(visible));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _LoadError());
    }
  }

  @override
  void dispose() {
    _ownedDb?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasEntries =
        _state is _Loaded && (_state as _Loaded).actions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Failed Actions'),
        actions: [
          if (hasEntries)
            PopupMenuButton<String>(
              key: const Key('failed-actions-overflow-menu'),
              onSelected: (value) {
                if (value == 'clear-all') _confirmClearAll();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'clear-all', child: Text('Clear All')),
              ],
            ),
        ],
      ),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Loaded(:final actions) when actions.isEmpty => const _EmptyState(),
        _Loaded(:final actions) => _ActionList(
          actions: actions,
          retryUseCase: widget.retryUseCase,
          thumbnailUseCase: widget.thumbnailUseCase,
          addCollectionUseCase: widget.addCollectionUseCase,
          addWishlistUseCase: widget.addWishlistUseCase,
          onRetried: _load,
        ),
        _LoadError() => _ErrorState(onRetry: _load),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _ActionList extends StatefulWidget {
  const _ActionList({
    required this.actions,
    required this.onRetried,
    this.retryUseCase,
    this.thumbnailUseCase,
    this.addCollectionUseCase,
    this.addWishlistUseCase,
  });

  final List<RetryAction> actions;
  final RetryMetadataRefreshUseCase? retryUseCase;
  final RetryThumbnailUseCase? thumbnailUseCase;
  final RetryAddCollectionItemUseCase? addCollectionUseCase;
  final RetryAddWishlistItemUseCase? addWishlistUseCase;
  final VoidCallback onRetried;

  @override
  State<_ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<_ActionList> {
  bool _retryingAll = false;
  int _retryAllCurrent = 0;
  int _retryAllTotal = 0;

  bool _isRetryable(RetryAction action) =>
      (widget.retryUseCase != null &&
          action.actionType == RetryActionType.refreshReleaseMetadata) ||
      (widget.thumbnailUseCase != null &&
          action.actionType == RetryActionType.cacheThumbnail) ||
      (widget.addCollectionUseCase != null &&
          action.actionType == RetryActionType.addCollectionItem) ||
      (widget.addWishlistUseCase != null &&
          action.actionType == RetryActionType.addWishlistItem);

  Future<void> _doRetryAll() async {
    final retryable = widget.actions.where(_isRetryable).toList();
    if (retryable.isEmpty) return;

    setState(() {
      _retryingAll = true;
      _retryAllCurrent = 0;
      _retryAllTotal = retryable.length;
    });

    for (final action in retryable) {
      if (!mounted) return;
      setState(() => _retryAllCurrent++);
      await _executeOne(action);
    }

    if (!mounted) return;
    setState(() => _retryingAll = false);
    widget.onRetried();
  }

  Future<void> _executeOne(RetryAction action) async {
    switch (action.actionType) {
      case RetryActionType.refreshReleaseMetadata:
        await widget.retryUseCase?.execute(action);
      case RetryActionType.cacheThumbnail:
        await widget.thumbnailUseCase?.execute(action);
      case RetryActionType.addCollectionItem:
        await widget.addCollectionUseCase?.execute(action);
      case RetryActionType.addWishlistItem:
        await widget.addWishlistUseCase?.execute(action);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRetryable = widget.actions.any(_isRetryable);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          if (hasRetryable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _retryingAll
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            key: const Key('retry-all-progress'),
                            'Retrying $_retryAllCurrent of $_retryAllTotal…',
                          ),
                        ],
                      )
                    : FilledButton.tonal(
                        key: const Key('retry-all-button'),
                        onPressed: _doRetryAll,
                        child: const Text('Retry All'),
                      ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, hasRetryable ? 8 : 16, 16, 16),
              itemCount: widget.actions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ActionCard(
                action: widget.actions[index],
                retryUseCase: widget.retryUseCase,
                thumbnailUseCase: widget.thumbnailUseCase,
                addCollectionUseCase: widget.addCollectionUseCase,
                addWishlistUseCase: widget.addWishlistUseCase,
                onRetried: widget.onRetried,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.action,
    required this.onRetried,
    this.retryUseCase,
    this.thumbnailUseCase,
    this.addCollectionUseCase,
    this.addWishlistUseCase,
  });

  final RetryAction action;
  final RetryMetadataRefreshUseCase? retryUseCase;
  final RetryThumbnailUseCase? thumbnailUseCase;
  final RetryAddCollectionItemUseCase? addCollectionUseCase;
  final RetryAddWishlistItemUseCase? addWishlistUseCase;
  final VoidCallback onRetried;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _retrying = false;

  static String _friendlyType(RetryActionType type) => switch (type) {
    RetryActionType.refreshReleaseMetadata => 'Refresh release info',
    RetryActionType.cacheThumbnail => 'Cache cover image',
    RetryActionType.addCollectionItem => 'Add to collection',
    RetryActionType.updateCollectionItem => 'Update collection item',
    RetryActionType.removeCollectionItem => 'Remove from collection',
    RetryActionType.addWishlistItem => 'Add to wishlist',
    RetryActionType.updateWishlistItem => 'Update wishlist item',
    RetryActionType.removeWishlistItem => 'Remove from wishlist',
  };

  static String _friendlyStatus(RetryActionStatus status) => switch (status) {
    RetryActionStatus.pending => 'Queued',
    RetryActionStatus.failed => 'Failed',
    RetryActionStatus.abandoned => 'Abandoned',
  };

  static String _metadataSnackbarMessage(RetryMetadataResult result) =>
      switch (result) {
        RetryMetadataSuccess() => 'Release info updated.',
        RetryMetadataNoToken() => 'Connect your Discogs account to retry.',
        RetryMetadataRateLimited() => 'Rate limited — try again shortly.',
        RetryMetadataNetworkError() => 'Network unavailable — try again later.',
        RetryMetadataFailed() => 'Refresh failed — try again later.',
      };

  static String _thumbnailSnackbarMessage(
    RetryThumbnailResult result,
  ) => switch (result) {
    RetryThumbnailSuccess() => 'Cover image cached.',
    RetryThumbnailNoUrl() => 'No cover image available for this release.',
    RetryThumbnailNetworkError() => 'Network unavailable — try again later.',
    RetryThumbnailFailed() => 'Failed to cache cover image — try again later.',
  };

  static String _addCollectionSnackbarMessage(
    RetryAddCollectionItemResult result,
  ) => switch (result) {
    RetryAddCollectionItemSuccess() => 'Item added to collection.',
    RetryAddCollectionItemAlreadyExists() => 'Already in your collection.',
    RetryAddCollectionItemInvalidPayload() =>
      'Retry failed — item data is invalid.',
    RetryAddCollectionItemStorageError() =>
      'Could not save to collection — try again later.',
  };

  static String _addWishlistSnackbarMessage(
    RetryAddWishlistItemResult result,
  ) => switch (result) {
    RetryAddWishlistItemSuccess() => 'Item added to wishlist.',
    RetryAddWishlistItemAlreadyExists() => 'Already in your wishlist.',
    RetryAddWishlistItemInvalidPayload() =>
      'Retry failed — item data is invalid.',
    RetryAddWishlistItemStorageError() =>
      'Could not save to wishlist — try again later.',
  };

  Future<void> _doRetry() async {
    setState(() => _retrying = true);

    final String message;
    switch (widget.action.actionType) {
      case RetryActionType.refreshReleaseMetadata:
        final result = await widget.retryUseCase!.execute(widget.action);
        message = _metadataSnackbarMessage(result);
      case RetryActionType.cacheThumbnail:
        final result = await widget.thumbnailUseCase!.execute(widget.action);
        message = _thumbnailSnackbarMessage(result);
      case RetryActionType.addCollectionItem:
        final result = await widget.addCollectionUseCase!.execute(
          widget.action,
        );
        message = _addCollectionSnackbarMessage(result);
      case RetryActionType.addWishlistItem:
        final result = await widget.addWishlistUseCase!.execute(widget.action);
        message = _addWishlistSnackbarMessage(result);
      default:
        message = 'No retry available for this action type.';
    }

    if (!mounted) return;
    setState(() => _retrying = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    widget.onRetried();
  }

  bool get _showRetryButton =>
      (widget.retryUseCase != null &&
          widget.action.actionType == RetryActionType.refreshReleaseMetadata) ||
      (widget.thumbnailUseCase != null &&
          widget.action.actionType == RetryActionType.cacheThumbnail) ||
      (widget.addCollectionUseCase != null &&
          widget.action.actionType == RetryActionType.addCollectionItem) ||
      (widget.addWishlistUseCase != null &&
          widget.action.actionType == RetryActionType.addWishlistItem);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isPending = widget.action.status == RetryActionStatus.pending;
    final statusColor = isPending
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;
    final statusBgColor = isPending
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.errorContainer;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _friendlyType(widget.action.actionType),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _friendlyStatus(widget.action.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.action.safeErrorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Attempts', value: '${widget.action.attemptCount}'),
            if (widget.action.lastAttemptedAt != null)
              _InfoRow(
                label: 'Last tried',
                value: formatDateTime(widget.action.lastAttemptedAt!, locale),
              ),
            _InfoRow(
              label: 'Queued',
              value: formatDateTime(widget.action.createdAt, locale),
            ),
            if (_showRetryButton) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _retrying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _doRetry,
                        child: const Text('Retry'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('No failed actions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Everything is up to date.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load failed actions from device storage.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

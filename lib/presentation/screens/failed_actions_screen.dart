import 'package:flutter/material.dart';

import '../../application/use_cases/retry_metadata_refresh_use_case.dart';
import '../../application/use_cases/retry_thumbnail_use_case.dart';
import '../../domain/models/retry_action.dart';
import '../../domain/repositories/retry_action_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_retry_action_repository.dart';

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
  });

  final RetryActionRepository? repository;
  final RetryMetadataRefreshUseCase? retryUseCase;
  final RetryThumbnailUseCase? thumbnailUseCase;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Failed Actions')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Loaded(:final actions) when actions.isEmpty => const _EmptyState(),
        _Loaded(:final actions) => _ActionList(
          actions: actions,
          retryUseCase: widget.retryUseCase,
          thumbnailUseCase: widget.thumbnailUseCase,
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

class _ActionList extends StatelessWidget {
  const _ActionList({
    required this.actions,
    required this.onRetried,
    this.retryUseCase,
    this.thumbnailUseCase,
  });

  final List<RetryAction> actions;
  final RetryMetadataRefreshUseCase? retryUseCase;
  final RetryThumbnailUseCase? thumbnailUseCase;
  final VoidCallback onRetried;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: actions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _ActionCard(
        action: actions[index],
        retryUseCase: retryUseCase,
        thumbnailUseCase: thumbnailUseCase,
        onRetried: onRetried,
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
  });

  final RetryAction action;
  final RetryMetadataRefreshUseCase? retryUseCase;
  final RetryThumbnailUseCase? thumbnailUseCase;
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

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

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

  Future<void> _doRetry() async {
    setState(() => _retrying = true);

    final String message;
    if (widget.action.actionType == RetryActionType.refreshReleaseMetadata) {
      final result = await widget.retryUseCase!.execute(widget.action);
      message = _metadataSnackbarMessage(result);
    } else {
      // cacheThumbnail — thumbnailUseCase is non-null (guarded by _showRetryButton)
      final result = await widget.thumbnailUseCase!.execute(widget.action);
      message = _thumbnailSnackbarMessage(result);
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
          widget.action.actionType == RetryActionType.cacheThumbnail);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                value: _formatDate(widget.action.lastAttemptedAt!),
              ),
            _InfoRow(
              label: 'Queued',
              value: _formatDate(widget.action.createdAt),
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

import 'package:flutter/material.dart';

import '../../application/use_cases/execute_pending_deletions_use_case.dart';
import '../../domain/models/pending_discogs_deletion.dart';
import '../../app/app_repositories.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _State {
  const _State();
}

class _Loading extends _State {
  const _Loading();
}

class _Loaded extends _State {
  const _Loaded(this.deletions);
  final List<PendingDiscogsDeletion> deletions;
}

class _Removing extends _State {
  const _Removing({this.current = 0, this.total = 0, this.currentItem = ''});
  final int current;
  final int total;
  final String currentItem;
}

class _Done extends _State {
  const _Done(this.result);
  final PendingDeletionsCompleted result;
}

class _NoToken extends _State {
  const _NoToken();
}

class _Error extends _State {
  const _Error();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PendingDeletionsScreen extends StatefulWidget {
  const PendingDeletionsScreen({
    super.key,
    this.deletionRepository,
    this.executeUseCase,
  });

  final PendingDiscogsDeletionRepository? deletionRepository;
  final ExecutePendingDeletionsUseCase? executeUseCase;

  @override
  State<PendingDeletionsScreen> createState() => _PendingDeletionsScreenState();
}

class _PendingDeletionsScreenState extends State<PendingDeletionsScreen> {
  late final PendingDiscogsDeletionRepository _repository;
  late final ExecutePendingDeletionsUseCase _executeUseCase;
  _State _state = const _Loading();

  @override
  void initState() {
    super.initState();
    _repository =
        widget.deletionRepository ??
        AppRepositoriesScope.of(context).pendingDeletion;
    _executeUseCase =
        widget.executeUseCase ??
        ExecutePendingDeletionsUseCase(
          tokenStorage: DiscogsTokenStorage(),
          apiClient: DiscogsApiClient(),
          deletionRepository: _repository,
        );
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final deletions = [
        ...await _repository.getByType(DeletionEntityType.collection),
        ...await _repository.getByType(DeletionEntityType.wishlist),
      ];
      if (!mounted) return;
      setState(() => _state = _Loaded(deletions));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _Error());
    }
  }

  Future<void> _execute() async {
    setState(() => _state = const _Removing());
    final result = await _executeUseCase.execute(
      onProgress: (current, total, item) {
        if (!mounted) return;
        setState(
          () => _state = _Removing(
            current: current,
            total: total,
            currentItem: item,
          ),
        );
      },
    );
    if (!mounted) return;
    switch (result) {
      case PendingDeletionsCompleted():
        setState(() => _state = _Done(result));
      case PendingDeletionsNoToken():
        setState(() => _state = const _NoToken());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Removals to sync')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Loaded(:final deletions) when deletions.isEmpty => const _EmptyBody(),
        _Loaded(:final deletions) => _ListBody(
          deletions: deletions,
          onConfirm: _execute,
        ),
        _Removing(:final current, :final total, :final currentItem) =>
          _RemovingBody(
            current: current,
            total: total,
            currentItem: currentItem,
          ),
        _Done(:final result) => _DoneBody(
          result: result,
          onDone: () => Navigator.of(context).pop(),
        ),
        _NoToken() => const _NoTokenBody(),
        _Error() => _ErrorBody(onRetry: _load),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bodies
// ---------------------------------------------------------------------------

class _ListBody extends StatelessWidget {
  const _ListBody({required this.deletions, required this.onConfirm});

  final List<PendingDiscogsDeletion> deletions;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'These records were removed locally and will be removed from your '
            'Discogs ${_listsLabel()} when you confirm.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: deletions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final d = deletions[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      d.entityType == DeletionEntityType.collection
                          ? Icons.library_music_outlined
                          : Icons.bookmark_remove_outlined,
                    ),
                    title: Text(d.title),
                    subtitle: Text(
                      '${d.artist} · '
                      '${d.entityType == DeletionEntityType.collection ? 'Collection' : 'Wantlist'}',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const Key('confirm-removals-button'),
              onPressed: onConfirm,
              icon: const Icon(Icons.cloud_off_outlined),
              label: Text('Remove ${deletions.length} from Discogs'),
            ),
          ),
        ),
      ],
    );
  }

  String _listsLabel() {
    final hasCollection = deletions.any(
      (d) => d.entityType == DeletionEntityType.collection,
    );
    final hasWishlist = deletions.any(
      (d) => d.entityType == DeletionEntityType.wishlist,
    );
    if (hasCollection && hasWishlist) return 'collection and wantlist';
    if (hasWishlist) return 'wantlist';
    return 'collection';
  }
}

class _RemovingBody extends StatelessWidget {
  const _RemovingBody({
    required this.current,
    required this.total,
    required this.currentItem,
  });

  final int current;
  final int total;
  final String currentItem;

  @override
  Widget build(BuildContext context) {
    final hasProgress = total > 0;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasProgress)
              LinearProgressIndicator(value: current / total)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              hasProgress
                  ? 'Removing item $current of $total…'
                  : 'Removing from Discogs…',
              style: theme.textTheme.bodyMedium,
            ),
            if (hasProgress && currentItem.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                currentItem,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoneBody extends StatelessWidget {
  const _DoneBody({required this.result, required this.onDone});

  final PendingDeletionsCompleted result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Removals complete', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Removed from Discogs: ${result.removed}'),
            if (result.failed > 0) Text('Could not remove: ${result.failed}'),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('removals-done-button'),
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

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
              Icons.done_all_outlined,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('Nothing to remove', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Records you delete and choose to also remove from Discogs '
              'will appear here.',
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

class _NoTokenBody extends StatelessWidget {
  const _NoTokenBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Connect your Discogs account in Settings to sync removals.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load pending removals.'),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

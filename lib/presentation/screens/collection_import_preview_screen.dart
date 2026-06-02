import 'package:flutter/material.dart';

import '../../application/use_cases/build_collection_import_preview_use_case.dart';
import '../../application/use_cases/fetch_collection_import_preview_use_case.dart';
import '../../domain/models/collection_import_preview.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';

const _kWideBreakpoint = 700.0;

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _PreviewState {
  const _PreviewState();
}

class _Loading extends _PreviewState {
  const _Loading();
}

class _Loaded extends _PreviewState {
  const _Loaded(this.preview);
  final CollectionImportPreview preview;
}

class _NoToken extends _PreviewState {
  const _NoToken();
}

class _RateLimited extends _PreviewState {
  const _RateLimited();
}

class _NetworkError extends _PreviewState {
  const _NetworkError();
}

class _Error extends _PreviewState {
  const _Error();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CollectionImportPreviewScreen extends StatefulWidget {
  const CollectionImportPreviewScreen({super.key, this.useCase});

  final FetchCollectionImportPreviewUseCase? useCase;

  @override
  State<CollectionImportPreviewScreen> createState() =>
      _CollectionImportPreviewScreenState();
}

class _CollectionImportPreviewScreenState
    extends State<CollectionImportPreviewScreen> {
  late final FetchCollectionImportPreviewUseCase _useCase;
  AppDatabase? _ownedDb;
  _PreviewState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    if (widget.useCase != null) {
      _useCase = widget.useCase!;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _useCase = FetchCollectionImportPreviewUseCase(
        previewBuilder: BuildCollectionImportPreviewUseCase(
          LocalCollectionRepository(db),
        ),
      );
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    final result = await _useCase.execute();
    if (!mounted) return;
    setState(() {
      _state = switch (result) {
        FetchPreviewReady(:final preview) => _Loaded(preview),
        FetchPreviewNoToken() => const _NoToken(),
        FetchPreviewRateLimited() => const _RateLimited(),
        FetchPreviewNetworkError() => const _NetworkError(),
        FetchPreviewError() => const _Error(),
      };
    });
  }

  @override
  void dispose() {
    _ownedDb?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Discogs')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Loaded(:final preview) => _PreviewBody(
            preview: preview,
            onRetry: _load,
          ),
        _NoToken() => const _NoTokenState(),
        _RateLimited() => _RetriableErrorState(
            message:
                'Discogs is rate-limiting requests. Please wait a moment and try again.',
            onRetry: _load,
          ),
        _NetworkError() => _RetriableErrorState(
            message:
                'No internet connection. Check your connection and try again.',
            onRetry: _load,
          ),
        _Error() => _RetriableErrorState(
            message:
                'Something went wrong. Check your connection and try again.',
            onRetry: _load,
          ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Preview body
// ---------------------------------------------------------------------------

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.preview, required this.onRetry});

  final CollectionImportPreview preview;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kWideBreakpoint;
        final hasWarnings =
            preview.duplicateCount > 0 || preview.invalidCount > 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _SummaryCard(preview: preview)),
                          if (hasWarnings) ...[
                            const SizedBox(width: 16),
                            Expanded(child: _WarningCard(preview: preview)),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          _SummaryCard(preview: preview),
                          if (hasWarnings) ...[
                            const SizedBox(height: 12),
                            _WarningCard(preview: preview),
                          ],
                        ],
                      ),
              ),
            ),
            _ConfirmBar(newCount: preview.newCount),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.preview});

  final CollectionImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collection preview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _CountRow(label: 'Total found', value: '${preview.totalCount}'),
            const SizedBox(height: 10),
            _CountRow(
              label: 'New items',
              value: '${preview.newCount}',
              color: preview.newCount > 0 ? theme.colorScheme.primary : null,
            ),
            const SizedBox(height: 10),
            _CountRow(
              label: 'Already in collection',
              value: '${preview.duplicateCount}',
            ),
            const SizedBox(height: 10),
            _CountRow(
              label: 'Cannot import',
              value: '${preview.invalidCount}',
              color: preview.invalidCount > 0 ? theme.colorScheme.error : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Warning card
// ---------------------------------------------------------------------------

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.preview});

  final CollectionImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = <String>[];
    if (preview.duplicateCount > 0) {
      final n = preview.duplicateCount;
      messages.add(
        '$n ${n == 1 ? 'item is' : 'items are'} already in your collection and will be skipped.',
      );
    }
    if (preview.invalidCount > 0) {
      final n = preview.invalidCount;
      messages.add(
        '$n ${n == 1 ? 'item' : 'items'} cannot be imported due to missing information.',
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text('Notes', style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            for (final msg in messages) ...[
              Text(msg, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirm bar
// ---------------------------------------------------------------------------

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.newCount});

  final int newCount;

  @override
  Widget build(BuildContext context) {
    final label = newCount == 0
        ? 'Nothing to import'
        : 'Import $newCount ${newCount == 1 ? 'record' : 'records'}';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: FilledButton(
          onPressed: null,
          child: Text(label),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error / empty states
// ---------------------------------------------------------------------------

class _NoTokenState extends StatelessWidget {
  const _NoTokenState();

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
              Icons.link_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Discogs account connected',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your Discogs account in Settings to import your collection.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RetriableErrorState extends StatelessWidget {
  const _RetriableErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
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
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

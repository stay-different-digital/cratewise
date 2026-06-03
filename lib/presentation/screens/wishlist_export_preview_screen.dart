import 'package:flutter/material.dart';

import '../../application/use_cases/build_wishlist_export_preview_use_case.dart';
import '../../application/use_cases/check_wishlist_export_capability_use_case.dart';
import '../../domain/models/wishlist_export_preview.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_wishlist_repository.dart';

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

class _Ready extends _PreviewState {
  const _Ready(this.preview);
  final WishlistExportPreview preview;
}

class _NotSupported extends _PreviewState {
  const _NotSupported(this.reason);
  final String reason;
}

class _Error extends _PreviewState {
  const _Error();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class WishlistExportPreviewScreen extends StatefulWidget {
  const WishlistExportPreviewScreen({
    super.key,
    this.useCase,
  });

  /// Injected only for testing. Production code passes null.
  final BuildWishlistExportPreviewUseCase? useCase;

  @override
  State<WishlistExportPreviewScreen> createState() =>
      _WishlistExportPreviewScreenState();
}

class _WishlistExportPreviewScreenState
    extends State<WishlistExportPreviewScreen> {
  late final BuildWishlistExportPreviewUseCase _useCase;
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
      _useCase = BuildWishlistExportPreviewUseCase(
        repository: LocalWishlistRepository(db),
        capabilityUseCase: const CheckWishlistExportCapabilityUseCase(),
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
        WishlistExportPreviewReady(:final preview) => _Ready(preview),
        WishlistExportPreviewNotSupported(:final reason) =>
          _NotSupported(reason),
        WishlistExportPreviewError() => const _Error(),
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
      appBar: AppBar(title: const Text('Export Wishlist to Discogs')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Ready(:final preview) => _PreviewBody(preview: preview),
        _NotSupported(:final reason) => _NotSupportedState(reason: reason),
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
  const _PreviewBody({required this.preview});

  final WishlistExportPreview preview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kWideBreakpoint;
        final hasNotes =
            preview.alreadySyncedCount > 0 || preview.invalidCount > 0;
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
                          if (hasNotes) ...[
                            const SizedBox(width: 16),
                            Expanded(child: _NotesCard(preview: preview)),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          _SummaryCard(preview: preview),
                          if (hasNotes) ...[
                            const SizedBox(height: 12),
                            _NotesCard(preview: preview),
                          ],
                        ],
                      ),
              ),
            ),
            _ConfirmBar(eligibleCount: preview.eligibleCount),
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

  final WishlistExportPreview preview;

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
            Text('Export preview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _CountRow(
              label: 'Total local items',
              value: '${preview.totalCount}',
            ),
            const SizedBox(height: 10),
            _CountRow(
              label: 'Ready to export',
              value: '${preview.eligibleCount}',
              color:
                  preview.eligibleCount > 0 ? theme.colorScheme.primary : null,
            ),
            const SizedBox(height: 10),
            _CountRow(
              label: 'Already linked to Discogs',
              value: '${preview.alreadySyncedCount}',
            ),
            const SizedBox(height: 10),
            _CountRow(
              label: 'Cannot export',
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
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
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
// Notes card
// ---------------------------------------------------------------------------

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.preview});

  final WishlistExportPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = <String>[];
    if (preview.alreadySyncedCount > 0) {
      final n = preview.alreadySyncedCount;
      messages.add(
        '$n ${n == 1 ? 'item is' : 'items are'} already in your Discogs wantlist and will be skipped.',
      );
    }
    if (preview.invalidCount > 0) {
      final n = preview.invalidCount;
      messages.add(
        '$n ${n == 1 ? 'item' : 'items'} cannot be exported due to a missing Discogs release ID.',
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
  const _ConfirmBar({required this.eligibleCount});

  final int eligibleCount;

  @override
  Widget build(BuildContext context) {
    final label = eligibleCount == 0
        ? 'Nothing to export'
        : 'Export $eligibleCount ${eligibleCount == 1 ? 'record' : 'records'}';
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
// Not supported state
// ---------------------------------------------------------------------------

class _NotSupportedState extends StatelessWidget {
  const _NotSupportedState({required this.reason});

  final String reason;

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
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Export not available',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reason,
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

// ---------------------------------------------------------------------------
// Retriable error state
// ---------------------------------------------------------------------------

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

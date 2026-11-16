import 'package:material_ui/material_ui.dart';

import '../../app/app_repositories.dart';
import '../../application/use_cases/build_collection_export_preview_use_case.dart';
import '../../application/use_cases/build_wishlist_export_preview_use_case.dart';
import '../../application/use_cases/check_collection_export_capability_use_case.dart';
import '../../application/use_cases/check_wishlist_export_capability_use_case.dart';
import '../../application/use_cases/execute_collection_export_use_case.dart';
import '../../application/use_cases/execute_wishlist_export_use_case.dart';
import '../../domain/models/collection_export_preview.dart';
import '../../domain/models/discogs_export_preview.dart';
import '../../domain/models/wishlist_export_preview.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';

const _kWideBreakpoint = 700.0;

// ---------------------------------------------------------------------------
// Entry points: collection and wishlist share one screen (US-130)
// ---------------------------------------------------------------------------

class CollectionExportPreviewScreen extends StatelessWidget {
  const CollectionExportPreviewScreen({
    super.key,
    this.useCase,
    this.executeUseCase,
  });

  /// Injected only for testing. Production code passes null.
  final BuildCollectionExportPreviewUseCase? useCase;

  /// Injected only for testing. Production code passes null.
  final ExecuteCollectionExportUseCase? executeUseCase;

  @override
  Widget build(BuildContext context) {
    var preview = useCase;
    var execute = executeUseCase;
    if (preview == null) {
      final repos = AppRepositoriesScope.of(context);
      preview = BuildCollectionExportPreviewUseCase(
        repository: repos.collection,
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
      );
      execute = ExecuteCollectionExportUseCase(
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
        tokenStorage: DiscogsTokenStorage(),
        apiClient: DiscogsApiClient.shared,
        collectionRepository: repos.collection,
        jobRepository: repos.importExportJob,
        rowResultRepository: repos.importExportRowResult,
      );
    }
    return _DiscogsExportPreviewScreen<CollectionExportPreview>(
      title: 'Export Collection to Discogs',
      noun: 'collection',
      alreadySyncedPhrase: 'already linked to your Discogs collection',
      loadPreview: () async => switch (await preview!.execute()) {
        CollectionExportPreviewReady(:final preview) => _Ready(preview),
        CollectionExportPreviewNotSupported(:final reason) => _NotSupported(
          reason,
        ),
        CollectionExportPreviewError() => const _Error(),
      },
      export: execute == null
          ? null
          : (p, onProgress) async => switch (await execute!.execute(
              p,
              onProgress: onProgress,
            )) {
              final ExecuteExportCompleted done => _ExportDone(done),
              ExecuteExportNotSupported(:final reason) => _NotSupported(reason),
              ExecuteExportNoToken() => const _NoToken(),
              ExecuteExportFailed(:final safeMessage) => _Failed(safeMessage),
            },
    );
  }
}

class WishlistExportPreviewScreen extends StatelessWidget {
  const WishlistExportPreviewScreen({
    super.key,
    this.useCase,
    this.executeUseCase,
  });

  /// Injected only for testing. Production code passes null.
  final BuildWishlistExportPreviewUseCase? useCase;

  /// Injected only for testing. Production code passes null.
  final ExecuteWishlistExportUseCase? executeUseCase;

  @override
  Widget build(BuildContext context) {
    var preview = useCase;
    var execute = executeUseCase;
    if (preview == null) {
      final repos = AppRepositoriesScope.of(context);
      preview = BuildWishlistExportPreviewUseCase(
        repository: repos.wishlist,
        capabilityUseCase: const CheckWishlistExportCapabilityUseCase(),
      );
      execute = ExecuteWishlistExportUseCase(
        capabilityUseCase: const CheckWishlistExportCapabilityUseCase(),
        tokenStorage: DiscogsTokenStorage(),
        apiClient: DiscogsApiClient.shared,
        wishlistRepository: repos.wishlist,
        jobRepository: repos.importExportJob,
        rowResultRepository: repos.importExportRowResult,
      );
    }
    return _DiscogsExportPreviewScreen<WishlistExportPreview>(
      title: 'Export Wishlist to Discogs',
      noun: 'wishlist',
      alreadySyncedPhrase: 'already in your Discogs wantlist',
      loadPreview: () async => switch (await preview!.execute()) {
        WishlistExportPreviewReady(:final preview) => _Ready(preview),
        WishlistExportPreviewNotSupported(:final reason) => _NotSupported(
          reason,
        ),
        WishlistExportPreviewError() => const _Error(),
      },
      export: execute == null
          ? null
          : (p, onProgress) async => switch (await execute!.execute(
              p,
              onProgress: onProgress,
            )) {
              final ExecuteWishlistExportCompleted done => _ExportDone(done),
              ExecuteWishlistExportNotSupported(:final reason) => _NotSupported(
                reason,
              ),
              ExecuteWishlistExportNoToken() => const _NoToken(),
              ExecuteWishlistExportFailed(:final safeMessage) => _Failed(
                safeMessage,
              ),
            },
    );
  }
}

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
  final DiscogsExportPreview preview;
}

class _NotSupported extends _PreviewState {
  const _NotSupported(this.reason);
  final String reason;
}

class _Error extends _PreviewState {
  const _Error();
}

class _NoToken extends _PreviewState {
  const _NoToken();
}

class _Exporting extends _PreviewState {
  const _Exporting({this.current = 0, this.total = 0, this.currentItem = ''});
  final int current;
  final int total;
  final String currentItem;
}

class _ExportDone extends _PreviewState {
  const _ExportDone(this.result);
  final DiscogsExportDone result;
}

/// Transient: export failed; the screen returns to [_Ready] with a snackbar.
class _Failed extends _PreviewState {
  const _Failed(this.safeMessage);
  final String safeMessage;
}

// ---------------------------------------------------------------------------
// Shared screen
// ---------------------------------------------------------------------------

typedef _OnProgress = void Function(int current, int total, String item);

class _DiscogsExportPreviewScreen<P extends DiscogsExportPreview>
    extends StatefulWidget {
  const _DiscogsExportPreviewScreen({
    super.key,
    required this.title,
    required this.noun,
    required this.alreadySyncedPhrase,
    required this.loadPreview,
    this.export,
  });

  final String title;
  final String noun;
  final String alreadySyncedPhrase;

  /// Resolves to [_Ready], [_NotSupported] or [_Error].
  final Future<_PreviewState> Function() loadPreview;

  /// Resolves to [_ExportDone], [_NotSupported], [_NoToken] or [_Failed].
  /// Null disables the confirm action.
  final Future<_PreviewState> Function(P preview, _OnProgress onProgress)?
  export;

  @override
  State<_DiscogsExportPreviewScreen<P>> createState() =>
      _DiscogsExportPreviewScreenState<P>();
}

class _DiscogsExportPreviewScreenState<P extends DiscogsExportPreview>
    extends State<_DiscogsExportPreviewScreen<P>> {
  _PreviewState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    final next = await widget.loadPreview();
    if (!mounted) return;
    setState(() => _state = next);
  }

  Future<void> _executeExport(P preview) async {
    final export = widget.export;
    if (export == null) return;
    setState(() => _state = const _Exporting());
    final next = await export(preview, (current, total, item) {
      if (!mounted) return;
      setState(
        () => _state = _Exporting(
          current: current,
          total: total,
          currentItem: item,
        ),
      );
    });
    if (!mounted) return;
    if (next is _Failed) {
      setState(() => _state = _Ready(preview));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.safeMessage)));
    } else {
      setState(() => _state = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: switch (_state) {
        _Loading() ||
        _Failed() => const Center(child: CircularProgressIndicator()),
        _Ready(:final preview) => _PreviewBody(
          preview: preview,
          alreadySyncedPhrase: widget.alreadySyncedPhrase,
          onConfirm: widget.export != null
              ? () => _executeExport(preview as P)
              : null,
        ),
        _NotSupported(:final reason) => _NotSupportedState(reason: reason),
        _Error() => _RetriableErrorState(
          message: 'Something went wrong. Check your connection and try again.',
          onRetry: _load,
        ),
        _NoToken() => _NoTokenState(noun: widget.noun),
        _Exporting(:final current, :final total, :final currentItem) =>
          _ExportingBody(
            noun: widget.noun,
            current: current,
            total: total,
            currentItem: currentItem,
          ),
        _ExportDone(:final result) => _ExportSummaryBody(
          result: result,
          onDone: () => Navigator.of(context).pop(),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Preview body
// ---------------------------------------------------------------------------

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.preview,
    required this.alreadySyncedPhrase,
    this.onConfirm,
  });

  final DiscogsExportPreview preview;
  final String alreadySyncedPhrase;
  final VoidCallback? onConfirm;

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
                            Expanded(
                              child: _NotesCard(
                                preview: preview,
                                alreadySyncedPhrase: alreadySyncedPhrase,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          _SummaryCard(preview: preview),
                          if (hasNotes) ...[
                            const SizedBox(height: 12),
                            _NotesCard(
                              preview: preview,
                              alreadySyncedPhrase: alreadySyncedPhrase,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            _ConfirmBar(
              eligibleCount: preview.eligibleCount,
              onConfirm: onConfirm,
            ),
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

  final DiscogsExportPreview preview;

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
              color: preview.eligibleCount > 0
                  ? theme.colorScheme.primary
                  : null,
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
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
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
  const _NotesCard({required this.preview, required this.alreadySyncedPhrase});

  final DiscogsExportPreview preview;

  /// e.g. "already linked to your Discogs collection".
  final String alreadySyncedPhrase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = <String>[];
    if (preview.alreadySyncedCount > 0) {
      final n = preview.alreadySyncedCount;
      messages.add(
        '$n ${n == 1 ? 'item is' : 'items are'} $alreadySyncedPhrase and will be skipped.',
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
  const _ConfirmBar({required this.eligibleCount, this.onConfirm});

  final int eligibleCount;
  final VoidCallback? onConfirm;

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
          onPressed: eligibleCount > 0 ? onConfirm : null,
          child: Text(label),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exporting body
// ---------------------------------------------------------------------------

class _ExportingBody extends StatelessWidget {
  const _ExportingBody({
    required this.noun,
    this.current = 0,
    this.total = 0,
    this.currentItem = '',
  });

  final String noun;
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
                  ? 'Exporting item $current of $total…'
                  : 'Exporting your $noun…',
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

// ---------------------------------------------------------------------------
// Export summary body
// ---------------------------------------------------------------------------

class _ExportSummaryBody extends StatelessWidget {
  const _ExportSummaryBody({required this.result, required this.onDone});

  final DiscogsExportDone result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Export complete',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CountRow(
                          label: 'Added to Discogs',
                          value: '${result.exported}',
                          color: result.exported > 0
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        if (result.skipped > 0) ...[
                          const SizedBox(height: 10),
                          _CountRow(
                            label: 'Skipped',
                            value: '${result.skipped}',
                          ),
                        ],
                        if (result.failed > 0) ...[
                          const SizedBox(height: 10),
                          _CountRow(
                            label: 'Failed',
                            value: '${result.failed}',
                            color: theme.colorScheme.error,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: FilledButton(onPressed: onDone, child: const Text('Done')),
          ),
        ),
      ],
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No token state
// ---------------------------------------------------------------------------

class _NoTokenState extends StatelessWidget {
  const _NoTokenState({required this.noun});

  final String noun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
                'Connect your Discogs account in Settings to export your $noun.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Retriable error state
// ---------------------------------------------------------------------------

class _RetriableErrorState extends StatelessWidget {
  const _RetriableErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
      ),
    );
  }
}

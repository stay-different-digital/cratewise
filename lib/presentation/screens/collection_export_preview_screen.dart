import 'package:flutter/material.dart';

import '../../application/use_cases/build_collection_export_preview_use_case.dart';
import '../../application/use_cases/check_collection_export_capability_use_case.dart';
import '../../application/use_cases/execute_collection_export_use_case.dart';
import '../../domain/models/collection_export_preview.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';
import '../../infrastructure/local_database/local_import_export_job_repository.dart';
import '../../infrastructure/local_database/local_import_export_row_result_repository.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';

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
  final CollectionExportPreview preview;
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
  final ExecuteExportCompleted result;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CollectionExportPreviewScreen extends StatefulWidget {
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
  State<CollectionExportPreviewScreen> createState() =>
      _CollectionExportPreviewScreenState();
}

class _CollectionExportPreviewScreenState
    extends State<CollectionExportPreviewScreen> {
  late final BuildCollectionExportPreviewUseCase _useCase;
  ExecuteCollectionExportUseCase? _executeUseCase;
  AppDatabase? _ownedDb;
  _PreviewState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    if (widget.useCase != null) {
      _useCase = widget.useCase!;
      _executeUseCase = widget.executeUseCase;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      final collectionRepo = LocalCollectionRepository(db);
      _useCase = BuildCollectionExportPreviewUseCase(
        repository: collectionRepo,
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
      );
      _executeUseCase = ExecuteCollectionExportUseCase(
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
        tokenStorage: DiscogsTokenStorage(),
        apiClient: DiscogsApiClient(),
        collectionRepository: collectionRepo,
        jobRepository: LocalImportExportJobRepository(db),
        rowResultRepository: LocalImportExportRowResultRepository(db),
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
        CollectionExportPreviewReady(:final preview) => _Ready(preview),
        CollectionExportPreviewNotSupported(:final reason) => _NotSupported(
          reason,
        ),
        CollectionExportPreviewError() => const _Error(),
      };
    });
  }

  Future<void> _executeExport(CollectionExportPreview preview) async {
    final uc = _executeUseCase;
    if (uc == null) return;
    setState(() => _state = const _Exporting());
    final result = await uc.execute(
      preview,
      onProgress: (current, total, item) {
        if (!mounted) return;
        setState(
          () => _state = _Exporting(
            current: current,
            total: total,
            currentItem: item,
          ),
        );
      },
    );
    if (!mounted) return;
    switch (result) {
      case ExecuteExportCompleted():
        setState(() => _state = _ExportDone(result));
      case ExecuteExportNotSupported(:final reason):
        setState(() => _state = _NotSupported(reason));
      case ExecuteExportNoToken():
        setState(() => _state = const _NoToken());
      case ExecuteExportFailed(:final safeMessage):
        setState(() => _state = _Ready(preview));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(safeMessage)));
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
      appBar: AppBar(title: const Text('Export Collection to Discogs')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Ready(:final preview) => _PreviewBody(
          preview: preview,
          onConfirm: _executeUseCase != null
              ? () => _executeExport(preview)
              : null,
        ),
        _NotSupported(:final reason) => _NotSupportedState(reason: reason),
        _Error() => _RetriableErrorState(
          message: 'Something went wrong. Check your connection and try again.',
          onRetry: _load,
        ),
        _NoToken() => const _NoTokenState(),
        _Exporting(:final current, :final total, :final currentItem) =>
          _ExportingBody(
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
  const _PreviewBody({required this.preview, this.onConfirm});

  final CollectionExportPreview preview;
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

  final CollectionExportPreview preview;

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
  const _NotesCard({required this.preview});

  final CollectionExportPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = <String>[];
    if (preview.alreadySyncedCount > 0) {
      final n = preview.alreadySyncedCount;
      messages.add(
        '$n ${n == 1 ? 'item is' : 'items are'} already linked to your Discogs collection and will be skipped.',
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
    this.current = 0,
    this.total = 0,
    this.currentItem = '',
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
                  ? 'Exporting item $current of $total…'
                  : 'Exporting your collection…',
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

  final ExecuteExportCompleted result;
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
  const _NoTokenState();

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
                'Connect your Discogs account in Settings to export your collection.',
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

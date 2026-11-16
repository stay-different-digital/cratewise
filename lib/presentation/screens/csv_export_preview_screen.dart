import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_repositories.dart';
import '../../application/use_cases/build_collection_csv_export_preview_use_case.dart';
import '../../application/use_cases/build_wishlist_csv_export_preview_use_case.dart';
import '../../application/use_cases/execute_collection_csv_export_use_case.dart';
import '../../application/use_cases/execute_wishlist_csv_export_use_case.dart';
import '../../domain/models/csv_collection_export_preview.dart';
import '../../domain/models/csv_export_preview.dart';
import '../../domain/models/csv_wishlist_export_preview.dart';
import '../../infrastructure/csv/csv_file_writer.dart';

const _kWideBreakpoint = 700.0;
const _kMaxSampleRows = 3;

// ---------------------------------------------------------------------------
// Entry points: collection and wishlist share one screen (US-130)
// ---------------------------------------------------------------------------

class CollectionCsvExportPreviewScreen extends StatelessWidget {
  const CollectionCsvExportPreviewScreen({
    super.key,
    this.previewUseCase,
    this.executeUseCase,
    this.onShareFile,
  });

  /// Injected only for testing. Production code passes null.
  final BuildCollectionCsvExportPreviewUseCase? previewUseCase;

  /// Injected only for testing. Production code passes null.
  final ExecuteCollectionCsvExportUseCase? executeUseCase;

  /// Injected only for testing. Production code passes null.
  final Future<void> Function(String filePath)? onShareFile;

  @override
  Widget build(BuildContext context) {
    var preview = previewUseCase;
    var execute = executeUseCase;
    if (preview == null) {
      final repos = AppRepositoriesScope.of(context);
      preview = BuildCollectionCsvExportPreviewUseCase(
        repository: repos.collection,
      );
      execute = ExecuteCollectionCsvExportUseCase(
        jobRepository: repos.importExportJob,
        fileWriter: const TempCsvFileWriter(),
      );
    }
    return CsvExportPreviewScreen<CsvCollectionExportPreview>(
      title: 'Export Collection to CSV',
      emptyMessage: 'Your collection is empty. Add items before exporting.',
      onShareFile: onShareFile,
      loadPreview: () async => switch (await preview!.execute()) {
        CollectionCsvExportPreviewReady(:final preview) => preview,
        CollectionCsvExportPreviewError() => null,
      },
      export: execute == null
          ? null
          : (p) async => switch (await execute!.execute(p)) {
              final ExecuteCollectionCsvExportCompleted done => (done, null),
              ExecuteCollectionCsvExportFailed(:final safeMessage) => (
                null,
                safeMessage,
              ),
            },
    );
  }
}

class WishlistCsvExportPreviewScreen extends StatelessWidget {
  const WishlistCsvExportPreviewScreen({
    super.key,
    this.previewUseCase,
    this.executeUseCase,
    this.onShareFile,
  });

  /// Injected only for testing. Production code passes null.
  final BuildWishlistCsvExportPreviewUseCase? previewUseCase;

  /// Injected only for testing. Production code passes null.
  final ExecuteWishlistCsvExportUseCase? executeUseCase;

  /// Injected only for testing. Production code passes null.
  final Future<void> Function(String filePath)? onShareFile;

  @override
  Widget build(BuildContext context) {
    var preview = previewUseCase;
    var execute = executeUseCase;
    if (preview == null) {
      final repos = AppRepositoriesScope.of(context);
      preview = BuildWishlistCsvExportPreviewUseCase(
        repository: repos.wishlist,
      );
      execute = ExecuteWishlistCsvExportUseCase(
        jobRepository: repos.importExportJob,
        fileWriter: const TempCsvFileWriter(),
      );
    }
    return CsvExportPreviewScreen<CsvWishlistExportPreview>(
      title: 'Export Wishlist to CSV',
      emptyMessage: 'Your wishlist is empty. Add items before exporting.',
      onShareFile: onShareFile,
      loadPreview: () async => switch (await preview!.execute()) {
        WishlistCsvExportPreviewReady(:final preview) => preview,
        WishlistCsvExportPreviewError() => null,
      },
      export: execute == null
          ? null
          : (p) async => switch (await execute!.execute(p)) {
              final ExecuteWishlistCsvExportCompleted done => (done, null),
              ExecuteWishlistCsvExportFailed(:final safeMessage) => (
                null,
                safeMessage,
              ),
            },
    );
  }
}

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _State {
  const _State();
}

class _Loading extends _State {
  const _Loading();
}

class _Ready extends _State {
  const _Ready(this.preview);
  final CsvExportPreview preview;
}

class _Exporting extends _State {
  const _Exporting();
}

class _Done extends _State {
  const _Done(this.result);
  final CsvExportDone result;
}

class _Error extends _State {
  const _Error();
}

// ---------------------------------------------------------------------------
// Shared screen
// ---------------------------------------------------------------------------

/// Export outcome: the finished export, or a safe user-facing error message.
typedef CsvExportOutcome = (CsvExportDone?, String?);

class CsvExportPreviewScreen<P extends CsvExportPreview>
    extends StatefulWidget {
  const CsvExportPreviewScreen({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.loadPreview,
    this.export,
    this.onShareFile,
  });

  final String title;
  final String emptyMessage;

  /// Returns null when the preview could not be built.
  final Future<P?> Function() loadPreview;

  /// Null hides the export action.
  final Future<CsvExportOutcome> Function(P preview)? export;

  final Future<void> Function(String filePath)? onShareFile;

  @override
  State<CsvExportPreviewScreen<P>> createState() =>
      _CsvExportPreviewScreenState<P>();
}

class _CsvExportPreviewScreenState<P extends CsvExportPreview>
    extends State<CsvExportPreviewScreen<P>> {
  _State _state = const _Loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    final preview = await widget.loadPreview();
    if (!mounted) return;
    setState(() => _state = preview != null ? _Ready(preview) : const _Error());
  }

  Future<void> _executeExport(P preview) async {
    final export = widget.export;
    if (export == null) return;
    setState(() => _state = const _Exporting());
    final (done, error) = await export(preview);
    if (!mounted) return;
    if (done != null) {
      setState(() => _state = _Done(done));
    } else {
      setState(() => _state = _Ready(preview));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Export failed')));
    }
  }

  static Future<void> _defaultShareFile(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath, mimeType: 'text/csv')]),
    );
  }

  Future<void> _shareAgain(String filePath) async {
    if (!File(filePath).existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File no longer available. Please export again.'),
        ),
      );
      return;
    }
    final share = widget.onShareFile ?? _defaultShareFile;
    await share(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Ready(:final preview) => _PreviewBody(
          preview: preview,
          emptyMessage: widget.emptyMessage,
          onConfirm: widget.export != null
              ? () => _executeExport(preview as P)
              : null,
        ),
        _Exporting() => const _ExportingBody(),
        _Done(:final result) => _DoneBody(
          result: result,
          onDone: () => Navigator.of(context).pop(),
          onShareAgain: () => _shareAgain(result.filePath),
        ),
        _Error() => _ErrorBody(onRetry: _load),
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
    required this.emptyMessage,
    this.onConfirm,
  });

  final CsvExportPreview preview;
  final String emptyMessage;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kWideBreakpoint;
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
                          Expanded(
                            child: _SummaryCard(
                              preview: preview,
                              emptyMessage: emptyMessage,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _SampleCard(preview: preview)),
                        ],
                      )
                    : Column(
                        children: [
                          _SummaryCard(
                            preview: preview,
                            emptyMessage: emptyMessage,
                          ),
                          const SizedBox(height: 12),
                          _SampleCard(preview: preview),
                        ],
                      ),
              ),
            ),
            _ConfirmBar(rowCount: preview.rowCount, onConfirm: onConfirm),
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
  const _SummaryCard({required this.preview, required this.emptyMessage});

  final CsvExportPreview preview;
  final String emptyMessage;

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
            _LabelValue(
              label: 'Rows to export',
              value: '${preview.rowCount}',
              valueColor: preview.rowCount > 0
                  ? theme.colorScheme.primary
                  : null,
            ),
            if (preview.rowCount == 0) ...[
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _LabelValue(label: 'Columns', value: '${preview.headers.length}'),
            const SizedBox(height: 16),
            Text('Columns', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final header in preview.headers)
                  _ColumnChip(label: header),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

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
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ColumnChip extends StatelessWidget {
  const _ColumnChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

// ---------------------------------------------------------------------------
// Sample card
// ---------------------------------------------------------------------------

class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.preview});

  final CsvExportPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleRows = preview.sampleRows.take(_kMaxSampleRows).toList();
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
                  Icons.table_rows_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  sampleRows.isEmpty
                      ? 'No data to preview'
                      : 'Sample data (first ${sampleRows.length} ${sampleRows.length == 1 ? 'row' : 'rows'})',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            if (sampleRows.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final row in sampleRows) ...[
                _SampleRow(row: row),
                const SizedBox(height: 4),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SampleRow extends StatelessWidget {
  const _SampleRow({required this.row});

  final List<String> row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artist = row.isNotEmpty ? row[0] : '';
    final title = row.length > 1 ? row[1] : '';
    final year = row.length > 6 ? row[6] : '';
    final summary = [
      if (artist.isNotEmpty) artist,
      if (title.isNotEmpty) title,
      if (year.isNotEmpty) year,
    ].join(' – ');
    return Text(
      summary.isNotEmpty ? summary : '(empty row)',
      style: theme.textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ---------------------------------------------------------------------------
// Confirm bar
// ---------------------------------------------------------------------------

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.rowCount, this.onConfirm});

  final int rowCount;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final label = rowCount == 0
        ? 'Nothing to export'
        : 'Export $rowCount ${rowCount == 1 ? 'row' : 'rows'}';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: FilledButton(
          onPressed: rowCount > 0 ? onConfirm : null,
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
  const _ExportingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Generating CSV…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Done body
// ---------------------------------------------------------------------------

class _DoneBody extends StatelessWidget {
  const _DoneBody({
    required this.result,
    required this.onDone,
    required this.onShareAgain,
  });

  final CsvExportDone result;
  final VoidCallback onDone;
  final VoidCallback onShareAgain;

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
                const SizedBox(height: 8),
                Text(
                  '${result.rowCount} ${result.rowCount == 1 ? 'row' : 'rows'} exported',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  result.filename,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: onShareAgain,
                  child: const Text('Share Again'),
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: onDone, child: const Text('Done')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

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
                'Something went wrong. Check your connection and try again.',
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

import 'package:flutter/material.dart';

import '../../application/use_cases/build_collection_csv_export_preview_use_case.dart';
import '../../application/use_cases/execute_collection_csv_export_use_case.dart';
import '../../domain/models/csv_collection_export_preview.dart';
import '../../infrastructure/csv/csv_file_writer.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';
import '../../infrastructure/local_database/local_import_export_job_repository.dart';

const _kWideBreakpoint = 700.0;
const _kMaxSampleRows = 3;

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
  final CsvCollectionExportPreview preview;
}

class _Exporting extends _State {
  const _Exporting();
}

class _Done extends _State {
  const _Done(this.result);
  final ExecuteCollectionCsvExportCompleted result;
}

class _Error extends _State {
  const _Error();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CollectionCsvExportPreviewScreen extends StatefulWidget {
  const CollectionCsvExportPreviewScreen({
    super.key,
    this.previewUseCase,
    this.executeUseCase,
  });

  /// Injected only for testing. Production code passes null.
  final BuildCollectionCsvExportPreviewUseCase? previewUseCase;

  /// Injected only for testing. Production code passes null.
  final ExecuteCollectionCsvExportUseCase? executeUseCase;

  @override
  State<CollectionCsvExportPreviewScreen> createState() =>
      _CollectionCsvExportPreviewScreenState();
}

class _CollectionCsvExportPreviewScreenState
    extends State<CollectionCsvExportPreviewScreen> {
  late final BuildCollectionCsvExportPreviewUseCase _previewUseCase;
  ExecuteCollectionCsvExportUseCase? _executeUseCase;
  AppDatabase? _ownedDb;
  _State _state = const _Loading();

  @override
  void initState() {
    super.initState();
    if (widget.previewUseCase != null) {
      _previewUseCase = widget.previewUseCase!;
      _executeUseCase = widget.executeUseCase;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      final collectionRepo = LocalCollectionRepository(db);
      _previewUseCase = BuildCollectionCsvExportPreviewUseCase(
        repository: collectionRepo,
      );
      _executeUseCase = ExecuteCollectionCsvExportUseCase(
        jobRepository: LocalImportExportJobRepository(db),
        fileWriter: const TempCsvFileWriter(),
      );
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    final result = await _previewUseCase.execute();
    if (!mounted) return;
    setState(() {
      _state = switch (result) {
        CollectionCsvExportPreviewReady(:final preview) => _Ready(preview),
        CollectionCsvExportPreviewError() => const _Error(),
      };
    });
  }

  Future<void> _executeExport(CsvCollectionExportPreview preview) async {
    final uc = _executeUseCase;
    if (uc == null) return;
    setState(() => _state = const _Exporting());
    final result = await uc.execute(preview);
    if (!mounted) return;
    switch (result) {
      case ExecuteCollectionCsvExportCompleted():
        setState(() => _state = _Done(result));
      case ExecuteCollectionCsvExportFailed(:final safeMessage):
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
      appBar: AppBar(title: const Text('Export Collection to CSV')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Ready(:final preview) => _PreviewBody(
          preview: preview,
          onConfirm: _executeUseCase != null
              ? () => _executeExport(preview)
              : null,
        ),
        _Exporting() => const _ExportingBody(),
        _Done(:final result) => _DoneBody(
          result: result,
          onDone: () => Navigator.of(context).pop(),
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
  const _PreviewBody({required this.preview, this.onConfirm});

  final CsvCollectionExportPreview preview;
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
                          Expanded(child: _SummaryCard(preview: preview)),
                          const SizedBox(width: 16),
                          Expanded(child: _SampleCard(preview: preview)),
                        ],
                      )
                    : Column(
                        children: [
                          _SummaryCard(preview: preview),
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
  const _SummaryCard({required this.preview});

  final CsvCollectionExportPreview preview;

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
                'Your collection is empty. Add items before exporting.',
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

  final CsvCollectionExportPreview preview;

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
  const _DoneBody({required this.result, required this.onDone});

  final ExecuteCollectionCsvExportCompleted result;
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
            child: FilledButton(onPressed: onDone, child: const Text('Done')),
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

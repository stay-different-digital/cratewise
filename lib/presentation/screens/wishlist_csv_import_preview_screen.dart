import 'package:flutter/material.dart';

import '../../application/use_cases/build_wishlist_csv_import_preview_use_case.dart';
import '../../application/use_cases/execute_wishlist_csv_import_use_case.dart';
import '../../domain/models/csv_wishlist_import_preview.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../infrastructure/csv/csv_file_picker_service.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_import_export_job_repository.dart';
import '../../infrastructure/local_database/local_import_export_row_result_repository.dart';
import '../../infrastructure/local_database/local_wishlist_repository.dart';

const _kWideBreakpoint = 700.0;
const _kMaxVisibleErrors = 5;

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _State {
  const _State();
}

class _Idle extends _State {
  const _Idle();
}

class _Preview extends _State {
  const _Preview({required this.filename, required this.preview});
  final String filename;
  final CsvWishlistImportPreview preview;
}

class _ParseFailed extends _State {
  const _ParseFailed(this.reason);
  final String reason;
}

class _Error extends _State {
  const _Error();
}

class _Importing extends _State {
  const _Importing();
}

class _Done extends _State {
  const _Done(this.result);
  final ExecuteWishlistCsvImportCompleted result;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class WishlistCsvImportPreviewScreen extends StatefulWidget {
  const WishlistCsvImportPreviewScreen({
    super.key,
    this.previewUseCase,
    this.executeUseCase,
    this.onPickFile,
  });

  /// Injected only for testing. Production code passes null.
  final BuildWishlistCsvImportPreviewUseCase? previewUseCase;

  /// Injected only for testing. Production code passes null.
  final ExecuteWishlistCsvImportUseCase? executeUseCase;

  /// Injected only for testing. Production code passes null.
  final Future<CsvPickedFile?> Function()? onPickFile;

  @override
  State<WishlistCsvImportPreviewScreen> createState() =>
      _WishlistCsvImportPreviewScreenState();
}

class _WishlistCsvImportPreviewScreenState
    extends State<WishlistCsvImportPreviewScreen> {
  late final BuildWishlistCsvImportPreviewUseCase _previewUseCase;
  late final Future<CsvPickedFile?> Function() _picker;
  ExecuteWishlistCsvImportUseCase? _executeUseCase;
  AppDatabase? _ownedDb;
  _State _state = const _Idle();

  @override
  void initState() {
    super.initState();
    _previewUseCase =
        widget.previewUseCase ?? const BuildWishlistCsvImportPreviewUseCase();
    _picker = widget.onPickFile ?? const CsvFilePickerService().pick;

    if (widget.onPickFile != null || widget.previewUseCase != null) {
      // Test mode — use injected execute use case (may be null = confirm disabled)
      _executeUseCase = widget.executeUseCase;
    } else {
      // Production mode — create execute use case from local DB
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _executeUseCase = ExecuteWishlistCsvImportUseCase(
        wishlistRepository: LocalWishlistRepository(db),
        jobRepository: LocalImportExportJobRepository(db),
        rowResultRepository: LocalImportExportRowResultRepository(db),
      );
    }
  }

  @override
  void dispose() {
    _ownedDb?.close();
    super.dispose();
  }

  Future<void> _pickAndPreview() async {
    final file = await _picker();
    if (!mounted) return;
    if (file == null) return;

    final result = _previewUseCase.execute(
      filename: file.filename,
      content: file.content,
    );
    setState(() {
      _state = switch (result) {
        WishlistCsvImportPreviewReady(:final filename, :final preview) =>
          _Preview(filename: filename, preview: preview),
        WishlistCsvImportPreviewParseFailed(:final reason) => _ParseFailed(
          reason,
        ),
        WishlistCsvImportPreviewError() => const _Error(),
      };
    });
  }

  Future<void> _executeImport(CsvWishlistImportPreview preview) async {
    final uc = _executeUseCase;
    if (uc == null) return;
    setState(() => _state = const _Importing());
    final result = await uc.execute(preview);
    if (!mounted) return;
    switch (result) {
      case ExecuteWishlistCsvImportCompleted():
        setState(() => _state = _Done(result));
      case ExecuteWishlistCsvImportFailed():
        setState(() => _state = _Preview(filename: '', preview: preview));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.safeMessage)));
    }
  }

  void _reset() => setState(() => _state = const _Idle());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wishlist from CSV')),
      body: switch (_state) {
        _Idle() => _IdleBody(onPickFile: _pickAndPreview),
        _Preview(:final filename, :final preview) => _PreviewBody(
          filename: filename,
          preview: preview,
          onPickDifferentFile: _reset,
          onConfirm: _executeUseCase != null && preview.validCount > 0
              ? () => _executeImport(preview)
              : null,
        ),
        _ParseFailed(:final reason) => _ParseFailedBody(
          reason: reason,
          onTryAgain: _reset,
        ),
        _Error() => _ErrorBody(onTryAgain: _reset),
        _Importing() => const _ImportingBody(),
        _Done(:final result) => _DoneBody(
          result: result,
          onDone: () => Navigator.of(context).pop(),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Idle body
// ---------------------------------------------------------------------------

class _IdleBody extends StatelessWidget {
  const _IdleBody({required this.onPickFile});

  final VoidCallback onPickFile;

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
                Icons.upload_file_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a CSV file',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a CSV file exported from Cratewise or Discogs to preview your wishlist import.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onPickFile,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Choose file'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview body
// ---------------------------------------------------------------------------

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.filename,
    required this.preview,
    required this.onPickDifferentFile,
    this.onConfirm,
  });

  final String filename;
  final CsvWishlistImportPreview preview;
  final VoidCallback onPickDifferentFile;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kWideBreakpoint;
        final hasErrors = preview.failedCount > 0;
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
                              filename: filename,
                              preview: preview,
                            ),
                          ),
                          if (hasErrors) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ErrorsCard(
                                failedRows: preview.failedRows,
                                totalFailed: preview.failedCount,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          _SummaryCard(filename: filename, preview: preview),
                          if (hasErrors) ...[
                            const SizedBox(height: 12),
                            _ErrorsCard(
                              failedRows: preview.failedRows,
                              totalFailed: preview.failedCount,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            _PickDifferentFileBar(onPickDifferentFile: onPickDifferentFile),
            _ConfirmBar(validCount: preview.validCount, onConfirm: onConfirm),
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
  const _SummaryCard({required this.filename, required this.preview});

  final String filename;
  final CsvWishlistImportPreview preview;

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
            Text('Import preview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _CountRow(label: 'File', value: filename),
            const SizedBox(height: 10),
            _CountRow(label: 'Total rows', value: '${preview.totalCount}'),
            const SizedBox(height: 10),
            _CountRow(
              label: 'Ready to import',
              value: '${preview.validCount}',
              color: preview.validCount > 0 ? theme.colorScheme.primary : null,
            ),
            if (preview.skippedCount > 0) ...[
              const SizedBox(height: 10),
              _CountRow(
                label: 'Skipped (duplicate)',
                value: '${preview.skippedCount}',
              ),
            ],
            if (preview.failedCount > 0) ...[
              const SizedBox(height: 10),
              _CountRow(
                label: 'Errors',
                value: '${preview.failedCount}',
                color: theme.colorScheme.error,
              ),
            ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Errors card
// ---------------------------------------------------------------------------

class _ErrorsCard extends StatelessWidget {
  const _ErrorsCard({required this.failedRows, required this.totalFailed});

  final List<FailedRow> failedRows;
  final int totalFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = failedRows.take(_kMaxVisibleErrors).toList();
    final remaining = totalFailed - visible.length;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 16,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Validation errors',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final row in visible) ...[
              Text(
                'Row ${row.rowIndex + 2}: ${row.safeErrorMessage}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (remaining > 0)
              Text(
                '…and $remaining more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pick different file bar
// ---------------------------------------------------------------------------

class _PickDifferentFileBar extends StatelessWidget {
  const _PickDifferentFileBar({required this.onPickDifferentFile});

  final VoidCallback onPickDifferentFile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Center(
        child: TextButton.icon(
          onPressed: onPickDifferentFile,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: const Text('Choose different file'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirm bar
// ---------------------------------------------------------------------------

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.validCount, this.onConfirm});

  final int validCount;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final label = validCount == 0
        ? 'Nothing to import'
        : 'Import $validCount ${validCount == 1 ? 'record' : 'records'}';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: FilledButton(
          onPressed: validCount > 0 ? onConfirm : null,
          child: Text(label),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Importing body
// ---------------------------------------------------------------------------

class _ImportingBody extends StatelessWidget {
  const _ImportingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Saving your wishlist…',
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

  final ExecuteWishlistCsvImportCompleted result;
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
                  'Import complete',
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
                          label: 'Added to wishlist',
                          value: '${result.imported}',
                          color: result.imported > 0
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: FilledButton(onPressed: onDone, child: const Text('Done')),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Parse failed body
// ---------------------------------------------------------------------------

class _ParseFailedBody extends StatelessWidget {
  const _ParseFailedBody({required this.reason, required this.onTryAgain});

  final String reason;
  final VoidCallback onTryAgain;

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
                'Could not read this file',
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
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onTryAgain,
                child: const Text('Choose different file'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onTryAgain});

  final VoidCallback onTryAgain;

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
                'Something went wrong reading the file.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onTryAgain,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/app_repositories.dart';
import '../../application/use_cases/build_collection_csv_import_preview_use_case.dart';
import '../../application/use_cases/build_wishlist_csv_import_preview_use_case.dart';
import '../../application/use_cases/execute_collection_csv_import_use_case.dart';
import '../../application/use_cases/execute_wishlist_csv_import_use_case.dart';
import '../../domain/models/csv_collection_import_preview.dart';
import '../../domain/models/csv_import_preview.dart';
import '../../domain/models/csv_wishlist_import_preview.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../infrastructure/csv/csv_file_picker_service.dart';
import '../../shared/import_notifier.dart';

const _kWideBreakpoint = 700.0;
const _kMaxVisibleErrors = 5;

// ---------------------------------------------------------------------------
// Entry points: collection and wishlist share one screen (US-130)
// ---------------------------------------------------------------------------

class CollectionCsvImportPreviewScreen extends StatelessWidget {
  const CollectionCsvImportPreviewScreen({
    super.key,
    this.previewUseCase,
    this.executeUseCase,
    this.onPickFile,
  });

  /// Injected only for testing. Production code passes null.
  final BuildCollectionCsvImportPreviewUseCase? previewUseCase;

  /// Injected only for testing. Production code passes null.
  final ExecuteCollectionCsvImportUseCase? executeUseCase;

  /// Injected only for testing. Production code passes null.
  final Future<CsvPickedFile?> Function()? onPickFile;

  @override
  Widget build(BuildContext context) {
    final preview =
        previewUseCase ?? const BuildCollectionCsvImportPreviewUseCase();
    var execute = executeUseCase;
    if (onPickFile == null && previewUseCase == null) {
      final repos = AppRepositoriesScope.maybeOf(context);
      if (repos != null) {
        execute = ExecuteCollectionCsvImportUseCase(
          collectionRepository: repos.collection,
          jobRepository: repos.importExportJob,
          rowResultRepository: repos.importExportRowResult,
        );
      }
    }
    return CsvImportPreviewScreen<CsvCollectionImportPreview>(
      title: 'Import Collection from CSV',
      noun: 'collection',
      onPickFile: onPickFile,
      buildPreview: (filename, content) =>
          switch (preview.execute(filename: filename, content: content)) {
            CollectionCsvImportPreviewReady(:final filename, :final preview) =>
              (filename: filename, preview: preview, parseFailure: null),
            CollectionCsvImportPreviewParseFailed(:final reason) => (
              filename: filename,
              preview: null,
              parseFailure: reason,
            ),
            CollectionCsvImportPreviewError() => (
              filename: filename,
              preview: null,
              parseFailure: null,
            ),
          },
      import: execute == null
          ? null
          : (p) async {
              switch (await execute!.execute(p)) {
                case final ExecuteCollectionCsvImportCompleted done:
                  collectionImportNotifier.value++;
                  return (done, null);
                case ExecuteCollectionCsvImportFailed(:final safeMessage):
                  return (null, safeMessage);
              }
            },
    );
  }
}

class WishlistCsvImportPreviewScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final preview =
        previewUseCase ?? const BuildWishlistCsvImportPreviewUseCase();
    var execute = executeUseCase;
    if (onPickFile == null && previewUseCase == null) {
      final repos = AppRepositoriesScope.maybeOf(context);
      if (repos != null) {
        execute = ExecuteWishlistCsvImportUseCase(
          wishlistRepository: repos.wishlist,
          jobRepository: repos.importExportJob,
          rowResultRepository: repos.importExportRowResult,
        );
      }
    }
    return CsvImportPreviewScreen<CsvWishlistImportPreview>(
      title: 'Import Wishlist from CSV',
      noun: 'wishlist',
      onPickFile: onPickFile,
      buildPreview: (filename, content) =>
          switch (preview.execute(filename: filename, content: content)) {
            WishlistCsvImportPreviewReady(:final filename, :final preview) => (
              filename: filename,
              preview: preview,
              parseFailure: null,
            ),
            WishlistCsvImportPreviewParseFailed(:final reason) => (
              filename: filename,
              preview: null,
              parseFailure: reason,
            ),
            WishlistCsvImportPreviewError() => (
              filename: filename,
              preview: null,
              parseFailure: null,
            ),
          },
      import: execute == null
          ? null
          : (p) async {
              switch (await execute!.execute(p)) {
                case final ExecuteWishlistCsvImportCompleted done:
                  wishlistImportNotifier.value++;
                  return (done, null);
                case ExecuteWishlistCsvImportFailed(:final safeMessage):
                  return (null, safeMessage);
              }
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

class _Idle extends _State {
  const _Idle();
}

class _Preview extends _State {
  const _Preview({required this.filename, required this.preview});
  final String filename;
  final CsvImportPreview preview;
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
  final CsvImportDone result;
}

// ---------------------------------------------------------------------------
// Shared screen
// ---------------------------------------------------------------------------

/// Preview build outcome: a preview, a parse-failure reason, or neither
/// (unexpected error).
typedef CsvImportBuild<P> = ({
  String filename,
  P? preview,
  String? parseFailure,
});

/// Import outcome: the finished import, or a safe user-facing error message.
typedef CsvImportOutcome = (CsvImportDone?, String?);

class CsvImportPreviewScreen<P extends CsvImportPreview>
    extends StatefulWidget {
  const CsvImportPreviewScreen({
    super.key,
    required this.title,
    required this.noun,
    required this.buildPreview,
    this.import,
    this.onPickFile,
  });

  final String title;

  /// "collection" or "wishlist", used in body copy.
  final String noun;

  final CsvImportBuild<P> Function(String filename, String content)
  buildPreview;

  /// Null disables the confirm action.
  final Future<CsvImportOutcome> Function(P preview)? import;

  final Future<CsvPickedFile?> Function()? onPickFile;

  @override
  State<CsvImportPreviewScreen<P>> createState() =>
      _CsvImportPreviewScreenState<P>();
}

class _CsvImportPreviewScreenState<P extends CsvImportPreview>
    extends State<CsvImportPreviewScreen<P>> {
  _State _state = const _Idle();

  Future<void> _pickAndPreview() async {
    final pick = widget.onPickFile ?? const CsvFilePickerService().pick;
    final file = await pick();
    if (!mounted) return;
    if (file == null) return;

    final built = widget.buildPreview(file.filename, file.content);
    setState(() {
      _state = switch (built) {
        (:final filename, preview: final P preview, parseFailure: _) =>
          _Preview(filename: filename, preview: preview),
        (filename: _, preview: null, :final String parseFailure) =>
          _ParseFailed(parseFailure),
        _ => const _Error(),
      };
    });
  }

  Future<void> _executeImport(P preview) async {
    final import = widget.import;
    if (import == null) return;
    setState(() => _state = const _Importing());
    final (done, error) = await import(preview);
    if (!mounted) return;
    if (done != null) {
      setState(() => _state = _Done(done));
    } else {
      setState(() => _state = _Preview(filename: '', preview: preview));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Import failed')));
    }
  }

  void _reset() => setState(() => _state = const _Idle());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: switch (_state) {
        _Idle() => _IdleBody(noun: widget.noun, onPickFile: _pickAndPreview),
        _Preview(:final filename, :final preview) => _PreviewBody(
          filename: filename,
          preview: preview,
          onPickDifferentFile: _reset,
          onConfirm: widget.import != null && preview.validCount > 0
              ? () => _executeImport(preview as P)
              : null,
        ),
        _ParseFailed(:final reason) => _ParseFailedBody(
          reason: reason,
          onTryAgain: _reset,
        ),
        _Error() => _ErrorBody(onTryAgain: _reset),
        _Importing() => _ImportingBody(noun: widget.noun),
        _Done(:final result) => _DoneBody(
          noun: widget.noun,
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
  const _IdleBody({required this.noun, required this.onPickFile});

  final String noun;
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
                'Choose a CSV file exported from Cratewise or Discogs to preview your $noun import.',
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
  final CsvImportPreview preview;
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
  final CsvImportPreview preview;

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
  const _ImportingBody({required this.noun});

  final String noun;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Saving your $noun…',
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
    required this.noun,
    required this.result,
    required this.onDone,
  });

  final String noun;

  final CsvImportDone result;
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
                          label: 'Added to $noun',
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

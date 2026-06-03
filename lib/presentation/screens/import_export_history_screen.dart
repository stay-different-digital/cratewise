import 'package:flutter/material.dart';

import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_import_export_job_repository.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _HistoryState {
  const _HistoryState();
}

class _Loading extends _HistoryState {
  const _Loading();
}

class _Loaded extends _HistoryState {
  const _Loaded(this.jobs);
  final List<ImportExportJob> jobs;
}

class _LoadError extends _HistoryState {
  const _LoadError();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ImportExportHistoryScreen extends StatefulWidget {
  const ImportExportHistoryScreen({super.key, this.repository});

  /// Injected only for testing. Production code passes null.
  final ImportExportJobRepository? repository;

  @override
  State<ImportExportHistoryScreen> createState() =>
      _ImportExportHistoryScreenState();
}

class _ImportExportHistoryScreenState
    extends State<ImportExportHistoryScreen> {
  late final ImportExportJobRepository _repository;
  AppDatabase? _ownedDb;
  _HistoryState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repository = widget.repository!;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _repository = LocalImportExportJobRepository(db);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final jobs = await _repository.getRecent();
      if (!mounted) return;
      setState(() => _state = _Loaded(jobs));
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
      appBar: AppBar(title: const Text('Import & Export History')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Loaded(:final jobs) when jobs.isEmpty => const _EmptyState(),
        _Loaded(:final jobs) => _HistoryList(jobs: jobs),
        _LoadError() => _ErrorState(onRetry: _load),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.jobs});

  final List<ImportExportJob> jobs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _JobCard(job: jobs[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Job card
// ---------------------------------------------------------------------------

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final ImportExportJob job;

  static String _statusLabel(ImportExportStatus status) => switch (status) {
        ImportExportStatus.completed => 'Completed',
        ImportExportStatus.completedWithErrors => 'Completed with errors',
        ImportExportStatus.failed => 'Failed',
        ImportExportStatus.running => 'Running',
        ImportExportStatus.idle => 'Idle',
        ImportExportStatus.validating => 'Validating',
        ImportExportStatus.previewing => 'Previewing',
        ImportExportStatus.cancelled => 'Cancelled',
      };

  static ({Color fg, Color bg}) _statusColors(
    ImportExportStatus status,
    ColorScheme cs,
  ) =>
      switch (status) {
        ImportExportStatus.completed => (
            fg: cs.tertiary,
            bg: cs.tertiaryContainer,
          ),
        ImportExportStatus.completedWithErrors => (
            fg: cs.secondary,
            bg: cs.secondaryContainer,
          ),
        ImportExportStatus.failed => (
            fg: cs.error,
            bg: cs.errorContainer,
          ),
        ImportExportStatus.running => (
            fg: cs.primary,
            bg: cs.primaryContainer,
          ),
        _ => (
            fg: cs.onSurfaceVariant,
            bg: cs.surfaceContainerHighest,
          ),
      };

  static String _validLabel(ImportExportJobType jobType) => switch (jobType) {
        ImportExportJobType.importCollectionFromDiscogs => 'Added',
        ImportExportJobType.importWishlistFromDiscogs => 'Added',
        ImportExportJobType.csvCollectionImport => 'Added',
        ImportExportJobType.csvWishlistImport => 'Added',
        _ => 'Exported',
      };

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _statusColors(job.status, theme.colorScheme);
    final hasCounts = job.validItems != null ||
        job.skippedItems != null ||
        job.failedItems != null;

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
                    job.jobType.label,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(job.status),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colors.fg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'From',
              value: '${job.source} → ${job.target}',
            ),
            if (hasCounts) ...[
              _InfoRow(
                label: _validLabel(job.jobType),
                value: '${job.validItems ?? 0}',
              ),
              _InfoRow(
                label: 'Skipped',
                value: '${job.skippedItems ?? 0}',
              ),
              _InfoRow(
                label: 'Failed',
                value: '${job.failedItems ?? 0}',
              ),
            ],
            _InfoRow(
              label: 'Started',
              value: _formatDate(job.createdAt),
            ),
            if (job.safeErrorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                job.safeErrorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info row
// ---------------------------------------------------------------------------

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
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

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
              Icons.history_outlined,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Import and export jobs will appear here.',
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

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

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
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load history from device storage.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

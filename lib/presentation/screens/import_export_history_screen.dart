import 'package:flutter/material.dart';

import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_status.dart';
import '../../app/app_repositories.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../shared/utils/date_format_utils.dart';

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
  const _Loaded({
    required this.jobs,
    required this.total,
    this.isLoadingMore = false,
  });

  final List<ImportExportJob> jobs;
  final int total;
  final bool isLoadingMore;

  _Loaded copyWith({
    List<ImportExportJob>? jobs,
    int? total,
    bool? isLoadingMore,
  }) => _Loaded(
    jobs: jobs ?? this.jobs,
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
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

class _ImportExportHistoryScreenState extends State<ImportExportHistoryScreen> {
  late final ImportExportJobRepository _repository;
  _HistoryState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? AppRepositoriesScope.of(context).importExportJob;
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final (total, jobs) = await (
        _repository.count(),
        _repository.getRecent(),
      ).wait;
      if (!mounted) return;
      setState(() => _state = _Loaded(jobs: jobs, total: total));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _LoadError());
    }
  }

  Future<void> _loadMore() async {
    final loaded = _state;
    if (loaded is! _Loaded) return;
    setState(() => _state = loaded.copyWith(isLoadingMore: true));
    try {
      final more = await _repository.getRecent(
        limit: 20,
        offset: loaded.jobs.length,
      );
      if (!mounted) return;
      setState(
        () => _state = loaded.copyWith(
          jobs: [...loaded.jobs, ...more],
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = loaded.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onDelete(ImportExportJob job) async {
    final loaded = _state;
    if (loaded is! _Loaded) return;

    final index = loaded.jobs.indexWhere((j) => j.id == job.id);
    if (index < 0) return;

    final updatedJobs = List<ImportExportJob>.from(loaded.jobs)
      ..removeAt(index);
    setState(
      () =>
          _state = loaded.copyWith(jobs: updatedJobs, total: loaded.total - 1),
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await messenger
        .showSnackBar(
          SnackBar(
            content: const Text('Entry deleted'),
            action: SnackBarAction(label: 'Undo', onPressed: () {}),
          ),
        )
        .closed;

    if (result == SnackBarClosedReason.action) {
      if (!mounted) return;
      final current = _state;
      if (current is! _Loaded) return;
      final restored = List<ImportExportJob>.from(current.jobs);
      restored.insert(index.clamp(0, restored.length), job);
      setState(
        () =>
            _state = current.copyWith(jobs: restored, total: current.total + 1),
      );
    } else {
      await _repository.remove(job.id);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import & Export History')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _Loaded(:final jobs) when jobs.isEmpty => const _EmptyState(),
        _Loaded(:final jobs, :final total, :final isLoadingMore) =>
          _HistoryList(
            jobs: jobs,
            total: total,
            isLoadingMore: isLoadingMore,
            onLoadMore: _loadMore,
            onDelete: _onDelete,
          ),
        _LoadError() => _ErrorState(onRetry: _load),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.jobs,
    required this.total,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onDelete,
  });

  final List<ImportExportJob> jobs;
  final int total;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final void Function(ImportExportJob) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMore = jobs.length < total;
    final hasFooter = hasMore || isLoadingMore;
    final itemCount = 1 + jobs.length + (hasFooter ? 1 : 0);

    return SafeArea(
      top: false,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Showing ${jobs.length} of $total jobs',
                key: const Key('history-count'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          if (index <= jobs.length) {
            final job = jobs[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey(job.id),
                direction: DismissDirection.endToStart,
                background: const _DeleteBackground(),
                onDismissed: (_) => onDelete(job),
                child: _JobCard(job: job),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator(
                      key: Key('load-more-indicator'),
                    )
                  : FilledButton.tonal(
                      key: const Key('load-more-button'),
                      onPressed: onLoadMore,
                      child: const Text('Load more'),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete background
// ---------------------------------------------------------------------------

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(Icons.delete_outline, color: cs.onError),
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
  ) {
    final isDark = cs.brightness == Brightness.dark;
    // Material 3 has no "warning" semantic token; use a brightness-aware amber
    // so completedWithErrors is visually distinct from both completed (tertiary)
    // and failed (error) in every theme.
    final warningFg = isDark
        ? const Color(0xFFFFD966)
        : const Color(0xFF7A4F00);
    final warningBg = isDark
        ? const Color(0xFF3D2B00)
        : const Color(0xFFFFF0C7);
    return switch (status) {
      ImportExportStatus.completed => (
        fg: cs.tertiary,
        bg: cs.tertiaryContainer,
      ),
      ImportExportStatus.completedWithErrors => (fg: warningFg, bg: warningBg),
      ImportExportStatus.failed => (fg: cs.error, bg: cs.errorContainer),
      ImportExportStatus.cancelled => (fg: cs.error, bg: cs.errorContainer),
      ImportExportStatus.running => (fg: cs.primary, bg: cs.primaryContainer),
      _ => (fg: cs.onSurfaceVariant, bg: cs.surfaceContainerHighest),
    };
  }

  static String _validLabel(ImportExportJobType jobType) => switch (jobType) {
    ImportExportJobType.importCollectionFromDiscogs => 'Added',
    ImportExportJobType.importWishlistFromDiscogs => 'Added',
    ImportExportJobType.csvCollectionImport => 'Added',
    ImportExportJobType.csvWishlistImport => 'Added',
    ImportExportJobType.autoSyncWithDiscogs => 'Sent',
    _ => 'Exported',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final colors = _statusColors(job.status, theme.colorScheme);
    final hasCounts =
        job.validItems != null ||
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
                  key: const Key('status-chip'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(job.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.fg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Route', value: '${job.source} → ${job.target}'),
            if (hasCounts) ...[
              _InfoRow(
                label: _validLabel(job.jobType),
                value: '${job.validItems ?? 0}',
              ),
              _InfoRow(label: 'Skipped', value: '${job.skippedItems ?? 0}'),
              _InfoRow(label: 'Failed', value: '${job.failedItems ?? 0}'),
            ],
            _InfoRow(
              label: 'Started',
              value: formatDateTime(job.createdAt, locale),
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
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
              Text('No history yet', style: theme.textTheme.titleMedium),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
      ),
    );
  }
}

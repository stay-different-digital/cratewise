import 'package:flutter/material.dart';

import '../../app/app_repositories.dart';
import '../../domain/models/collection_stats.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/collection_repository.dart';

class CollectionStatisticsScreen extends StatefulWidget {
  const CollectionStatisticsScreen({
    super.key,
    this.repository,
    this.metadataRepository,
  });

  final CollectionRepository? repository;
  final CachedReleaseMetadataRepository? metadataRepository;

  @override
  State<CollectionStatisticsScreen> createState() =>
      _CollectionStatisticsScreenState();
}

class _CollectionStatisticsScreenState
    extends State<CollectionStatisticsScreen> {
  late final Future<CollectionStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    final repo =
        widget.repository ?? AppRepositoriesScope.of(context).collection;
    final metaRepo =
        widget.metadataRepository ?? AppRepositoriesScope.of(context).cachedRelease;
    final itemsFuture = repo.getAll();
    final metaFuture = metaRepo.getAll();
    _statsFuture = () async {
      return CollectionStats.from(
        await itemsFuture,
        metadata: await metaFuture,
      );
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection statistics')),
      body: FutureBuilder<CollectionStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Could not load statistics.'),
              ),
            );
          }
          return _StatsBody(stats: snapshot.data!);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final CollectionStats stats;

  static const _kWideBreakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= _kWideBreakpoint
          ? _buildWide(context)
          : _buildNarrow(context),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OverviewSection(stats: stats),
        const SizedBox(height: 12),
        _DistributionSection(title: 'By decade', data: stats.byDecade),
        const SizedBox(height: 12),
        _DistributionSection(title: 'By format', data: stats.byFormat),
        const SizedBox(height: 12),
        _DistributionSection(title: 'By genre', data: stats.byGenre),
        const SizedBox(height: 12),
        _DistributionSection(title: 'By style', data: stats.byStyle),
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _OverviewSection(stats: stats),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DistributionSection(
                  title: 'By decade',
                  data: stats.byDecade,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DistributionSection(
                  title: 'By format',
                  data: stats.byFormat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DistributionSection(
                  title: 'By genre',
                  data: stats.byGenre,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DistributionSection(
                  title: 'By style',
                  data: stats.byStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.stats});

  final CollectionStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(
                  key: const Key('stat-total'),
                  label: 'Records',
                  value: '${stats.totalItems}',
                ),
                _StatChip(
                  key: const Key('stat-artists'),
                  label: 'Artists',
                  value: '${stats.uniqueArtists}',
                ),
                _StatChip(
                  key: const Key('stat-labels'),
                  label: 'Labels',
                  value: '${stats.uniqueLabels}',
                ),
                _StatChip(
                  key: const Key('stat-missing-cover'),
                  label: 'No cover',
                  value: '${stats.missingCover}',
                ),
                _StatChip(
                  key: const Key('stat-missing-year'),
                  label: 'No year',
                  value: '${stats.missingYear}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Distribution
// ---------------------------------------------------------------------------

class _DistributionSection extends StatelessWidget {
  const _DistributionSection({required this.title, required this.data});

  final String title;
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxCount = data.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final entry in data.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DistributionRow(
                  label: entry.key,
                  count: entry.value,
                  maxCount: maxCount,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.count,
    required this.maxCount,
  });

  final String label;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: count / maxCount,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

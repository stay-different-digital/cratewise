import 'package:flutter/material.dart';

import '../../domain/models/collection_item.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _DetailState {
  const _DetailState();
}

class _Loading extends _DetailState {
  const _Loading();
}

class _Loaded extends _DetailState {
  const _Loaded(this.item);
  final CollectionItem item;
}

class _NotFound extends _DetailState {
  const _NotFound();
}

class _DetailError extends _DetailState {
  const _DetailError();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.itemId,
    this.repository,
  });

  final String itemId;
  final CollectionRepository? repository;

  @override
  State<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late final CollectionRepository _repository;
  AppDatabase? _ownedDb;
  _DetailState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repository = widget.repository!;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _repository = LocalCollectionRepository(db);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final item = await _repository.getById(widget.itemId);
      if (!mounted) return;
      setState(
        () => _state = item != null ? _Loaded(item) : const _NotFound(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _DetailError());
    }
  }

  @override
  void dispose() {
    _ownedDb?.close();
    super.dispose();
  }

  Future<void> _showEditConditionsSheet(CollectionItem item) async {
    final updated = await showModalBottomSheet<CollectionItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _EditConditionsSheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conditions saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(
        title: Text(state is _Loaded ? state.item.title : 'Collection Item'),
        actions: state is _Loaded
            ? [
                IconButton(
                  key: const Key('edit-conditions-button'),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit conditions',
                  onPressed: () => _showEditConditionsSheet(state.item),
                ),
              ]
            : null,
      ),
      body: switch (state) {
        _Loading() => const Center(
            key: Key('collection-detail-loading'),
            child: CircularProgressIndicator(),
          ),
        _Loaded(:final item) => _CollectionDetailBody(item: item),
        _NotFound() => const _NotFoundBody(),
        _DetailError() => _ErrorBody(onRetry: _load),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Edit conditions sheet
// ---------------------------------------------------------------------------

class _EditConditionsSheet extends StatefulWidget {
  const _EditConditionsSheet({required this.item, required this.repository});

  final CollectionItem item;
  final CollectionRepository repository;

  @override
  State<_EditConditionsSheet> createState() => _EditConditionsSheetState();
}

class _EditConditionsSheetState extends State<_EditConditionsSheet> {
  late RecordCondition _media;
  late RecordCondition _sleeve;
  bool _saving = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _media = widget.item.mediaCondition;
    _sleeve = widget.item.sleeveCondition;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _hasError = false;
    });
    try {
      final updated = widget.item.copyWith(
        mediaCondition: _media,
        sleeveCondition: _sleeve,
        updatedAt: DateTime.now(),
      );
      await widget.repository.update(updated);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Conditions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          DropdownButtonFormField<RecordCondition>(
            key: const Key('media-condition-dropdown'),
            initialValue: _media,
            decoration: const InputDecoration(labelText: 'Media condition'),
            items: RecordCondition.values
                .map(
                  (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (v) {
                    if (v != null) setState(() => _media = v);
                  },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<RecordCondition>(
            key: const Key('sleeve-condition-dropdown'),
            initialValue: _sleeve,
            decoration: const InputDecoration(labelText: 'Sleeve condition'),
            items: RecordCondition.values
                .map(
                  (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (v) {
                    if (v != null) setState(() => _sleeve = v);
                  },
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not save conditions. Please try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-conditions-button'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail body
// ---------------------------------------------------------------------------

class _CollectionDetailBody extends StatelessWidget {
  const _CollectionDetailBody({required this.item});

  final CollectionItem item;

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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoverSection(item: item),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _TitleArtist(item: item),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _InfoRows(item: item),
          ),
          if (item.notes != null && item.notes!.isNotEmpty)
            _NotesSection(notes: item.notes!),
          if (item.tags.isNotEmpty) _TagsSection(tags: item.tags),
          _HistorySection(item: item),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.coverUrl != null
                      ? AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            item.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _coverPlaceholder(theme),
                          ),
                        )
                      : AspectRatio(
                          aspectRatio: 1,
                          child: _coverPlaceholder(theme),
                        ),
                ),
                const SizedBox(height: 20),
                _TitleArtist(item: item),
                const SizedBox(height: 16),
                _InfoRows(item: item),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.notes != null && item.notes!.isNotEmpty)
                  _NotesSection(notes: item.notes!),
                if (item.tags.isNotEmpty) _TagsSection(tags: item.tags),
                _HistorySection(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _coverPlaceholder(ThemeData theme) => ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.album,
          size: 72,
          color: theme.colorScheme.outlineVariant,
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (item.coverUrl == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: _coverPlaceholder(theme),
      );
    }
    return AspectRatio(
      aspectRatio: 1,
      child: Image.network(
        item.coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _coverPlaceholder(theme),
      ),
    );
  }
}

class _TitleArtist extends StatelessWidget {
  const _TitleArtist({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title.isEmpty ? '(Untitled)' : item.title,
          style: theme.textTheme.headlineSmall,
        ),
        if (item.artist.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.artist,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRows extends StatelessWidget {
  const _InfoRows({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final hasLabel = item.label != null && item.label!.isNotEmpty;
    final hasCatno = item.catno != null && item.catno!.isNotEmpty;
    final String? labelCatno;
    if (hasLabel && hasCatno) {
      labelCatno = '${item.label} — ${item.catno}';
    } else if (hasLabel) {
      labelCatno = item.label;
    } else if (hasCatno) {
      labelCatno = item.catno;
    } else {
      labelCatno = null;
    }

    return Column(
      children: [
        if (labelCatno != null) _InfoRow('Label', labelCatno),
        if (item.format != null && item.format!.isNotEmpty)
          _InfoRow('Format', item.format!),
        if (item.country != null && item.country!.isNotEmpty)
          _InfoRow('Country', item.country!),
        if (item.year != null) _InfoRow('Year', '${item.year}'),
        _InfoRow('Media', item.mediaCondition.label),
        _InfoRow('Sleeve', item.sleeveCondition.label),
        if (item.storageLocation != null && item.storageLocation!.isNotEmpty)
          _InfoRow('Location', item.storageLocation!),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Notes'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Tags'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags.map((t) => Chip(label: Text(t))).toList(),
          ),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _InfoRow('Added', _formatDate(item.createdAt)),
              _InfoRow('Updated', _formatDate(item.updatedAt)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error/empty states
// ---------------------------------------------------------------------------

class _NotFoundBody extends StatelessWidget {
  const _NotFoundBody();

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
              Icons.search_off,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('Item not found.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'This item may have been removed.',
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

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

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
              'Could not load this item.',
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

// ---------------------------------------------------------------------------
// Shared primitive widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatDate(DateTime dt) {
  final d = dt.toLocal();
  return '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

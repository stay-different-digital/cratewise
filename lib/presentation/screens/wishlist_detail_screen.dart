import 'package:flutter/material.dart';

import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_wishlist_repository.dart';

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
  final WishlistItem item;
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

class WishlistDetailScreen extends StatefulWidget {
  const WishlistDetailScreen({
    super.key,
    required this.itemId,
    this.repository,
  });

  final String itemId;
  final WishlistRepository? repository;

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  late final WishlistRepository _repository;
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
      _repository = LocalWishlistRepository(db);
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

  Future<void> _showEditPrioritySheet(WishlistItem item) async {
    final updated = await showModalBottomSheet<WishlistItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditPrioritySheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Priority saved.')),
      );
    }
  }

  Future<void> _showEditTargetPriceSheet(WishlistItem item) async {
    final updated = await showModalBottomSheet<WishlistItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _EditTargetPriceSheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target price saved.')),
      );
    }
  }

  Future<void> _showEditNotesSheet(WishlistItem item) async {
    final updated = await showModalBottomSheet<WishlistItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditNotesSheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(
        title: Text(state is _Loaded ? state.item.title : 'Wishlist Item'),
        actions: state is _Loaded
            ? [
                IconButton(
                  key: const Key('edit-priority-button'),
                  icon: const Icon(Icons.tune),
                  tooltip: 'Edit priority',
                  onPressed: () => _showEditPrioritySheet(state.item),
                ),
                IconButton(
                  key: const Key('edit-target-price-button'),
                  icon: const Icon(Icons.sell_outlined),
                  tooltip: 'Edit target price',
                  onPressed: () => _showEditTargetPriceSheet(state.item),
                ),
                IconButton(
                  key: const Key('edit-notes-button'),
                  icon: const Icon(Icons.edit_note),
                  tooltip: 'Edit notes',
                  onPressed: () => _showEditNotesSheet(state.item),
                ),
              ]
            : null,
      ),
      body: switch (state) {
        _Loading() => const Center(
            key: Key('wishlist-detail-loading'),
            child: CircularProgressIndicator(),
          ),
        _Loaded(:final item) => _WishlistDetailBody(item: item),
        _NotFound() => const _NotFoundBody(),
        _DetailError() => _ErrorBody(onRetry: _load),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Edit priority sheet
// ---------------------------------------------------------------------------

class _EditPrioritySheet extends StatefulWidget {
  const _EditPrioritySheet({required this.item, required this.repository});

  final WishlistItem item;
  final WishlistRepository repository;

  @override
  State<_EditPrioritySheet> createState() => _EditPrioritySheetState();
}

class _EditPrioritySheetState extends State<_EditPrioritySheet> {
  late WishlistPriority _priority;
  bool _saving = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _priority = widget.item.priority;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _hasError = false;
    });
    try {
      final updated = widget.item.copyWith(
        priority: _priority,
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
          Text('Edit Priority', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          DropdownButtonFormField<WishlistPriority>(
            key: const Key('priority-dropdown'),
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: WishlistPriority.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: _saving
                ? null
                : (v) {
                    if (v != null) setState(() => _priority = v);
                  },
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not save priority. Please try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-priority-button'),
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
// Edit target price sheet
// ---------------------------------------------------------------------------

class _EditTargetPriceSheet extends StatefulWidget {
  const _EditTargetPriceSheet({required this.item, required this.repository});

  final WishlistItem item;
  final WishlistRepository repository;

  @override
  State<_EditTargetPriceSheet> createState() => _EditTargetPriceSheetState();
}

class _EditTargetPriceSheetState extends State<_EditTargetPriceSheet> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _hasError = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.targetPrice?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    double? parsed;
    if (text.isNotEmpty) {
      parsed = double.tryParse(text);
      if (parsed == null) {
        setState(() =>
            _validationError = 'Enter a valid price, or leave empty to clear.');
        return;
      }
    }
    setState(() {
      _saving = true;
      _hasError = false;
      _validationError = null;
    });
    try {
      final updated = text.isEmpty
          ? widget.item.copyWith(
              clearTargetPrice: true,
              updatedAt: DateTime.now(),
            )
          : widget.item.copyWith(
              targetPrice: parsed,
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
          Text('Edit Target Price', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('target-price-text-field'),
            controller: _controller,
            enabled: !_saving,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Target price',
              hintText: 'Leave empty to clear',
              errorText: _validationError,
            ),
            onFieldSubmitted: (_) => _save(),
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not save target price. Please try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-target-price-button'),
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
// Edit notes sheet
// ---------------------------------------------------------------------------

class _EditNotesSheet extends StatefulWidget {
  const _EditNotesSheet({required this.item, required this.repository});

  final WishlistItem item;
  final WishlistRepository repository;

  @override
  State<_EditNotesSheet> createState() => _EditNotesSheetState();
}

class _EditNotesSheetState extends State<_EditNotesSheet> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _hasError = false;
    });
    try {
      final text = _controller.text.trim();
      final updated = widget.item.copyWith(
        notes: text,
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
          Text('Edit Notes', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('notes-text-field'),
            controller: _controller,
            enabled: !_saving,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not save notes. Please try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-notes-button'),
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

class _WishlistDetailBody extends StatelessWidget {
  const _WishlistDetailBody({required this.item});

  final WishlistItem item;

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
                            errorBuilder: (_, _, _) =>
                                _coverPlaceholder(theme),
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
                _HistorySection(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _coverPlaceholder(ThemeData theme) => Semantics(
      label: 'No cover image',
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.album,
                size: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No cover',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.item});

  final WishlistItem item;

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

  final WishlistItem item;

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

  final WishlistItem item;

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

    final targetPriceText = item.targetPrice != null
        ? item.targetPrice!.toStringAsFixed(2)
        : 'Not set';

    return Column(
      children: [
        if (labelCatno != null) _InfoRow('Label', labelCatno),
        if (item.format != null && item.format!.isNotEmpty)
          _InfoRow('Format', item.format!),
        if (item.country != null && item.country!.isNotEmpty)
          _InfoRow('Country', item.country!),
        if (item.year != null) _InfoRow('Year', '${item.year}'),
        _InfoRow('Priority', item.priority.label),
        _InfoRow('Target price', targetPriceText),
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

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.item});

  final WishlistItem item;

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
              key: const Key('wishlist-detail-retry-button'),
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
            width: 88,
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

import 'dart:io';

import 'package:flutter/material.dart';

import '../../application/services/discogs_release_detail_service.dart';
import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_cached_release_metadata_repository.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../shared/route_observer.dart';
import '../../shared/utils/date_format_utils.dart';

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
// Actions
// ---------------------------------------------------------------------------

enum _OverflowAction { remove }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.itemId,
    this.repository,
    this.thumbnailRepository,
    this.releaseDetailService,
    this.cacheRepository,
  });

  final String itemId;
  final CollectionRepository? repository;
  final ThumbnailRepository? thumbnailRepository;
  final DiscogsReleaseDetailService? releaseDetailService;
  final CachedReleaseMetadataRepository? cacheRepository;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen>
    with RouteAware {
  late final CollectionRepository _repository;
  late final ThumbnailRepository _thumbnailRepository;
  CachedReleaseMetadataRepository? _cacheRepository;
  DiscogsReleaseDetailService? _detailService;
  AppDatabase? _ownedDb;
  _DetailState _state = const _Loading();
  ReleaseDetail? _releaseDetail;

  @override
  void initState() {
    super.initState();
    _thumbnailRepository =
        widget.thumbnailRepository ?? LocalThumbnailRepository();
    if (widget.repository != null) {
      _repository = widget.repository!;
      _cacheRepository = widget.cacheRepository;
      _detailService = widget.releaseDetailService;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _repository = LocalCollectionRepository(db);
      _cacheRepository =
          widget.cacheRepository ?? LocalCachedReleaseMetadataRepository(db);
      _detailService =
          widget.releaseDetailService ??
          DiscogsReleaseDetailService(cacheRepository: _cacheRepository);
    }
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => _refresh();

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final item = await _repository.getById(widget.itemId);
      if (!mounted) return;
      setState(() => _state = item != null ? _Loaded(item) : const _NotFound());
      if (item != null) _loadReleaseDetail(item.discogsReleaseId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _DetailError());
    }
  }

  /// Loads Discogs release details (label, genres, tracklist, …) for the
  /// item: cache first (no network, no API quota), live fetch only when the
  /// release was never cached. Failures are silent — the local item view
  /// stands on its own without these details.
  Future<void> _loadReleaseDetail(int releaseId) async {
    if (_releaseDetail?.id == releaseId) return;
    try {
      final cached = await _cacheRepository?.getByReleaseId(releaseId);
      if (cached != null) {
        if (!mounted) return;
        setState(() => _releaseDetail = _cachedToDetail(cached));
        return;
      }
      final service = _detailService;
      if (service == null) return;
      final detail = await service.fetchDetail(releaseId);
      if (!mounted) return;
      setState(() => _releaseDetail = detail);
    } catch (_) {
      // No token, offline, or fetch error: keep the plain local view.
    }
  }

  Future<void> _refresh() async {
    try {
      final item = await _repository.getById(widget.itemId);
      if (!mounted) return;
      setState(() => _state = item != null ? _Loaded(item) : const _NotFound());
      if (item != null) _loadReleaseDetail(item.discogsReleaseId);
    } catch (_) {
      if (!mounted) return;
      if (_state is _Loaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh. Please try again.')),
        );
      } else {
        setState(() => _state = const _DetailError());
      }
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _ownedDb?.close();
    super.dispose();
  }

  Future<void> _showEditTagsSheet(CollectionItem item) async {
    final updated = await showModalBottomSheet<CollectionItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditTagsSheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tags saved.')));
    }
  }

  Future<void> _showEditNotesSheet(CollectionItem item) async {
    final updated = await showModalBottomSheet<CollectionItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditNotesSheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notes saved.')));
    }
  }

  Future<void> _confirmRemove(CollectionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Cratewise?'),
        content: const Text(
          'This removes the item from your Cratewise collection. '
          'Your Discogs collection is not affected.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-remove-button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm-remove-button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _removeItem(item);
    }
  }

  Future<void> _removeItem(CollectionItem item) async {
    try {
      await _repository.remove(item.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove item. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showEditStorageLocationSheet(CollectionItem item) async {
    final updated = await showModalBottomSheet<CollectionItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _EditStorageLocationSheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Storage location saved.')));
    }
  }

  Future<void> _showEditConditionsSheet(CollectionItem item) async {
    final updated = await showModalBottomSheet<CollectionItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditConditionsSheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conditions saved.')));
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
                IconButton(
                  key: const Key('edit-notes-button'),
                  icon: const Icon(Icons.edit_note),
                  tooltip: 'Edit notes',
                  onPressed: () => _showEditNotesSheet(state.item),
                ),
                IconButton(
                  key: const Key('edit-tags-button'),
                  icon: const Icon(Icons.label_outlined),
                  tooltip: 'Edit tags',
                  onPressed: () => _showEditTagsSheet(state.item),
                ),
                IconButton(
                  key: const Key('edit-storage-location-button'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  tooltip: 'Edit storage location',
                  onPressed: () => _showEditStorageLocationSheet(state.item),
                ),
                PopupMenuButton<_OverflowAction>(
                  key: const Key('detail-overflow-menu'),
                  onSelected: (action) {
                    if (action == _OverflowAction.remove) {
                      _confirmRemove(state.item);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _OverflowAction.remove,
                      child: Text('Remove from Cratewise'),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: switch (state) {
        _Loading() => const Center(
          key: Key('collection-detail-loading'),
          child: CircularProgressIndicator(),
        ),
        _Loaded(:final item) => RefreshIndicator(
          onRefresh: _refresh,
          child: _CollectionDetailBody(
            item: item,
            releaseDetail: _releaseDetail,
            thumbnailRepository: _thumbnailRepository,
          ),
        ),
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
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
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
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
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
// Edit storage location sheet
// ---------------------------------------------------------------------------

class _EditStorageLocationSheet extends StatefulWidget {
  const _EditStorageLocationSheet({
    required this.item,
    required this.repository,
  });

  final CollectionItem item;
  final CollectionRepository repository;

  @override
  State<_EditStorageLocationSheet> createState() =>
      _EditStorageLocationSheetState();
}

class _EditStorageLocationSheetState extends State<_EditStorageLocationSheet> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.storageLocation ?? '',
    );
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
        storageLocation: text,
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
          Text('Edit Storage Location', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('storage-location-text-field'),
            controller: _controller,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Storage location'),
            onFieldSubmitted: (_) => _save(),
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not save storage location. Please try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-storage-location-button'),
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
// Edit tags sheet
// ---------------------------------------------------------------------------

class _EditTagsSheet extends StatefulWidget {
  const _EditTagsSheet({required this.item, required this.repository});

  final CollectionItem item;
  final CollectionRepository repository;

  @override
  State<_EditTagsSheet> createState() => _EditTagsSheetState();
}

class _EditTagsSheetState extends State<_EditTagsSheet> {
  late List<String> _tags;
  late final TextEditingController _tagController;
  bool _saving = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.item.tags);
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;
    if (_tags.any((t) => t.toLowerCase() == tag.toLowerCase())) return;
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _hasError = false;
    });
    try {
      final updated = widget.item.copyWith(
        tags: List<String>.from(_tags),
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
          Text('Edit Tags', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tag in _tags)
                  InputChip(
                    key: Key('tag-chip-$tag'),
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: _saving ? null : () => _removeTag(tag),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('tag-input-field'),
                  controller: _tagController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(labelText: 'Add a tag'),
                  onFieldSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('add-tag-button'),
                icon: const Icon(Icons.add),
                tooltip: 'Add tag',
                onPressed: _saving ? null : _addTag,
              ),
            ],
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not save tags. Please try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-tags-button'),
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

  final CollectionItem item;
  final CollectionRepository repository;

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
              labelText: 'Personal notes',
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

class _CollectionDetailBody extends StatelessWidget {
  const _CollectionDetailBody({
    required this.item,
    required this.thumbnailRepository,
    this.releaseDetail,
  });

  final CollectionItem item;
  final ReleaseDetail? releaseDetail;
  final ThumbnailRepository thumbnailRepository;

  static const _kWideBreakpoint = 700.0;

  bool get _hasReleaseNotes =>
      releaseDetail?.notes != null && releaseDetail!.notes!.trim().isNotEmpty;

  bool get _hasTracklist => releaseDetail?.tracklist.isNotEmpty ?? false;

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
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CoverSection(item: item, thumbnailRepository: thumbnailRepository),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _TitleArtist(item: item),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _InfoRows(item: item, detail: releaseDetail),
            ),
            if (item.notes != null && item.notes!.isNotEmpty)
              _NotesSection(notes: item.notes!),
            if (item.tags.isNotEmpty) _TagsSection(tags: item.tags),
            if (_hasTracklist)
              _TracklistSection(tracks: releaseDetail!.tracklist),
            if (_hasReleaseNotes)
              _ReleaseNotesSection(notes: releaseDetail!.notes!),
            _HistorySection(item: item),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CachedCoverImage(
                    releaseId: item.discogsReleaseId,
                    borderRadius: BorderRadius.circular(8),
                    thumbnailRepository: thumbnailRepository,
                  ),
                  const SizedBox(height: 20),
                  _TitleArtist(item: item),
                  const SizedBox(height: 16),
                  _InfoRows(item: item, detail: releaseDetail),
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
                  if (_hasTracklist)
                    _TracklistSection(tracks: releaseDetail!.tracklist),
                  if (_hasReleaseNotes)
                    _ReleaseNotesSection(notes: releaseDetail!.notes!),
                  _HistorySection(item: item),
                ],
              ),
            ),
          ],
        ),
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
          Icon(Icons.album, size: 72, color: theme.colorScheme.outlineVariant),
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

class _CachedCoverImage extends StatefulWidget {
  const _CachedCoverImage({
    required this.releaseId,
    required this.borderRadius,
    this.thumbnailRepository,
  });

  final int releaseId;
  final BorderRadius borderRadius;
  final ThumbnailRepository? thumbnailRepository;

  @override
  State<_CachedCoverImage> createState() => _CachedCoverImageState();
}

class _CachedCoverImageState extends State<_CachedCoverImage> {
  late final Future<String?> _pathFuture;

  @override
  void initState() {
    super.initState();
    _pathFuture =
        widget.thumbnailRepository?.getLocalPath(widget.releaseId) ??
        Future<String?>.value();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: FutureBuilder<String?>(
          future: _pathFuture,
          builder: (_, snapshot) {
            final path = snapshot.data;
            if (path != null) {
              return Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _coverPlaceholder(theme),
              );
            }
            return _coverPlaceholder(theme);
          },
        ),
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.item, this.thumbnailRepository});

  final CollectionItem item;
  final ThumbnailRepository? thumbnailRepository;

  @override
  Widget build(BuildContext context) {
    return _CachedCoverImage(
      releaseId: item.discogsReleaseId,
      borderRadius: BorderRadius.zero,
      thumbnailRepository: thumbnailRepository,
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
  const _InfoRows({required this.item, this.detail});

  final CollectionItem item;

  /// Discogs release details. Preferred over the local item's sparse fields
  /// when available (imported items have no label/format/country locally).
  final ReleaseDetail? detail;

  String? _firstNonEmpty(String? a, String? b) {
    if (a != null && a.trim().isNotEmpty) return a;
    if (b != null && b.trim().isNotEmpty) return b;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = _firstNonEmpty(detail?.label, item.label);
    final catno = _firstNonEmpty(detail?.catno, item.catno);
    final String? labelCatno;
    if (label != null && catno != null) {
      labelCatno = '$label — $catno';
    } else {
      labelCatno = label ?? catno;
    }

    final format = _firstNonEmpty(detail?.format, item.format);
    final country = _firstNonEmpty(detail?.country, item.country);
    final year = detail?.year ?? item.year;
    final genres = detail?.genres ?? const <String>[];
    final styles = detail?.styles ?? const <String>[];

    return Column(
      children: [
        if (labelCatno != null) _InfoRow('Label', labelCatno),
        if (format != null) _InfoRow('Format', format),
        if (country != null) _InfoRow('Country', country),
        if (year != null) _InfoRow('Released', '$year'),
        if (genres.isNotEmpty) _InfoRow('Genre', genres.join(', ')),
        if (styles.isNotEmpty) _InfoRow('Style', styles.join(', ')),
        if (item.discogsReleaseId > 0)
          _InfoRow('Discogs ID', '${item.discogsReleaseId}'),
        _InfoRow('Media', item.mediaCondition.label),
        _InfoRow('Sleeve', item.sleeveCondition.label),
        if (item.storageLocation != null && item.storageLocation!.isNotEmpty)
          _InfoRow('Location', item.storageLocation!),
        _InfoRow('Status', _syncStatusLabel(item.syncStatus)),
      ],
    );
  }
}

class _TracklistSection extends StatelessWidget {
  const _TracklistSection({required this.tracks});

  final List<ReleaseTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Tracklist'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              for (final track in tracks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          track.position,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          track.title,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (track.duration.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          track.duration,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReleaseNotesSection extends StatelessWidget {
  const _ReleaseNotesSection({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Release Notes'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ),
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
    final locale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _InfoRow('Added', formatDate(item.createdAt, locale)),
              _InfoRow('Updated', formatDate(item.updatedAt, locale)),
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
              'This item may have been removed from your device storage.',
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
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load this item from device storage.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
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
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ReleaseDetail _cachedToDetail(CachedReleaseMetadata m) => ReleaseDetail(
  id: m.discogsReleaseId,
  title: m.title,
  artist: m.artist,
  label: m.label ?? '',
  catno: m.catno ?? '',
  format: m.format ?? '',
  country: m.country ?? '',
  year: m.year,
  genres: m.genres,
  styles: m.styles,
  tracklist: m.tracklist,
  notes: m.notes,
  coverUrl: m.coverUrl,
  identifiers: m.identifiers,
);

String _syncStatusLabel(SyncStatus status) => switch (status) {
  SyncStatus.localOnly => 'Saved on this device',
  SyncStatus.synced => 'Synced',
  SyncStatus.pending => 'Waiting to sync',
  SyncStatus.failed => 'Sync failed',
  SyncStatus.conflict => 'Needs review',
  SyncStatus.offline => 'Offline',
};

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import '../../application/services/discogs_release_detail_service.dart';
import '../../application/services/thumbnail_cache_service.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/models/pending_discogs_deletion.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../app/app_repositories.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../shared/route_observer.dart';
import '../../shared/utils/date_format_utils.dart';
import '../widgets/release_details_sections.dart';
import '../widgets/release_image_gallery.dart';

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

enum _OverflowAction { djFields, remove }

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
    this.thumbnailCacheService,
    this.deletionRepository,
  });

  final String itemId;
  final CollectionRepository? repository;
  final ThumbnailRepository? thumbnailRepository;
  final DiscogsReleaseDetailService? releaseDetailService;
  final CachedReleaseMetadataRepository? cacheRepository;
  final ThumbnailCacheService? thumbnailCacheService;
  final PendingDiscogsDeletionRepository? deletionRepository;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen>
    with RouteAware {
  late final CollectionRepository _repository;
  late final ThumbnailRepository _thumbnailRepository;
  late final ThumbnailCacheService _thumbnailCacheService;
  bool _ownsThumbService = false;
  CachedReleaseMetadataRepository? _cacheRepository;
  DiscogsReleaseDetailService? _detailService;
  PendingDiscogsDeletionRepository? _deletionRepository;
  _DetailState _state = const _Loading();
  ReleaseDetail? _releaseDetail;

  @override
  void initState() {
    super.initState();
    _thumbnailRepository =
        widget.thumbnailRepository ?? LocalThumbnailRepository();
    _ownsThumbService = widget.thumbnailCacheService == null;
    _thumbnailCacheService =
        widget.thumbnailCacheService ??
        ThumbnailCacheService(repository: _thumbnailRepository);
    if (widget.repository != null) {
      _repository = widget.repository!;
      _cacheRepository = widget.cacheRepository;
      _detailService = widget.releaseDetailService;
      _deletionRepository = widget.deletionRepository;
    } else {
      final repos = AppRepositoriesScope.of(context);
      _repository = repos.collection;
      _cacheRepository = widget.cacheRepository ?? repos.cachedRelease;
      _detailService =
          widget.releaseDetailService ??
          DiscogsReleaseDetailService(cacheRepository: _cacheRepository);
      _deletionRepository = widget.deletionRepository ?? repos.pendingDeletion;
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
  /// item via the standard cache-first path. Null result (offline + never
  /// cached, or no token) leaves the plain local view unchanged.
  Future<void> _loadReleaseDetail(int releaseId) async {
    if (_releaseDetail?.id == releaseId) return;
    final detail = await _detailService?.getCachedOrFetch(releaseId);
    if (!mounted || detail == null) return;
    setState(() => _releaseDetail = detail);
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
    if (_ownsThumbService) _thumbnailCacheService.close();
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
    // Only collection items we hold a Discogs instance id for can be removed
    // from Discogs; for those, offer opt-in propagation (US-72).
    final canRemoveFromDiscogs =
        _deletionRepository != null && item.discogsInstanceId != null;
    var alsoFromDiscogs = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Remove from Cratewise?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This removes the item from your Cratewise collection.',
              ),
              if (canRemoveFromDiscogs)
                CheckboxListTile(
                  key: const Key('also-remove-from-discogs-checkbox'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: alsoFromDiscogs,
                  onChanged: (v) =>
                      setLocalState(() => alsoFromDiscogs = v ?? false),
                  title: const Text('Also remove from my Discogs collection'),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Your Discogs collection is not affected.'),
                ),
            ],
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
      ),
    );
    if (confirmed == true && mounted) {
      await _removeItem(item, alsoFromDiscogs: alsoFromDiscogs);
    }
  }

  Future<void> _removeItem(
    CollectionItem item, {
    bool alsoFromDiscogs = false,
  }) async {
    try {
      if (alsoFromDiscogs && item.discogsInstanceId != null) {
        await _deletionRepository?.add(
          PendingDiscogsDeletion(
            id: const Uuid().v4(),
            entityType: DeletionEntityType.collection,
            discogsReleaseId: item.discogsReleaseId,
            discogsInstanceId: item.discogsInstanceId,
            artist: item.artist,
            title: item.title,
            createdAt: DateTime.now(),
          ),
        );
      }
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

  Future<void> _showEditDjFieldsSheet(CollectionItem item) async {
    final updated = await showModalBottomSheet<CollectionItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditDjFieldsSheet(item: item, repository: _repository),
    );
    if (updated != null && mounted) {
      setState(() => _state = _Loaded(updated));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('DJ fields saved.')));
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
                    switch (action) {
                      case _OverflowAction.djFields:
                        _showEditDjFieldsSheet(state.item);
                      case _OverflowAction.remove:
                        _confirmRemove(state.item);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      key: Key('edit-dj-fields-menu-item'),
                      value: _OverflowAction.djFields,
                      child: Text('Edit DJ fields'),
                    ),
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
            thumbnailCacheService: _thumbnailCacheService,
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
    required this.thumbnailCacheService,
    this.releaseDetail,
  });

  final CollectionItem item;
  final ReleaseDetail? releaseDetail;
  final ThumbnailCacheService thumbnailCacheService;

  String? get _coverUrl => item.coverUrl ?? releaseDetail?.coverUrl;

  Widget _imageWidget(BorderRadius borderRadius) {
    final urls = releaseDetail?.imageUrls ?? const [];
    if (urls.isNotEmpty) {
      return ReleaseImageGallery(imageUrls: urls, borderRadius: borderRadius);
    }
    return _CachedCoverImage(
      releaseId: item.discogsReleaseId,
      coverUrl: _coverUrl,
      borderRadius: borderRadius,
      thumbnailCacheService: thumbnailCacheService,
    );
  }

  static const _kWideBreakpoint = 700.0;

  bool get _hasReleaseNotes =>
      releaseDetail?.notes != null && releaseDetail!.notes!.trim().isNotEmpty;

  bool get _hasTracklist => releaseDetail?.tracklist.isNotEmpty ?? false;

  bool _hasDjFields(CollectionItem item) =>
      item.bpm != null ||
      item.musicalKey != null ||
      item.energyLevel != null ||
      item.gigCrates.isNotEmpty;

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
            _imageWidget(BorderRadius.zero),
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
            if (_hasDjFields(item)) _DjFieldsSection(item: item),
            if (_hasTracklist)
              ReleaseTracklistSection(tracks: releaseDetail!.tracklist),
            if (_hasReleaseNotes)
              ReleaseNotesSection(notes: releaseDetail!.notes!),
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
                  _imageWidget(BorderRadius.circular(8)),
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
                  if (_hasDjFields(item)) _DjFieldsSection(item: item),
                  if (_hasTracklist)
                    ReleaseTracklistSection(tracks: releaseDetail!.tracklist),
                  if (_hasReleaseNotes)
                    ReleaseNotesSection(notes: releaseDetail!.notes!),
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
    required this.thumbnailCacheService,
    this.coverUrl,
  });

  final int releaseId;
  final BorderRadius borderRadius;

  /// Source URL for the cover. Used only when no thumbnail is cached yet;
  /// the download is cached for offline use afterwards (US-75).
  final String? coverUrl;
  final ThumbnailCacheService thumbnailCacheService;

  @override
  State<_CachedCoverImage> createState() => _CachedCoverImageState();
}

class _CachedCoverImageState extends State<_CachedCoverImage> {
  late Future<String?> _pathFuture;

  @override
  void initState() {
    super.initState();
    _pathFuture = _resolve();
  }

  @override
  void didUpdateWidget(_CachedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The release details (US-74) can arrive after first build and supply a
    // cover URL the local item lacks — re-resolve when that happens.
    if (oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.releaseId != widget.releaseId) {
      setState(() {
        _pathFuture = _resolve();
      });
    }
  }

  Future<String?> _resolve() => widget.thumbnailCacheService.getOrFetch(
    widget.releaseId,
    widget.coverUrl,
  );

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

String _syncStatusLabel(SyncStatus status) => switch (status) {
  SyncStatus.localOnly => 'Saved on this device',
  SyncStatus.synced => 'Synced',
  SyncStatus.pending => 'Waiting to sync',
  SyncStatus.failed => 'Sync failed',
  SyncStatus.conflict => 'Needs review',
  SyncStatus.offline => 'Offline',
};

// ---------------------------------------------------------------------------
// DJ fields display section (US-121)
// ---------------------------------------------------------------------------

class _DjFieldsSection extends StatelessWidget {
  const _DjFieldsSection({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          Text('DJ', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (item.bpm != null)
            _DjRow(label: 'BPM', value: '${item.bpm}'),
          if (item.musicalKey != null)
            _DjRow(label: 'Key', value: item.musicalKey!.label),
          if (item.energyLevel != null)
            _DjRow(
              label: 'Energy',
              value: '★' * item.energyLevel! + '☆' * (5 - item.energyLevel!),
            ),
          if (item.gigCrates.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Gig crates', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.gigCrates
                  .map(
                    (c) => Chip(
                      key: Key('gig-crate-chip-$c'),
                      label: Text(c),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DjRow extends StatelessWidget {
  const _DjRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
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
// Edit DJ fields sheet (US-121)
// ---------------------------------------------------------------------------

class _EditDjFieldsSheet extends StatefulWidget {
  const _EditDjFieldsSheet({required this.item, required this.repository});

  final CollectionItem item;
  final CollectionRepository repository;

  @override
  State<_EditDjFieldsSheet> createState() => _EditDjFieldsSheetState();
}

class _EditDjFieldsSheetState extends State<_EditDjFieldsSheet> {
  late final TextEditingController _bpmController;
  MusicalKey? _musicalKey;
  int? _energyLevel;
  late List<String> _gigCrates;
  late final TextEditingController _crateController;
  bool _saving = false;
  bool _hasError = false;
  String? _bpmError;

  @override
  void initState() {
    super.initState();
    _bpmController = TextEditingController(
      text: widget.item.bpm?.toString() ?? '',
    );
    _musicalKey = widget.item.musicalKey;
    _energyLevel = widget.item.energyLevel;
    _gigCrates = List<String>.from(widget.item.gigCrates);
    _crateController = TextEditingController();
  }

  @override
  void dispose() {
    _bpmController.dispose();
    _crateController.dispose();
    super.dispose();
  }

  void _addCrate() {
    final crate = _crateController.text.trim();
    if (crate.isEmpty) return;
    if (_gigCrates.any((c) => c.toLowerCase() == crate.toLowerCase())) return;
    setState(() {
      _gigCrates.add(crate);
      _crateController.clear();
    });
  }

  void _removeCrate(String crate) {
    setState(() => _gigCrates.remove(crate));
  }

  Future<void> _save() async {
    final bpmText = _bpmController.text.trim();
    int? bpm;
    if (bpmText.isNotEmpty) {
      bpm = int.tryParse(bpmText);
      if (bpm == null || bpm < 20 || bpm > 300) {
        setState(() => _bpmError = 'Enter a BPM between 20 and 300');
        return;
      }
    }
    setState(() {
      _saving = true;
      _hasError = false;
      _bpmError = null;
    });
    try {
      final updated = CollectionItem(
        id: widget.item.id,
        discogsReleaseId: widget.item.discogsReleaseId,
        artist: widget.item.artist,
        title: widget.item.title,
        label: widget.item.label,
        catno: widget.item.catno,
        format: widget.item.format,
        country: widget.item.country,
        year: widget.item.year,
        coverUrl: widget.item.coverUrl,
        mediaCondition: widget.item.mediaCondition,
        sleeveCondition: widget.item.sleeveCondition,
        notes: widget.item.notes,
        tags: widget.item.tags,
        storageLocation: widget.item.storageLocation,
        syncStatus: widget.item.syncStatus,
        discogsInstanceId: widget.item.discogsInstanceId,
        createdAt: widget.item.createdAt,
        updatedAt: DateTime.now(),
        bpm: bpm,
        musicalKey: _musicalKey,
        energyLevel: _energyLevel,
        gigCrates: List<String>.from(_gigCrates),
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

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit DJ fields', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Stored locally only — not synced to Discogs.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('bpm-text-field'),
            controller: _bpmController,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'BPM',
              hintText: '20–300',
              errorText: _bpmError,
            ),
            onChanged: (_) {
              if (_bpmError != null) setState(() => _bpmError = null);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MusicalKey?>(
            key: const Key('musical-key-dropdown'),
            initialValue: _musicalKey,
            decoration: const InputDecoration(labelText: 'Musical key'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Not set')),
              ...MusicalKey.values.map(
                (k) => DropdownMenuItem(value: k, child: Text(k.label)),
              ),
            ],
            onChanged: _saving ? null : (v) => setState(() => _musicalKey = v),
          ),
          const SizedBox(height: 16),
          Text('Energy', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final level in [1, 2, 3, 4, 5])
                IconButton(
                  key: Key('energy-$level'),
                  icon: Icon(
                    (_energyLevel ?? 0) >= level
                        ? Icons.star
                        : Icons.star_border,
                    color: (_energyLevel ?? 0) >= level
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _saving
                      ? null
                      : () => setState(
                            () => _energyLevel =
                                _energyLevel == level ? null : level,
                          ),
                ),
              if (_energyLevel != null) ...[
                const SizedBox(width: 4),
                Text('$_energyLevel / 5', style: theme.textTheme.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text('Gig crates', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          if (_gigCrates.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final crate in _gigCrates)
                  InputChip(
                    key: Key('gig-crate-chip-$crate'),
                    label: Text(crate),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: _saving ? null : () => _removeCrate(crate),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('gig-crate-input-field'),
                  controller: _crateController,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Add a gig crate'),
                  onFieldSubmitted: (_) => _addCrate(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('add-gig-crate-button'),
                icon: const Icon(Icons.add),
                tooltip: 'Add gig crate',
                onPressed: _saving ? null : _addCrate,
              ),
            ],
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not save DJ fields. Please try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-dj-fields-button'),
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

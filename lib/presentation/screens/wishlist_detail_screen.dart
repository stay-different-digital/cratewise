import 'dart:io';

import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import '../../application/services/discogs_release_detail_service.dart';
import '../../application/services/thumbnail_cache_service.dart';
import '../../application/use_cases/add_to_collection_use_case.dart';
import '../../domain/models/pending_discogs_deletion.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../app/app_repositories.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../shared/utils/date_format_utils.dart';
import '../widgets/release_details_sections.dart';

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

enum _OverflowAction { remove }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class WishlistDetailScreen extends StatefulWidget {
  const WishlistDetailScreen({
    super.key,
    required this.itemId,
    this.repository,
    this.thumbnailRepository,
    this.thumbnailCacheService,
    this.releaseDetailService,
    this.cacheRepository,
    this.deletionRepository,
    this.addToCollectionUseCase,
  });

  final String itemId;
  final WishlistRepository? repository;
  final ThumbnailRepository? thumbnailRepository;
  final ThumbnailCacheService? thumbnailCacheService;
  final DiscogsReleaseDetailService? releaseDetailService;
  final CachedReleaseMetadataRepository? cacheRepository;
  final PendingDiscogsDeletionRepository? deletionRepository;
  final AddToCollectionUseCase? addToCollectionUseCase;

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  late final WishlistRepository _repository;
  late final ThumbnailRepository _thumbnailRepository;
  late final ThumbnailCacheService _thumbnailCacheService;
  bool _ownsThumbService = false;
  DiscogsReleaseDetailService? _detailService;
  PendingDiscogsDeletionRepository? _deletionRepository;
  AddToCollectionUseCase? _addToCollectionUseCase;
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
      _detailService = widget.releaseDetailService;
      _deletionRepository = widget.deletionRepository;
      _addToCollectionUseCase = widget.addToCollectionUseCase;
    } else {
      final repos = AppRepositoriesScope.of(context);
      _repository = repos.wishlist;
      _detailService =
          widget.releaseDetailService ??
          DiscogsReleaseDetailService(
            cacheRepository: widget.cacheRepository ?? repos.cachedRelease,
          );
      _deletionRepository = widget.deletionRepository ?? repos.pendingDeletion;
      _addToCollectionUseCase =
          widget.addToCollectionUseCase ??
          AddToCollectionUseCase(repos.collection);
    }
    _load();
  }

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

  /// Loads Discogs release details via the standard cache-first path
  /// (US-76). Null result leaves the plain local view unchanged.
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
    if (_ownsThumbService) _thumbnailCacheService.close();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Priority saved.')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Target price saved.')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notes saved.')));
    }
  }

  Future<void> _confirmRemove(WishlistItem item) async {
    // A wantlist entry can be removed from Discogs by release id (no instance
    // id needed) when it is linked there; offer opt-in propagation (US-72).
    final canRemoveFromDiscogs =
        _deletionRepository != null && item.syncStatus == SyncStatus.synced;
    var alsoFromDiscogs = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Remove from wishlist?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This removes the item from your Cratewise wishlist.'),
              if (canRemoveFromDiscogs)
                CheckboxListTile(
                  key: const Key('also-remove-from-discogs-checkbox'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: alsoFromDiscogs,
                  onChanged: (v) =>
                      setLocalState(() => alsoFromDiscogs = v ?? false),
                  title: const Text('Also remove from my Discogs wantlist'),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Your Discogs account is not affected.'),
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
    WishlistItem item, {
    bool alsoFromDiscogs = false,
  }) async {
    try {
      if (alsoFromDiscogs && item.syncStatus == SyncStatus.synced) {
        await _deletionRepository?.add(
          PendingDiscogsDeletion(
            id: const Uuid().v4(),
            entityType: DeletionEntityType.wishlist,
            discogsReleaseId: item.discogsReleaseId,
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

  /// Builds the [ReleaseDetail] the add-to-collection use case needs. Prefers
  /// the richer Discogs detail when it is loaded for this release; otherwise
  /// falls back to the wishlist item's own fields so the move never has to wait
  /// on a network fetch (the use case reads only id/artist/title/label/catno/
  /// format/country/year/coverUrl).
  ReleaseDetail _releaseForMove(WishlistItem item) {
    final detail = _releaseDetail;
    if (detail != null && detail.id == item.discogsReleaseId) return detail;
    return ReleaseDetail(
      id: item.discogsReleaseId,
      title: item.title,
      artist: item.artist,
      label: item.label ?? '',
      catno: item.catno ?? '',
      format: item.format ?? '',
      country: item.country ?? '',
      genres: const [],
      styles: const [],
      tracklist: const [],
      identifiers: const [],
      year: item.year,
      coverUrl: item.coverUrl,
    );
  }

  /// Moves the item into the collection (US-86): add first, and only remove it
  /// from the wishlist if the add succeeded (or it was already in the
  /// collection). The move is local-only — it never records a Discogs wantlist
  /// tombstone, mirroring the default of the remove flow.
  Future<void> _moveToCollection(WishlistItem item) async {
    final useCase = _addToCollectionUseCase;
    if (useCase == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await useCase.execute(_releaseForMove(item));
    if (!mounted) return;

    switch (result) {
      case AddToCollectionStorageError():
        // The add failed: leave the wishlist entry intact so it is never lost.
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Could not add to your collection. Your wishlist is unchanged.',
            ),
          ),
        );
      case AddToCollectionSuccess():
      case AddToCollectionDuplicate():
        final alreadyOwned = result is AddToCollectionDuplicate;
        try {
          await _repository.remove(item.id);
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                alreadyOwned
                    ? 'Already in your collection — removed from wishlist.'
                    : 'Moved to your collection.',
              ),
            ),
          );
          navigator.pop();
        } catch (_) {
          if (!mounted) return;
          // The add succeeded but the wishlist removal failed — surface it
          // rather than leaving a silent inconsistent state.
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Added to your collection, but could not remove it from the '
                'wishlist. Please remove it manually.',
              ),
            ),
          );
        }
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
                  key: const Key('add-to-collection-button'),
                  icon: const Icon(Icons.library_add_outlined),
                  tooltip: 'Add to collection',
                  onPressed: () => _moveToCollection(state.item),
                ),
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
                PopupMenuButton<_OverflowAction>(
                  key: const Key('detail-overflow-menu'),
                  onSelected: (action) {
                    if (action == _OverflowAction.remove) {
                      _confirmRemove(state.item);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _OverflowAction.remove,
                      child: Text('Remove from wishlist'),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: switch (state) {
        _Loading() => const Center(
          key: Key('wishlist-detail-loading'),
          child: CircularProgressIndicator(),
        ),
        _Loaded(:final item) => RefreshIndicator(
          onRefresh: _refresh,
          child: _WishlistDetailBody(
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
        setState(
          () => _validationError =
              'Enter a valid price, or leave empty to clear.',
        );
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
  const _WishlistDetailBody({
    required this.item,
    required this.thumbnailCacheService,
    this.releaseDetail,
  });

  final WishlistItem item;
  final ReleaseDetail? releaseDetail;
  final ThumbnailCacheService thumbnailCacheService;

  String? get _coverUrl => item.coverUrl ?? releaseDetail?.coverUrl;

  bool get _hasReleaseNotes =>
      releaseDetail?.notes != null && releaseDetail!.notes!.trim().isNotEmpty;

  bool get _hasTracklist => releaseDetail?.tracklist.isNotEmpty ?? false;

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
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CachedCoverImage(
              releaseId: item.discogsReleaseId,
              coverUrl: _coverUrl,
              borderRadius: BorderRadius.zero,
              thumbnailCacheService: thumbnailCacheService,
            ),
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
                  _CachedCoverImage(
                    releaseId: item.discogsReleaseId,
                    coverUrl: _coverUrl,
                    borderRadius: BorderRadius.circular(8),
                    thumbnailCacheService: thumbnailCacheService,
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
  const _InfoRows({required this.item, this.detail});

  final WishlistItem item;

  /// Discogs release details (US-76 standard). Preferred over the local
  /// item's sparse fields when available.
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

    final targetPriceText = item.targetPrice != null
        ? item.targetPrice!.toStringAsFixed(2)
        : 'Not set';

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
        _InfoRow('Priority', item.priority.label),
        _InfoRow('Target price', targetPriceText),
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

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.item});

  final WishlistItem item;

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

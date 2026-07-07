import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import '../../application/services/discogs_release_detail_service.dart';
import '../../application/services/thumbnail_cache_service.dart';
import '../../application/use_cases/add_to_collection_use_case.dart';
import '../../application/use_cases/add_to_wishlist_use_case.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/pending_discogs_deletion.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../app/app_repositories.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../shared/errors/app_error.dart';
import '../../shared/utils/date_format_utils.dart';
import '../widgets/rate_limit_retry_button.dart';
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
  const _Loaded(this.detail);
  final ReleaseDetail detail;
}

class _CachedLoaded extends _DetailState {
  _CachedLoaded(this.metadata);
  final CachedReleaseMetadata metadata;
}

class _DetailError extends _DetailState {
  const _DetailError(this.error);
  final AppError error;
}

// ---------------------------------------------------------------------------
// Add state
// ---------------------------------------------------------------------------

enum _AddState { idle, adding, added, duplicate }

// ---------------------------------------------------------------------------
// Remove actions (US-81)
// ---------------------------------------------------------------------------

enum _RemoveAction { collection, wishlist }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ReleaseDetailScreen extends StatefulWidget {
  const ReleaseDetailScreen({
    super.key,
    required this.releaseId,
    this.initialArtist,
    this.initialTitle,
    this.detailService,
    this.addToCollectionUseCase,
    this.addToWishlistUseCase,
    this.collectionRepository,
    this.wishlistRepository,
    this.cacheRepository,
    this.thumbnailCacheService,
    this.thumbnailRepository,
    this.deletionRepository,
  });

  final int releaseId;
  final String? initialArtist;
  final String? initialTitle;
  final DiscogsReleaseDetailService? detailService;
  final AddToCollectionUseCase? addToCollectionUseCase;
  final AddToWishlistUseCase? addToWishlistUseCase;
  final CollectionRepository? collectionRepository;
  final WishlistRepository? wishlistRepository;
  final CachedReleaseMetadataRepository? cacheRepository;
  final ThumbnailCacheService? thumbnailCacheService;
  final ThumbnailRepository? thumbnailRepository;
  final PendingDiscogsDeletionRepository? deletionRepository;

  @override
  State<ReleaseDetailScreen> createState() => _ReleaseDetailScreenState();
}

class _ReleaseDetailScreenState extends State<ReleaseDetailScreen> {
  late final DiscogsReleaseDetailService _service;
  ThumbnailCacheService? _ownedThumbService;
  AddToCollectionUseCase? _addUseCase;
  AddToWishlistUseCase? _addWishlistUseCase;
  late final CachedReleaseMetadataRepository? _cacheRepository;
  CollectionRepository? _collectionRepository;
  WishlistRepository? _wishlistRepository;
  PendingDiscogsDeletionRepository? _deletionRepository;
  _DetailState _state = const _Loading();
  _AddState _addState = _AddState.idle;
  _AddState _addWishlistState = _AddState.idle;

  @override
  void initState() {
    super.initState();
    final repos = AppRepositoriesScope.maybeOf(context);
    _collectionRepository = widget.collectionRepository ?? repos?.collection;
    _addUseCase =
        widget.addToCollectionUseCase ??
        (_collectionRepository != null
            ? AddToCollectionUseCase(_collectionRepository!)
            : null);
    _wishlistRepository = widget.wishlistRepository ?? repos?.wishlist;
    _addWishlistUseCase =
        widget.addToWishlistUseCase ??
        (_wishlistRepository != null
            ? AddToWishlistUseCase(_wishlistRepository!)
            : null);
    _cacheRepository = widget.cacheRepository ?? repos?.cachedRelease;
    _deletionRepository = widget.deletionRepository ?? repos?.pendingDeletion;
    if (widget.detailService == null && widget.thumbnailCacheService == null) {
      _ownedThumbService = ThumbnailCacheService(
        repository: LocalThumbnailRepository(),
      );
    }
    _service =
        widget.detailService ??
        DiscogsReleaseDetailService(
          cacheRepository: _cacheRepository,
          thumbnailCacheService:
              widget.thumbnailCacheService ?? _ownedThumbService,
        );
    _fetch();
    _checkInitialCollectionStatus();
    _checkInitialWishlistStatus();
  }

  @override
  void dispose() {
    _ownedThumbService?.close();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final detail = await _service.fetchDetail(widget.releaseId);
      if (!mounted) return;
      setState(() => _state = _Loaded(detail));
    } on AppError catch (e) {
      final cached = await _tryLoadFromCache();
      if (!mounted) return;
      if (cached != null) {
        setState(() => _state = _CachedLoaded(cached));
      } else {
        setState(() => _state = _DetailError(e));
      }
    }
  }

  Future<CachedReleaseMetadata?> _tryLoadFromCache() async {
    if (_cacheRepository == null) return null;
    try {
      return await _cacheRepository.getByReleaseId(widget.releaseId);
    } catch (_) {
      return null;
    }
  }

  void _retry() {
    setState(() => _state = const _Loading());
    _fetch();
  }

  Future<void> _checkInitialCollectionStatus() async {
    if (_collectionRepository == null) return;
    try {
      final inCollection = await _collectionRepository!.containsRelease(
        widget.releaseId,
      );
      if (!mounted) return;
      if (inCollection && _addState == _AddState.idle) {
        setState(() => _addState = _AddState.duplicate);
      }
    } catch (_) {
      // silently ignore — button stays enabled so the user can try to add
    }
  }

  Future<void> _checkInitialWishlistStatus() async {
    if (_wishlistRepository == null) return;
    try {
      final inWishlist = await _wishlistRepository!.containsRelease(
        widget.releaseId,
      );
      if (!mounted) return;
      if (inWishlist && _addWishlistState == _AddState.idle) {
        setState(() => _addWishlistState = _AddState.duplicate);
      }
    } catch (_) {
      // silently ignore — button stays enabled so the user can try to add
    }
  }

  Future<void> _refresh() async {
    try {
      final detail = await _service.fetchDetail(widget.releaseId);
      if (!mounted) return;
      setState(() => _state = _Loaded(detail));
    } on AppError catch (e) {
      if (!mounted) return;
      if (_state is _Loaded || _state is _CachedLoaded) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_refreshErrorMessage(e))));
      } else {
        setState(() => _state = _DetailError(e));
      }
    }
  }

  static String _refreshErrorMessage(AppError e) => switch (e) {
    RateLimitedError() => 'Too many requests — wait a moment and try again.',
    NetworkError() => 'No internet connection.',
    _ => 'Could not refresh. Try again.',
  };

  ReleaseDetail? _currentDetail() {
    final state = _state;
    if (state is _Loaded) return state.detail;
    if (state is _CachedLoaded) {
      return releaseDetailFromCachedMetadata(state.metadata);
    }
    return null;
  }

  Future<void> _handleAdd() async {
    final detail = _currentDetail();
    if (detail == null || _addUseCase == null) return;
    setState(() => _addState = _AddState.adding);
    final result = await _addUseCase!.execute(detail);
    if (!mounted) return;
    switch (result) {
      case AddToCollectionSuccess(:final item):
        setState(() => _addState = _AddState.added);
        await _showConditionPrompt(item);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to your collection')),
        );
      case AddToCollectionDuplicate():
        setState(() => _addState = _AddState.duplicate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already in your collection')),
        );
      case AddToCollectionStorageError():
        setState(() => _addState = _AddState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save to collection — queued for retry.'),
          ),
        );
    }
  }

  Future<void> _showConditionPrompt(CollectionItem item) async {
    if (!mounted) return;
    final result =
        await showModalBottomSheet<(RecordCondition, RecordCondition)>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _ConditionPromptSheet(
            key: const Key('condition-prompt-sheet'),
            initialMediaCondition: item.mediaCondition,
            initialSleeveCondition: item.sleeveCondition,
          ),
        );
    if (result == null) return;
    final (media, sleeve) = result;
    try {
      await _collectionRepository?.update(
        item.copyWith(
          mediaCondition: media,
          sleeveCondition: sleeve,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // Silently ignore update errors — item is already saved with defaults.
    }
  }

  Future<void> _handleAddToWishlist() async {
    final detail = _currentDetail();
    if (detail == null || _addWishlistUseCase == null) return;
    setState(() => _addWishlistState = _AddState.adding);
    final result = await _addWishlistUseCase!.execute(detail);
    if (!mounted) return;
    switch (result) {
      case AddToWishlistSuccess():
        setState(() => _addWishlistState = _AddState.added);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to your wishlist')));
      case AddToWishlistDuplicate():
        setState(() => _addWishlistState = _AddState.duplicate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already in your wishlist')),
        );
      case AddToWishlistStorageError():
        setState(() => _addWishlistState = _AddState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save to wishlist — queued for retry.'),
          ),
        );
    }
  }

  // -------------------------------------------------------------------------
  // Remove from collection / wishlist (US-81)
  // -------------------------------------------------------------------------

  bool get _inCollection =>
      _addState == _AddState.added || _addState == _AddState.duplicate;

  bool get _onWishlist =>
      _addWishlistState == _AddState.added ||
      _addWishlistState == _AddState.duplicate;

  /// Resolves the local collection item for this release (the detail screen
  /// only holds the Discogs release id, not the item id) and runs the remove
  /// flow. Mirrors US-80's getAll-derived lookup to avoid a new repository
  /// method across the test fakes.
  Future<void> _handleRemoveFromCollection() async {
    final repo = _collectionRepository;
    if (repo == null) return;
    CollectionItem? item;
    try {
      final all = await repo.getAll();
      for (final i in all) {
        if (i.discogsReleaseId == widget.releaseId) {
          item = i;
          break;
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove from collection. Please try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (item == null) {
      // Already gone — re-enable the button so the user can add again.
      setState(() => _addState = _AddState.idle);
      return;
    }
    await _confirmRemoveFromCollection(item);
  }

  Future<void> _confirmRemoveFromCollection(CollectionItem item) async {
    // Only items we hold a Discogs instance id for can propagate the removal
    // to Discogs; for those, offer opt-in propagation (US-72).
    final canRemoveFromDiscogs =
        _deletionRepository != null && item.discogsInstanceId != null;
    var alsoFromDiscogs = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Remove from Collection?'),
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
      await _removeFromCollection(item, alsoFromDiscogs: alsoFromDiscogs);
    }
  }

  Future<void> _removeFromCollection(
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
      await _collectionRepository!.remove(item.id);
      if (!mounted) return;
      setState(() => _addState = _AddState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from your collection')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove from collection. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleRemoveFromWishlist() async {
    final repo = _wishlistRepository;
    if (repo == null) return;
    WishlistItem? item;
    try {
      final all = await repo.getAll();
      for (final i in all) {
        if (i.discogsReleaseId == widget.releaseId) {
          item = i;
          break;
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove from wishlist. Please try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (item == null) {
      setState(() => _addWishlistState = _AddState.idle);
      return;
    }
    await _confirmRemoveFromWishlist(item);
  }

  Future<void> _confirmRemoveFromWishlist(WishlistItem item) async {
    // A synced wantlist entry can be removed from Discogs by release id (no
    // instance id needed); offer opt-in propagation (US-72).
    final canRemoveFromDiscogs =
        _deletionRepository != null && item.syncStatus == SyncStatus.synced;
    var alsoFromDiscogs = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Remove from Wishlist?'),
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
      await _removeFromWishlist(item, alsoFromDiscogs: alsoFromDiscogs);
    }
  }

  Future<void> _removeFromWishlist(
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
      await _wishlistRepository!.remove(item.id);
      if (!mounted) return;
      setState(() => _addWishlistState = _AddState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from your wishlist')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove from wishlist. Please try again.'),
        ),
      );
    }
  }

  static bool _isRetriable(AppError e) =>
      e is! NoTokenError && e is! InvalidTokenError;

  String get _appBarTitle {
    final state = _state;
    if (state is _Loading) {
      final t = widget.initialTitle;
      if (t != null && t.isNotEmpty) {
        final a = widget.initialArtist;
        return (a != null && a.isNotEmpty) ? '$a — $t' : t;
      }
      return 'Release Detail';
    }
    if (state is _Loaded && state.detail.title.isNotEmpty) {
      final d = state.detail;
      final a = d.displayArtist ?? d.artist;
      return a.isNotEmpty ? '$a — ${d.title}' : d.title;
    }
    if (state is _CachedLoaded && state.metadata.title.isNotEmpty) {
      final m = state.metadata;
      return m.artist.isNotEmpty ? '${m.artist} — ${m.title}' : m.title;
    }
    return 'Release Detail';
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final canRemove =
        (state is _Loaded || state is _CachedLoaded) &&
        (_inCollection || _onWishlist);
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle, overflow: TextOverflow.ellipsis, maxLines: 1),
        actions: canRemove
            ? [
                PopupMenuButton<_RemoveAction>(
                  key: const Key('detail-remove-menu'),
                  onSelected: (action) {
                    switch (action) {
                      case _RemoveAction.collection:
                        _handleRemoveFromCollection();
                      case _RemoveAction.wishlist:
                        _handleRemoveFromWishlist();
                    }
                  },
                  itemBuilder: (_) => [
                    if (_inCollection)
                      const PopupMenuItem(
                        key: Key('remove-from-collection-item'),
                        value: _RemoveAction.collection,
                        child: Text('Remove from Collection'),
                      ),
                    if (_onWishlist)
                      const PopupMenuItem(
                        key: Key('remove-from-wishlist-item'),
                        value: _RemoveAction.wishlist,
                        child: Text('Remove from Wishlist'),
                      ),
                  ],
                ),
              ]
            : null,
      ),
      body: switch (state) {
        _Loading() => _SkeletonBody(
          artist: widget.initialArtist,
          title: widget.initialTitle,
        ),
        _DetailError(:final error) => _ErrorBody(
          error: error,
          onRetry: _isRetriable(error) ? _retry : null,
        ),
        _Loaded(:final detail) => RefreshIndicator(
          onRefresh: _refresh,
          child: _DetailBody(detail: detail),
        ),
        _CachedLoaded(:final metadata) => RefreshIndicator(
          onRefresh: _refresh,
          child: _CachedDetailBody(
            metadata: metadata,
            thumbnailRepository: widget.thumbnailRepository,
          ),
        ),
      },
      bottomNavigationBar: (state is _Loaded || state is _CachedLoaded)
          ? _AddActionsBar(
              collectionState: _addState,
              wishlistState: _addWishlistState,
              onAddCollection: _handleAdd,
              onAddToWishlist: _handleAddToWishlist,
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Add actions bar (collection + wishlist)
// ---------------------------------------------------------------------------

class _AddActionsBar extends StatelessWidget {
  const _AddActionsBar({
    required this.collectionState,
    required this.wishlistState,
    required this.onAddCollection,
    required this.onAddToWishlist,
  });

  final _AddState collectionState;
  final _AddState wishlistState;
  final VoidCallback onAddCollection;
  final VoidCallback onAddToWishlist;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: double.infinity, child: _buildCollectionButton()),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: _buildWishlistButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionButton() {
    final Widget icon;
    final String label;
    final VoidCallback? onPressed;

    switch (collectionState) {
      case _AddState.idle:
        icon = const Icon(Icons.add);
        label = 'Add to Collection';
        onPressed = onAddCollection;
      case _AddState.adding:
        icon = const Icon(Icons.add);
        label = 'Adding…';
        onPressed = null;
      case _AddState.added || _AddState.duplicate:
        icon = const Icon(Icons.check);
        label = 'In Collection';
        onPressed = null;
    }

    return FilledButton.icon(
      key: const Key('add-to-collection-button'),
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
    );
  }

  Widget _buildWishlistButton() {
    final Widget icon;
    final String label;
    final VoidCallback? onPressed;

    switch (wishlistState) {
      case _AddState.idle:
        icon = const Icon(Icons.bookmark_border);
        label = 'Add to Wishlist';
        onPressed = onAddToWishlist;
      case _AddState.adding:
        icon = const Icon(Icons.bookmark_border);
        label = 'Adding…';
        onPressed = null;
      case _AddState.added || _AddState.duplicate:
        icon = const Icon(Icons.bookmark);
        label = 'In Wishlist';
        onPressed = null;
    }

    return OutlinedButton.icon(
      key: const Key('add-to-wishlist-button'),
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({this.artist, this.title});

  final String? artist;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surfaceContainerHighest;

    Widget block({double? width, required double height}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    final hasTitle = title != null && title!.isNotEmpty;
    final hasArtist = artist != null && artist!.isNotEmpty;

    return SingleChildScrollView(
      key: const Key('release-detail-loading'),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 1, child: ColoredBox(color: color)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hasTitle
                    ? Text(title!, style: theme.textTheme.headlineSmall)
                    : block(width: 200, height: 22),
                const SizedBox(height: 8),
                if (hasArtist)
                  Text(
                    artist!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  block(width: 130, height: 16),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      block(width: 80, height: 12),
                      const SizedBox(width: 16),
                      Expanded(child: block(height: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: block(width: 80, height: 14),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      block(width: 28, height: 12),
                      const SizedBox(width: 12),
                      Expanded(child: block(height: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, this.onRetry});

  final AppError error;
  final VoidCallback? onRetry;

  String get _message => switch (error) {
    NoTokenError() =>
      'Connect a Discogs token in Settings to view release details.',
    InvalidTokenError() =>
      'Your Discogs token is not valid. Go to Settings to reconnect.',
    RateLimitedError() => 'Too many requests. Wait a moment and try again.',
    NetworkError() =>
      'No internet connection. Visit this release while online to save data for offline viewing.',
    StorageError() => 'Could not load your saved token. Try again.',
    DiscogsUnavailableError() => 'Could not reach Discogs. Try again.',
    UnexpectedApiError() => 'Could not reach Discogs. Try again.',
  };

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
              _message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              RateLimitRetryButton(
                onRetry: onRetry!,
                isRateLimited: error is RateLimitedError,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail body
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, this.localThumbnailPath});

  final ReleaseDetail detail;
  final String? localThumbnailPath;

  static const _kWideBreakpoint = 700.0;

  List<String> get _effectiveImageUrls => detail.imageUrls.isNotEmpty
      ? detail.imageUrls
      : (detail.coverUrl != null ? [detail.coverUrl!] : const []);

  Widget _buildCoverNarrow() {
    final urls = _effectiveImageUrls;
    if (urls.isEmpty && localThumbnailPath == null) {
      return const SizedBox.shrink();
    }
    return ReleaseImageGallery(
      imageUrls: urls,
      localThumbnailPath: localThumbnailPath,
    );
  }

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
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCoverNarrow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _TitleArtist(detail: detail),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _InfoRows(detail: detail),
          ),
          if (detail.tracklist.isNotEmpty)
            _TracklistSection(tracks: detail.tracklist),
          if (detail.notes != null && detail.notes!.isNotEmpty)
            _NotesSection(notes: detail.notes!),
          if (detail.identifiers.isNotEmpty)
            _IdentifiersSection(identifiers: detail.identifiers),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWideCover(BuildContext context) {
    final urls = _effectiveImageUrls;
    if (urls.isNotEmpty || localThumbnailPath != null) {
      return ReleaseImageGallery(
        imageUrls: urls,
        localThumbnailPath: localThumbnailPath,
        borderRadius: BorderRadius.circular(8),
      );
    }
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.album,
            size: 72,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return SingleChildScrollView(
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
                _buildWideCover(context),
                const SizedBox(height: 20),
                _TitleArtist(detail: detail),
                const SizedBox(height: 16),
                _InfoRows(detail: detail),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (detail.tracklist.isNotEmpty)
                  _TracklistSection(tracks: detail.tracklist),
                if (detail.notes != null && detail.notes!.isNotEmpty)
                  _NotesSection(notes: detail.notes!),
                if (detail.identifiers.isNotEmpty)
                  _IdentifiersSection(identifiers: detail.identifiers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cached detail body
// ---------------------------------------------------------------------------

class _CachedDetailBody extends StatelessWidget {
  const _CachedDetailBody({required this.metadata, this.thumbnailRepository});

  final CachedReleaseMetadata metadata;
  final ThumbnailRepository? thumbnailRepository;

  @override
  Widget build(BuildContext context) {
    final detail = releaseDetailFromCachedMetadata(metadata);
    if (thumbnailRepository == null) {
      return Column(
        children: [
          _CachedBanner(fetchedAt: metadata.fetchedAt),
          Expanded(child: _DetailBody(detail: detail)),
        ],
      );
    }
    return FutureBuilder<String?>(
      future: thumbnailRepository!.getLocalPath(metadata.discogsReleaseId),
      builder: (context, snapshot) => Column(
        children: [
          _CachedBanner(fetchedAt: metadata.fetchedAt),
          Expanded(
            child: _DetailBody(
              detail: detail,
              localThumbnailPath: snapshot.data,
            ),
          ),
        ],
      ),
    );
  }
}

class _CachedBanner extends StatelessWidget {
  const _CachedBanner({required this.fetchedAt});

  final DateTime fetchedAt;

  static const _kStaleDays = 30;

  bool get _isStale =>
      DateTime.now().difference(fetchedAt).inDays >= _kStaleDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stale = _isStale;
    final bgColor = stale
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final fgColor = stale
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;
    return ColoredBox(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              stale ? Icons.warning_amber_rounded : Icons.offline_pin_outlined,
              key: stale ? const Key('cached-banner-stale') : null,
              size: 16,
              color: fgColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Showing saved data · last updated ${formatDate(fetchedAt, Localizations.localeOf(context))}',
                style: theme.textTheme.labelSmall?.copyWith(color: fgColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _TitleArtist extends StatelessWidget {
  const _TitleArtist({required this.detail});

  final ReleaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.title.isEmpty ? '(Untitled)' : detail.title,
          style: theme.textTheme.headlineSmall,
        ),
        if ((detail.displayArtist ?? detail.artist).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            detail.displayArtist ?? detail.artist,
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
  const _InfoRows({required this.detail});

  final ReleaseDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (detail.label.isNotEmpty)
          _InfoRow(
            'Label',
            detail.catno.isNotEmpty
                ? '${detail.label} — ${detail.catno}'
                : detail.label,
          ),
        if (detail.format.isNotEmpty) _InfoRow('Format', detail.format),
        if (detail.country.isNotEmpty) _InfoRow('Country', detail.country),
        if (detail.year != null) _InfoRow('Released', '${detail.year}'),
        if (detail.genres.isNotEmpty)
          _InfoRow('Genre', detail.genres.join(', ')),
        if (detail.styles.isNotEmpty)
          _InfoRow('Style', detail.styles.join(', ')),
        _InfoRow('Discogs ID', '#${detail.id}'),
      ],
    );
  }
}

class _TracklistSection extends StatelessWidget {
  const _TracklistSection({required this.tracks});

  final List<ReleaseTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Tracklist'),
        ...tracks.map((t) => _TrackRow(track: t)),
        const SizedBox(height: 8),
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

class _IdentifiersSection extends StatelessWidget {
  const _IdentifiersSection({required this.identifiers});

  final List<ReleaseIdentifier> identifiers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Identifiers'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: identifiers
                .map((i) => _InfoRow(i.type, i.value))
                .toList(),
          ),
        ),
      ],
    );
  }
}

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

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track});

  final ReleaseTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
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
          Expanded(child: Text(track.title, style: theme.textTheme.bodyMedium)),
          if (track.duration.isNotEmpty)
            Text(
              track.duration,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Condition prompt sheet
// ---------------------------------------------------------------------------

class _ConditionPromptSheet extends StatefulWidget {
  const _ConditionPromptSheet({
    super.key,
    required this.initialMediaCondition,
    required this.initialSleeveCondition,
  });

  final RecordCondition initialMediaCondition;
  final RecordCondition initialSleeveCondition;

  @override
  State<_ConditionPromptSheet> createState() => _ConditionPromptSheetState();
}

class _ConditionPromptSheetState extends State<_ConditionPromptSheet> {
  late RecordCondition _media;
  late RecordCondition _sleeve;

  static const _kConditions = [
    RecordCondition.mint,
    RecordCondition.nearMint,
    RecordCondition.veryGoodPlus,
    RecordCondition.veryGood,
    RecordCondition.goodPlus,
    RecordCondition.good,
    RecordCondition.fair,
    RecordCondition.poor,
  ];

  @override
  void initState() {
    super.initState();
    _media = widget.initialMediaCondition;
    _sleeve = widget.initialSleeveCondition;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Set condition', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'You can update this any time from your collection.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _ConditionDropdown(
              key: const Key('media-condition-dropdown'),
              label: 'Media',
              value: _media,
              conditions: _kConditions,
              onChanged: (v) => setState(() => _media = v),
            ),
            const SizedBox(height: 12),
            _ConditionDropdown(
              key: const Key('sleeve-condition-dropdown'),
              label: 'Sleeve',
              value: _sleeve,
              conditions: _kConditions,
              onChanged: (v) => setState(() => _sleeve = v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('condition-skip-button'),
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('condition-save-button'),
                    onPressed: () =>
                        Navigator.of(context).pop((_media, _sleeve)),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionDropdown extends StatelessWidget {
  const _ConditionDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.conditions,
    required this.onChanged,
  });

  final String label;
  final RecordCondition value;
  final List<RecordCondition> conditions;
  final ValueChanged<RecordCondition> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RecordCondition>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: conditions
          .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

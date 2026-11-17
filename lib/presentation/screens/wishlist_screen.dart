import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/app_repositories.dart';
import '../../app/router.dart';
import '../../application/services/thumbnail_cache_service.dart';
import '../../domain/models/added_date_sort.dart';
import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/models/wishlist_filter_set.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/saved_search_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/import_notifier.dart';
import '../../shared/route_observer.dart';
import '../widgets/wishlist_filter_sheet.dart';
import '../widgets/wishlist_item_card.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _WishlistState {
  const _WishlistState();
}

class _Loading extends _WishlistState {
  const _Loading();
}

class _Loaded extends _WishlistState {
  const _Loaded(this.items);
  final List<WishlistItem> items;
}

class _WishlistError extends _WishlistState {
  const _WishlistError();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({
    super.key,
    this.repository,
    this.thumbnailRepository,
    this.thumbnailCacheService,
    this.accelerometerStream,
    this.metadataRepository,
    this.savedSearchRepository,
  });

  final WishlistRepository? repository;
  final ThumbnailRepository? thumbnailRepository;
  final ThumbnailCacheService? thumbnailCacheService;
  final Stream<AccelerometerEvent>? accelerometerStream;
  final CachedReleaseMetadataRepository? metadataRepository;
  final SavedSearchRepository? savedSearchRepository;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with RouteAware {
  late final WishlistRepository _repository;
  late final ThumbnailRepository _thumbnailRepository;
  late final ThumbnailCacheService _thumbnailCacheService;
  CachedReleaseMetadataRepository? _metaRepository;
  late final SavedSearchRepository? _savedSearchRepository;
  bool _ownsThumbService = false;
  _WishlistState _state = const _Loading();
  List<CachedReleaseMetadata> _metadata = const [];
  WishlistFilterSet _filter = const WishlistFilterSet();
  AddedDateSort _sort = AddedDateSort.newestFirst;

  /// Badge count: active filters plus a non-default sort (US-164).
  int get _activeCount =>
      _filter.activeCount + (_sort != AddedDateSort.newestFirst ? 1 : 0);
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _debouncedQuery = '';
  static const _kShakeThreshold = 20.0;
  static const _kShakeCooldown = Duration(seconds: 2);
  StreamSubscription<AccelerometerEvent>? _shakeSub;
  DateTime _lastShake = DateTime(0);
  bool _shakeActive = true;

  @override
  void initState() {
    super.initState();
    _thumbnailRepository =
        widget.thumbnailRepository ?? LocalThumbnailRepository();
    _ownsThumbService = widget.thumbnailCacheService == null;
    _thumbnailCacheService =
        widget.thumbnailCacheService ??
        ThumbnailCacheService(repository: _thumbnailRepository);
    _repository =
        widget.repository ?? AppRepositoriesScope.of(context).wishlist;
    _metaRepository =
        widget.metadataRepository ??
        AppRepositoriesScope.maybeOf(context)?.cachedRelease;
    _savedSearchRepository =
        widget.savedSearchRepository ??
        AppRepositoriesScope.maybeOf(context)?.savedSearch;
    _load();
    wishlistImportNotifier.addListener(_onImportNotification);
    _shakeSub = (widget.accelerometerStream ?? accelerometerEventStream())
        .listen(_onAccelerometer);
  }

  void _onImportNotification() {
    if (mounted) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) wishlistRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => _shakeActive = false;

  @override
  void didPopNext() {
    _shakeActive = true;
    _refresh();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final itemsFuture = _repository.getAll();
      final metaFuture = _metaRepository?.getAll();
      final items = await itemsFuture;
      final meta = await metaFuture ?? const [];
      if (!mounted) return;
      setState(() {
        _state = _Loaded(items);
        _metadata = meta;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _WishlistError());
    }
  }

  Future<void> _refresh() async {
    try {
      final itemsFuture = _repository.getAll();
      final metaFuture = _metaRepository?.getAll();
      final items = await itemsFuture;
      final meta = await metaFuture ?? const [];
      if (!mounted) return;
      setState(() {
        _state = _Loaded(items);
        _metadata = meta;
      });
    } catch (_) {
      if (!mounted) return;
      if (_state is _Loaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh your wishlist. Please try again.'),
          ),
        );
      } else {
        setState(() => _state = const _WishlistError());
      }
    }
  }

  @override
  void dispose() {
    wishlistRouteObserver.unsubscribe(this);
    wishlistImportNotifier.removeListener(_onImportNotification);
    _shakeSub?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    if (_ownsThumbService) _thumbnailCacheService.close();
    super.dispose();
  }

  Widget _buildBody() {
    return switch (_state) {
      _Loading() => const Center(child: CircularProgressIndicator()),
      _Loaded(:final items) when items.isEmpty => RefreshIndicator(
        onRefresh: _refresh,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _EmptyWishlistState())],
        ),
      ),
      _Loaded(:final items) => _buildLoadedList(items),
      _WishlistError() => _WishlistErrorState(onRetry: _load),
    };
  }

  Future<void> _openFilterSheet() async {
    final items = _state is _Loaded
        ? (_state as _Loaded).items
        : <WishlistItem>[];
    final result = await showModalBottomSheet<WishlistFilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WishlistFilterSheet(
        current: _filter,
        sort: _sort,
        items: items,
        metadata: _metadata,
        savedSearchRepository: _savedSearchRepository,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _filter = result.filter;
        _sort = result.sort;
      });
    }
  }

  Future<void> _openSavedSearches() async {
    final result = await context.push<SavedSearch>(
      AppRoutes.savedSearches,
      extra: SavedSearchType.wishlistFilter,
    );
    if (result == null || !mounted) return;
    final filter = WishlistFilterSet.fromJsonString(result.payloadJson);
    setState(() => _filter = filter);
    _savedSearchRepository?.updateLastUsed(result.id, DateTime.now());
  }

  Widget _buildLoadedList(List<WishlistItem> items) {
    final q = _debouncedQuery.trim().toLowerCase();
    var filtered = q.isEmpty
        ? items
        : items
              .where(
                (i) =>
                    i.artist.toLowerCase().contains(q) ||
                    i.title.toLowerCase().contains(q),
              )
              .toList();

    if (!_filter.isEmpty) {
      filtered = _filter.apply(filtered, metadata: _metadata);
    }
    filtered = _sort.apply(filtered, (i) => i.createdAt);

    if (filtered.isEmpty) {
      return _NoSearchResults(query: _debouncedQuery.trim());
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          if (!_filter.isEmpty)
            _ActiveFilterBar(
              count: _filter.activeCount,
              onClear: () =>
                  setState(() => _filter = const WishlistFilterSet()),
            ),
          Expanded(
            child: _WishlistList(
              items: filtered,
              thumbnailCacheService: _thumbnailCacheService,
            ),
          ),
        ],
      ),
    );
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!mounted || !_shakeActive) return;
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null && shell.currentIndex != 2) return;
    final x = event.x, y = event.y, z = event.z;
    if (sqrt(x * x + y * y + z * z) < _kShakeThreshold) return;
    final now = DateTime.now();
    if (now.difference(_lastShake) < _kShakeCooldown) return;
    _lastShake = now;
    final state = _state;
    if (state is! _Loaded || state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Je verlanglijst is leeg — voeg eerst platen toe.'),
        ),
      );
      return;
    }
    final item = state.items[Random().nextInt(state.items.length)];
    context.push(AppRoutes.wishlistDetail(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    setState(() {}); // immediate: clear-button visibility
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(
                          () => _debouncedQuery = _searchController.text,
                        );
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.wishlistSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _debounce?.cancel();
                              _searchController.clear();
                              setState(() => _debouncedQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 20,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('wishlist-filter-button'),
                icon: Badge(
                  isLabelVisible: _activeCount > 0,
                  label: Text('$_activeCount'),
                  child: const Icon(Icons.filter_list_outlined),
                ),
                tooltip: 'Filter',
                onPressed: _openFilterSheet,
              ),
              IconButton(
                key: const Key('wishlist-saved-searches-button'),
                icon: const Icon(Icons.bookmarks_outlined),
                tooltip: 'Saved filters',
                onPressed: _openSavedSearches,
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.count, required this.onClear});

  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count filter${count == 1 ? '' : 's'} active',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          TextButton(
            key: const Key('clear-filters-button'),
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _WishlistList extends StatelessWidget {
  const _WishlistList({
    required this.items,
    required this.thumbnailCacheService,
  });

  final List<WishlistItem> items;
  final ThumbnailCacheService thumbnailCacheService;

  static const _kWideBreakpoint = 700.0;
  static const _kGridItemExtent = 124.0;

  void _openDetail(BuildContext context, int index) {
    context.push(AppRoutes.wishlistDetail(items[index].id));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= _kWideBreakpoint
          ? _buildGrid(context)
          : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      // Match the collection list's spacing (US/QA: equal density across tabs).
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => WishlistItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailCacheService: thumbnailCacheService,
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      // Match the collection grid's spacing (US/QA: equal density across tabs).
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: _kGridItemExtent,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => WishlistItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailCacheService: thumbnailCacheService,
      ),
    );
  }
}

class _EmptyWishlistState extends StatelessWidget {
  const _EmptyWishlistState();

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
              Icons.bookmark_border,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.wishlistEmptyTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.wishlistOfflineNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.addViaSearchHint,
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

class _WishlistErrorState extends StatelessWidget {
  const _WishlistErrorState({required this.onRetry});

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
              'Could not load your wishlist from device storage.',
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

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

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
            Text(
              AppLocalizations.of(context)!.wishlistNoResultsTitle(query),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.wishlistNoResultsBody,
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

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/app_repositories.dart';
import '../../app/router.dart';
import '../../application/services/thumbnail_cache_service.dart';
import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/collection_filter_set.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/models/collection_sort.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/saved_search_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/import_notifier.dart';
import '../../shared/route_observer.dart';
import '../widgets/collection_filter_sheet.dart';
import '../widgets/collection_item_card.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _CollectionState {
  const _CollectionState();
}

class _Loading extends _CollectionState {
  const _Loading();
}

class _Loaded extends _CollectionState {
  const _Loaded(this.items);
  final List<CollectionItem> items;
}

class _CollectionError extends _CollectionState {
  const _CollectionError();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    this.repository,
    this.thumbnailRepository,
    this.thumbnailCacheService,
    this.accelerometerStream,
    this.metadataRepository,
    this.savedSearchRepository,
  });

  final CollectionRepository? repository;
  final ThumbnailRepository? thumbnailRepository;
  final ThumbnailCacheService? thumbnailCacheService;
  final Stream<AccelerometerEvent>? accelerometerStream;
  final CachedReleaseMetadataRepository? metadataRepository;
  final SavedSearchRepository? savedSearchRepository;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with RouteAware {
  late final CollectionRepository _repository;
  late final ThumbnailRepository _thumbnailRepository;
  late final ThumbnailCacheService _thumbnailCacheService;
  CachedReleaseMetadataRepository? _metaRepository;
  late final SavedSearchRepository? _savedSearchRepository;
  bool _ownsThumbService = false;
  _CollectionState _state = const _Loading();
  List<CachedReleaseMetadata> _metadata = const [];
  CollectionFilterSet _filter = const CollectionFilterSet();
  CollectionSort _sort = CollectionSort.newestFirst;
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
        widget.repository ?? AppRepositoriesScope.of(context).collection;
    _metaRepository =
        widget.metadataRepository ??
        AppRepositoriesScope.maybeOf(context)?.cachedRelease;
    _savedSearchRepository =
        widget.savedSearchRepository ??
        AppRepositoriesScope.maybeOf(context)?.savedSearch;
    _load();
    collectionImportNotifier.addListener(_onImportNotification);
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
    if (route != null) appRouteObserver.subscribe(this, route);
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
      setState(() => _state = const _CollectionError());
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
            content: Text(
              'Could not refresh your collection. Please try again.',
            ),
          ),
        );
      } else {
        setState(() => _state = const _CollectionError());
      }
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    collectionImportNotifier.removeListener(_onImportNotification);
    _shakeSub?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    if (_ownsThumbService) _thumbnailCacheService.close();
    super.dispose();
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!mounted || !_shakeActive) return;
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null && shell.currentIndex != 1) return;
    final x = event.x, y = event.y, z = event.z;
    if (sqrt(x * x + y * y + z * z) < _kShakeThreshold) return;
    final now = DateTime.now();
    if (now.difference(_lastShake) < _kShakeCooldown) return;
    _lastShake = now;
    final state = _state;
    if (state is! _Loaded || state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Je collectie is leeg — voeg eerst platen toe.'),
        ),
      );
      return;
    }
    final item = state.items[Random().nextInt(state.items.length)];
    context.push(AppRoutes.collectionDetail(item.id));
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
                    hintText: AppLocalizations.of(
                      context,
                    )!.collectionSearchHint,
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
                key: const Key('collection-filter-button'),
                icon: Badge(
                  isLabelVisible: !_filter.isEmpty,
                  label: Text('${_filter.activeCount}'),
                  child: const Icon(Icons.filter_list_outlined),
                ),
                tooltip: 'Filter',
                onPressed: _openFilterSheet,
              ),
              PopupMenuButton<CollectionSort>(
                key: const Key('collection-sort-button'),
                icon: Icon(
                  Icons.sort,
                  color: _sort != CollectionSort.newestFirst
                      ? theme.colorScheme.primary
                      : null,
                ),
                tooltip: 'Sort',
                initialValue: _sort,
                onSelected: (s) => setState(() => _sort = s),
                itemBuilder: (context) => CollectionSort.values
                    .map(
                      (s) => CheckedPopupMenuItem(
                        value: s,
                        checked: s == _sort,
                        child: Text(s.label),
                      ),
                    )
                    .toList(),
              ),
              IconButton(
                key: const Key('collection-saved-searches-button'),
                icon: const Icon(Icons.bookmark_outline),
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

  Widget _buildBody() {
    return switch (_state) {
      _Loading() => const Center(child: CircularProgressIndicator()),
      _Loaded(:final items) when items.isEmpty => RefreshIndicator(
        onRefresh: _refresh,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _EmptyCollectionState())],
        ),
      ),
      _Loaded(:final items) => _buildLoadedList(items),
      _CollectionError() => _CollectionErrorState(onRetry: _load),
    };
  }

  Future<void> _openFilterSheet() async {
    final items = _state is _Loaded
        ? (_state as _Loaded).items
        : <CollectionItem>[];
    final result = await showModalBottomSheet<CollectionFilterSet>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CollectionFilterSheet(
        current: _filter,
        items: items,
        metadata: _metadata,
        savedSearchRepository: _savedSearchRepository,
      ),
    );
    if (result != null && mounted) setState(() => _filter = result);
  }

  Future<void> _openSavedSearches() async {
    final result = await context.push<SavedSearch>(
      AppRoutes.savedSearches,
      extra: SavedSearchType.collectionFilter,
    );
    if (result == null || !mounted) return;
    final filter = CollectionFilterSet.fromJsonString(result.payloadJson);
    setState(() => _filter = filter);
    _savedSearchRepository?.updateLastUsed(result.id, DateTime.now());
  }

  Widget _buildLoadedList(List<CollectionItem> items) {
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
    filtered = _sort.apply(filtered);

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
                  setState(() => _filter = const CollectionFilterSet()),
            ),
          Expanded(
            child: _CollectionList(
              items: filtered,
              thumbnailCacheService: _thumbnailCacheService,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _CollectionList extends StatelessWidget {
  const _CollectionList({
    required this.items,
    required this.thumbnailCacheService,
  });

  final List<CollectionItem> items;
  final ThumbnailCacheService thumbnailCacheService;

  static const _kWideBreakpoint = 700.0;
  static const _kGridItemExtent = 124.0;

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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => CollectionItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailCacheService: thumbnailCacheService,
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: _kGridItemExtent,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => CollectionItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailCacheService: thumbnailCacheService,
      ),
    );
  }

  void _openDetail(BuildContext context, int index) {
    context.push(AppRoutes.collectionDetail(items[index].id));
  }
}

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

class _EmptyCollectionState extends StatelessWidget {
  const _EmptyCollectionState();

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
              Icons.album_outlined,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.collectionEmptyTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.collectionOfflineNote,
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

class _CollectionErrorState extends StatelessWidget {
  const _CollectionErrorState({required this.onRetry});

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
              'Could not load your collection from device storage.',
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
              AppLocalizations.of(context)!.collectionNoResultsTitle(query),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.collectionNoResultsBody,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../application/services/discogs_search_service.dart';
import '../../application/services/search_query_cache.dart';
import '../../application/use_cases/add_to_collection_use_case.dart';
import '../../application/use_cases/add_to_wishlist_use_case.dart';
import '../../domain/models/release_search_result.dart';
import '../../domain/models/search_filter.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';
import '../../infrastructure/local_database/local_wishlist_repository.dart';
import '../../shared/errors/app_error.dart';
import '../../shared/route_observer.dart';
import '../widgets/rate_limit_retry_button.dart';
import '../widgets/release_search_result_card.dart';
import 'release_detail_screen.dart';

const _kWideBreakpoint = 700.0;

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _SearchState {
  const _SearchState();
}

class _Idle extends _SearchState {
  const _Idle();
}

class _Loading extends _SearchState {
  const _Loading();
}

/// Stable results state. Also used for the "loading more" and "pagination
/// error" sub-states via [isLoadingMore] and [paginationError].
class _Results extends _SearchState {
  const _Results({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalResults,
    this.isLoadingMore = false,
    this.paginationError,
    this.fromCache = false,
  });

  final List<ReleaseSearchResult> items;
  final int currentPage;
  final int totalPages;
  final int totalResults;
  final bool isLoadingMore;
  final AppError? paginationError;
  // True while a background network refresh is pending or after it failed.
  final bool fromCache;

  bool get hasMore => currentPage < totalPages;

  _Results copyWith({
    List<ReleaseSearchResult>? items,
    int? currentPage,
    int? totalPages,
    int? totalResults,
    bool? isLoadingMore,
    AppError? paginationError,
    bool clearPaginationError = false,
    bool? fromCache,
  }) {
    return _Results(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalResults: totalResults ?? this.totalResults,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: clearPaginationError
          ? null
          : (paginationError ?? this.paginationError),
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class _SearchError extends _SearchState {
  const _SearchError(this.error);
  final AppError error;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.searchService,
    this.addToCollectionUseCase,
    this.addToWishlistUseCase,
    this.cacheRepository,
    this.queryCache,
    this.collectionRepository,
    this.wishlistRepository,
  });

  final DiscogsSearchService? searchService;
  final AddToCollectionUseCase? addToCollectionUseCase;
  final AddToWishlistUseCase? addToWishlistUseCase;
  final CachedReleaseMetadataRepository? cacheRepository;
  final SearchQueryCache? queryCache;
  final CollectionRepository? collectionRepository;
  final WishlistRepository? wishlistRepository;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with RouteAware {
  late final DiscogsSearchService _service;
  late final SearchQueryCache _cache;
  late final CollectionRepository _collectionRepository;
  late final WishlistRepository _wishlistRepository;
  AppDatabase? _ownedDb;
  final _controller = TextEditingController();
  _SearchState _state = const _Idle();
  Timer? _debounce;
  String _lastQuery = '';
  // Selected search-scope filter (US-84). All = no chip selected = search every
  // field. US-84 only holds the state; US-85 will scope the query to it.
  SearchFilter _filter = SearchFilter.all;
  ReleaseSearchResult? _selectedResult;
  int _searchGeneration = 0;
  // Discogs release ids the user already has locally. Loaded once and refreshed
  // on return from a detail screen — never per card (US-80).
  Set<int> _collectionIds = const {};
  Set<int> _wishlistIds = const {};

  @override
  void initState() {
    super.initState();
    _service = widget.searchService ?? DiscogsSearchService();
    _cache = widget.queryCache ?? SearchQueryCache();
    if (widget.collectionRepository != null &&
        widget.wishlistRepository != null) {
      _collectionRepository = widget.collectionRepository!;
      _wishlistRepository = widget.wishlistRepository!;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _collectionRepository =
          widget.collectionRepository ?? LocalCollectionRepository(db);
      _wishlistRepository =
          widget.wishlistRepository ?? LocalWishlistRepository(db);
    }
    _controller.addListener(_onQueryChanged);
    _loadMembership();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) searchRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => _loadMembership();

  /// Resolves which results are already in the collection / on the wishlist.
  /// A storage failure degrades to "no icons" rather than breaking search.
  Future<void> _loadMembership() async {
    try {
      final collection = await _collectionRepository.getAll();
      final wishlist = await _wishlistRepository.getAll();
      if (!mounted) return;
      setState(() {
        _collectionIds = collection.map((i) => i.discogsReleaseId).toSet();
        _wishlistIds = wishlist.map((i) => i.discogsReleaseId).toSet();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _collectionIds = const {};
        _wishlistIds = const {};
      });
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      _lastQuery = '';
      setState(() {
        _state = const _Idle();
        _selectedResult = null;
      });
      return;
    }
    setState(() {}); // rebuild clear button
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _onSubmit(query),
    );
  }

  Future<void> _onSubmit(String query) async {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    // Only skip if we already have fresh (non-cached) results for this query.
    final alreadyHasFreshResults =
        _state is _Results &&
        !(_state as _Results).isLoadingMore &&
        !(_state as _Results).fromCache;
    if (trimmed == _lastQuery &&
        (_state is _Loading || alreadyHasFreshResults)) {
      return;
    }
    _lastQuery = trimmed;
    final gen = ++_searchGeneration;

    // Check cache first — show immediately and refresh in background.
    final cacheKey = SearchQueryCache.normalizeKey(trimmed);
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      setState(() {
        _state = _Results(
          items: cached.items,
          currentPage: cached.currentPage,
          totalPages: cached.totalPages,
          totalResults: cached.totalResults,
          fromCache: true,
        );
        _selectedResult = null;
      });
      _searchInBackground(trimmed, cacheKey, gen);
      return;
    }

    setState(() {
      _state = const _Loading();
      _selectedResult = null;
    });
    try {
      final page = await _service.search(trimmed);
      if (!mounted || gen != _searchGeneration) return;
      _cache.put(cacheKey, page);
      setState(
        () => _state = _Results(
          items: page.items,
          currentPage: page.currentPage,
          totalPages: page.totalPages,
          totalResults: page.totalResults,
        ),
      );
    } on AppError catch (e) {
      if (!mounted || gen != _searchGeneration) return;
      setState(() => _state = _SearchError(e));
    }
  }

  Future<void> _searchInBackground(
    String query,
    String cacheKey,
    int gen,
  ) async {
    try {
      final page = await _service.search(query);
      if (!mounted || gen != _searchGeneration) return;
      _cache.put(cacheKey, page);
      setState(
        () => _state = _Results(
          items: page.items,
          currentPage: page.currentPage,
          totalPages: page.totalPages,
          totalResults: page.totalResults,
        ),
      );
    } on AppError {
      // Silently keep the cached results; fromCache: true banner stays visible.
    }
  }

  Future<void> _loadMore() async {
    if (_state is! _Results) return;
    final current = _state as _Results;
    if (!current.hasMore || current.isLoadingMore) return;

    final gen = _searchGeneration;
    setState(
      () => _state = current.copyWith(
        isLoadingMore: true,
        clearPaginationError: true,
      ),
    );

    try {
      final page = await _service.search(
        _lastQuery,
        page: current.currentPage + 1,
      );
      if (!mounted || gen != _searchGeneration) return;
      setState(
        () => _state = _Results(
          items: [...current.items, ...page.items],
          currentPage: page.currentPage,
          totalPages: page.totalPages,
          totalResults: page.totalResults,
        ),
      );
    } on AppError catch (e) {
      if (!mounted || gen != _searchGeneration) return;
      setState(
        () =>
            _state = current.copyWith(isLoadingMore: false, paginationError: e),
      );
    }
  }

  @override
  void dispose() {
    searchRouteObserver.unsubscribe(this);
    _debounce?.cancel();
    _controller.dispose();
    _ownedDb?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = _controller.text.isNotEmpty;
    final isWide = MediaQuery.sizeOf(context).width >= _kWideBreakpoint;

    final searchPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _controller,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.search,
            onSubmitted: _onSubmit,
            decoration: InputDecoration(
              hintText: 'Artist, album, or label…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: _controller.clear,
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
        _SearchFilterChips(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        Expanded(child: _buildBody(isWide: isWide)),
      ],
    );

    if (!isWide) return searchPane;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 320, child: searchPane),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: _selectedResult != null
              ? ReleaseDetailScreen(
                  key: ValueKey(_selectedResult!.id),
                  releaseId: _selectedResult!.id,
                  initialArtist: _selectedResult!.artist,
                  initialTitle: _selectedResult!.title,
                  addToCollectionUseCase: widget.addToCollectionUseCase,
                  addToWishlistUseCase: widget.addToWishlistUseCase,
                  cacheRepository: widget.cacheRepository,
                )
              : const _NoSelectionPlaceholder(),
        ),
      ],
    );
  }

  Widget _buildBody({required bool isWide}) {
    if (_controller.text.isEmpty) return const _EmptyState();
    return switch (_state) {
      _Idle() => const _EmptyState(),
      _Loading() => const _LoadingIndicator(),
      _Results(:final items) when items.isEmpty => const _NoResultsState(),
      _Results(
        :final items,
        :final totalResults,
        :final isLoadingMore,
        :final paginationError,
        :final hasMore,
        :final fromCache,
      ) =>
        _ResultsList(
          items: items,
          totalResults: totalResults,
          isLoadingMore: isLoadingMore,
          paginationError: paginationError,
          onLoadMore: hasMore && !isLoadingMore ? _loadMore : null,
          onRetry: _loadMore,
          fromCache: fromCache,
          collectionIds: _collectionIds,
          wishlistIds: _wishlistIds,
          onResultTap: (result) {
            if (isWide) {
              setState(() => _selectedResult = result);
            } else {
              context.push(
                AppRoutes.searchRelease(
                  result.id,
                  artist: result.artist,
                  title: result.title,
                ),
              );
            }
          },
        ),
      _SearchError(:final error) => _SearchErrorState(
        error: error,
        onRetry: error is NoTokenError || error is InvalidTokenError
            ? null
            : () => _onSubmit(_lastQuery),
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Filter chips (US-84)
// ---------------------------------------------------------------------------

/// Release / Artist / Label scope chips shown under the search field. Single-
/// choice: selecting one deselects the others; tapping the active chip returns
/// to "All" (no chip selected). The row wraps rather than overflowing on a
/// narrow phone or in the 320dp wide-layout search pane.
class _SearchFilterChips extends StatelessWidget {
  const _SearchFilterChips({required this.selected, required this.onChanged});

  final SearchFilter selected;
  final ValueChanged<SearchFilter> onChanged;

  static const _choices = [
    SearchFilter.release,
    SearchFilter.artist,
    SearchFilter.label,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final filter in _choices)
            FilterChip(
              key: Key('search-filter-chip-${filter.name}'),
              label: Text(filter.chipLabel),
              selected: selected == filter,
              onSelected: (isSelected) =>
                  onChanged(isSelected ? filter : SearchFilter.all),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.search,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('Search Discogs', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Type an artist, album, or label name to search.',
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

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

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
            Text('No results', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Try a different search term.',
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

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({required this.error, this.onRetry});

  final AppError error;
  final VoidCallback? onRetry;

  String get _message => switch (error) {
    NoTokenError() => 'Connect a Discogs token in Settings to search.',
    InvalidTokenError() =>
      'Your Discogs token is not valid. Go to Settings to reconnect.',
    RateLimitedError() => 'Too many requests. Wait a moment and try again.',
    NetworkError() =>
      'No internet connection. Your collection and wishlist are still available offline.',
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

class _NoSelectionPlaceholder extends StatelessWidget {
  const _NoSelectionPlaceholder();

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
            Text('Select a result', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap a search result to view its details.',
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

// ---------------------------------------------------------------------------
// Paginated results list
// ---------------------------------------------------------------------------

class _ResultsList extends StatefulWidget {
  const _ResultsList({
    required this.items,
    required this.totalResults,
    required this.isLoadingMore,
    required this.paginationError,
    required this.onLoadMore,
    required this.onRetry,
    required this.onResultTap,
    required this.fromCache,
    required this.collectionIds,
    required this.wishlistIds,
  });

  final List<ReleaseSearchResult> items;
  final int totalResults;
  final bool isLoadingMore;
  final AppError? paginationError;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final ValueChanged<ReleaseSearchResult> onResultTap;
  final bool fromCache;
  final Set<int> collectionIds;
  final Set<int> wishlistIds;

  @override
  State<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<_ResultsList> {
  final _scrollController = ScrollController();
  Timer? _rateLimitTimer;
  int _rateLimitSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.paginationError is RateLimitedError) _startRateLimitCountdown();
    // If the first page fits entirely within the viewport, the scroll listener
    // never fires. Check after the first frame so we can pre-fetch page 2.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  @override
  void didUpdateWidget(_ResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // onLoadMore becoming available means we just finished loading — check
    // again in case the new items still don't require scrolling.
    if (oldWidget.onLoadMore == null && widget.onLoadMore != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onScroll();
      });
    }
    if (oldWidget.paginationError is! RateLimitedError &&
        widget.paginationError is RateLimitedError) {
      _startRateLimitCountdown();
    } else if (oldWidget.paginationError is RateLimitedError &&
        widget.paginationError is! RateLimitedError) {
      _cancelRateLimitTimer();
    }
  }

  void _startRateLimitCountdown() {
    _cancelRateLimitTimer();
    setState(() => _rateLimitSecondsLeft = kRateLimitCountdownSeconds);
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_rateLimitSecondsLeft > 1) {
          _rateLimitSecondsLeft--;
        } else {
          _rateLimitSecondsLeft = 0;
          _cancelRateLimitTimer();
        }
      });
    });
  }

  void _cancelRateLimitTimer() {
    _rateLimitTimer?.cancel();
    _rateLimitTimer = null;
  }

  void _onScroll() {
    if (widget.onLoadMore == null || widget.isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      widget.onLoadMore!();
    }
  }

  @override
  void dispose() {
    _cancelRateLimitTimer();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFooter(BuildContext context) {
    if (widget.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(key: Key('pagination-loading')),
        ),
      );
    }
    if (widget.paginationError != null) {
      final counting =
          widget.paginationError is RateLimitedError &&
          _rateLimitSecondsLeft > 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextButton.icon(
          key: const Key('pagination-retry'),
          onPressed: counting ? null : widget.onRetry,
          icon: Icon(counting ? Icons.hourglass_empty : Icons.refresh),
          label: Text(
            counting
                ? 'Retry in $_rateLimitSecondsLeft s'
                : widget.paginationError is RateLimitedError
                ? 'Retry'
                : 'Failed to load more — tap to retry',
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countText = '1–${widget.items.length} of ${widget.totalResults}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.fromCache) const _CachedResultsBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            countText,
            key: const Key('result-count'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: widget.items.length + 1,
            separatorBuilder: (_, index) => index < widget.items.length - 1
                ? const SizedBox(height: 8)
                : const SizedBox.shrink(),
            itemBuilder: (context, index) {
              if (index == widget.items.length) return _buildFooter(context);
              final item = widget.items[index];
              return ReleaseSearchResultCard(
                result: item,
                onTap: () => widget.onResultTap(item),
                inCollection: widget.collectionIds.contains(item.id),
                onWishlist: widget.wishlistIds.contains(item.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cached results banner
// ---------------------------------------------------------------------------

class _CachedResultsBanner extends StatelessWidget {
  const _CachedResultsBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('cached-results-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.secondaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing saved results',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

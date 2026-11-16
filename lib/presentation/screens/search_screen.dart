import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../app/app_repositories.dart';
import '../../app/router.dart';
import '../../app/search_preferences.dart';
import '../../application/services/discogs_search_service.dart';
import '../../application/services/search_query_cache.dart';
import '../../application/use_cases/add_to_collection_use_case.dart';
import '../../application/use_cases/add_to_wishlist_use_case.dart';
import '../../domain/models/release_search_result.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/models/search_filter.dart';
import '../../domain/models/search_sort.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/saved_search_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/errors/app_error.dart';
import '../../shared/route_observer.dart';
import '../../shared/tab_reselect_notifier.dart';
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

/// A search to run when the Search tab opens, e.g. "all releases of this
/// label" from a release detail (US-134). Passed as the route's `extra`.
/// Compared by identity: every tap creates a new request, so tapping the same
/// label twice still re-runs the search.
class SearchRequest {
  const SearchRequest({
    required this.query,
    this.filter = SearchFilter.all,
    this.sort = SearchSort.relevance,
  });

  final String query;
  final SearchFilter filter;
  final SearchSort sort;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.request,
    this.searchService,
    this.addToCollectionUseCase,
    this.addToWishlistUseCase,
    this.cacheRepository,
    this.queryCache,
    this.collectionRepository,
    this.wishlistRepository,
    this.accelerometerStream,
    this.savedSearchRepository,
    this.loadVinylOnly,
    this.saveVinylOnly,
  });

  final SearchRequest? request;
  final DiscogsSearchService? searchService;
  final AddToCollectionUseCase? addToCollectionUseCase;
  final AddToWishlistUseCase? addToWishlistUseCase;
  final CachedReleaseMetadataRepository? cacheRepository;
  final SearchQueryCache? queryCache;
  final CollectionRepository? collectionRepository;
  final WishlistRepository? wishlistRepository;
  final Stream<AccelerometerEvent>? accelerometerStream;
  final SavedSearchRepository? savedSearchRepository;
  // Injected only in tests; production reads/writes the stored preference.
  final Future<bool> Function()? loadVinylOnly;
  final Future<void> Function(bool)? saveVinylOnly;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with RouteAware {
  late final DiscogsSearchService _service;
  late final SearchQueryCache _cache;
  CollectionRepository? _collectionRepository;
  WishlistRepository? _wishlistRepository;
  SavedSearchRepository? _savedSearchRepository;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _listenedText = '';
  _SearchState _state = const _Idle();
  Timer? _debounce;
  String _lastQuery = '';
  // Selected search-scope filter (US-84/US-85). All = no chip selected = search
  // every field via the general `q` query.
  SearchFilter _filter = SearchFilter.all;
  // Filter of the search currently shown — paired with [_lastQuery] so the
  // skip-guard and pagination/background refresh stay on the same filter (US-85).
  SearchFilter _lastFilter = SearchFilter.all;
  // Result order (US-133), paired with [_lastSort] the same way. Unlike the
  // filter it survives clearing the field: it is a preference, not a scope.
  SearchSort _sort = SearchSort.relevance;
  SearchSort _lastSort = SearchSort.relevance;
  // Limit results to vinyl (US-142). A persisted preference, so like the sort
  // it survives clearing the field. [_vinylOnlyTouched] stops the async
  // preference load from overriding a toggle the user already made.
  bool _vinylOnly = false;
  bool _lastVinylOnly = false;
  bool _vinylOnlyTouched = false;
  ReleaseSearchResult? _selectedResult;
  int _searchGeneration = 0;
  // Discogs release ids the user already has locally. Loaded once and refreshed
  // on return from a detail screen — never per card (US-80).
  Set<int> _collectionIds = const {};
  Set<int> _wishlistIds = const {};

  // Easter egg: shake → Rick Astley (US-109).
  static const _kShakeThreshold = 20.0; // m/s²
  static const _kShakeCooldown = Duration(seconds: 2);
  static const _kRickAstleyReleaseId = 1758356;
  StreamSubscription<AccelerometerEvent>? _shakeSub;
  DateTime _lastShake = DateTime(0);
  bool _shakeActive = true;

  @override
  void initState() {
    super.initState();
    _service = widget.searchService ?? DiscogsSearchService();
    _cache = widget.queryCache ?? SearchQueryCache();
    final repos = AppRepositoriesScope.maybeOf(context);
    _collectionRepository = widget.collectionRepository ?? repos?.collection;
    _wishlistRepository = widget.wishlistRepository ?? repos?.wishlist;
    _savedSearchRepository = widget.savedSearchRepository ?? repos?.savedSearch;
    _controller.addListener(_onQueryChanged);
    searchTabReselectedNotifier.addListener(_onTabReselected);
    _loadMembership();
    _loadVinylOnly();
    _shakeSub = (widget.accelerometerStream ?? accelerometerEventStream())
        .listen(_onAccelerometer);
    if (widget.request != null) _applyRequest(widget.request!);
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab keeps its state, so a new request arrives as a widget update.
    final request = widget.request;
    if (request != null && !identical(request, oldWidget.request)) {
      _applyRequest(request);
    }
  }

  void _onTabReselected() {
    if (!mounted) return;
    // A release detail is still on top: this tap only takes the user back to
    // the results (the shell pops it), nothing is cleared yet.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _resetSearch();
  }

  /// Starts a fresh search (US-139): empty box, idle state, keyboard focus.
  /// Unlike the clear button this keeps the scope chip and the sort, and it
  /// drops any search still in flight.
  void _resetSearch() {
    _debounce?.cancel();
    _searchGeneration++; // results of an in-flight search are discarded
    // Mark '' as already seen so the controller listener doesn't treat this
    // as a user edit (which would reset the scope to All).
    _listenedText = '';
    _controller.clear();
    _lastQuery = '';
    setState(() {
      _state = const _Idle();
      _selectedResult = null;
    });
    _focusNode.requestFocus();
  }

  /// Replaces the current search with [request] (US-134): text, scope and
  /// order all come from the request; the vinyl-only preference is kept.
  void _applyRequest(SearchRequest request) {
    _controller.text = request.query;
    setState(() {
      _filter = request.filter;
      _sort = request.sort;
      _selectedResult = null;
    });
    _onSubmit(request.query);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) searchRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => _shakeActive = false;

  @override
  void didPopNext() {
    _shakeActive = true;
    _loadMembership();
  }

  Future<void> _loadVinylOnly() async {
    final vinylOnly = await (widget.loadVinylOnly ?? loadVinylOnlyPreference)();
    if (!mounted || _vinylOnlyTouched || vinylOnly == _vinylOnly) return;
    setState(() => _vinylOnly = vinylOnly);
    final text = _controller.text.trim();
    if (text.isNotEmpty) _onSubmit(text);
  }

  void _setVinylOnly(bool vinylOnly) {
    _vinylOnlyTouched = true;
    setState(() => _vinylOnly = vinylOnly);
    (widget.saveVinylOnly ?? saveVinylOnlyPreference)(vinylOnly);
    // Re-run from page 1 like a filter or sort change.
    final text = _controller.text.trim();
    if (text.isNotEmpty) _onSubmit(text);
  }

  /// Resolves which results are already in the collection / on the wishlist.
  /// A storage failure degrades to "no icons" rather than breaking search.
  Future<void> _loadMembership() async {
    if (_collectionRepository == null || _wishlistRepository == null) return;
    try {
      final collection = await _collectionRepository!.getAll();
      final wishlist = await _wishlistRepository!.getAll();
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
    // The controller also notifies on cursor/selection changes — e.g. focusing
    // the empty field places the cursor. Only text edits may reset the scope,
    // otherwise tapping into the field after picking a chip drops the chip.
    if (_controller.text == _listenedText) return;
    _listenedText = _controller.text;
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      _lastQuery = '';
      // Clearing the field resets the scope back to All (US-84/US-85).
      _lastFilter = SearchFilter.all;
      setState(() {
        _state = const _Idle();
        _selectedResult = null;
        _filter = SearchFilter.all;
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
    final filter = _filter;
    final sort = _sort;
    final vinylOnly = _vinylOnly;
    // Only skip if we already have fresh (non-cached) results for this exact
    // query, filter *and* sort — changing either with identical text must
    // re-search.
    final alreadyHasFreshResults =
        _state is _Results &&
        !(_state as _Results).isLoadingMore &&
        !(_state as _Results).fromCache;
    if (trimmed == _lastQuery &&
        filter == _lastFilter &&
        sort == _lastSort &&
        vinylOnly == _lastVinylOnly &&
        (_state is _Loading || alreadyHasFreshResults)) {
      return;
    }
    _lastQuery = trimmed;
    _lastFilter = filter;
    _lastSort = sort;
    _lastVinylOnly = vinylOnly;
    final gen = ++_searchGeneration;

    // Check cache first — show immediately and refresh in background. The key
    // is scoped by filter and sort so "All" and "Artist" results, or the same
    // results in another order, don't collide (US-85, US-133).
    final cacheKey = SearchQueryCache.normalizeKey(
      trimmed,
      filter,
      sort,
      vinylOnly,
    );
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
      _searchInBackground(trimmed, cacheKey, gen, filter, sort, vinylOnly);
      return;
    }

    setState(() {
      _state = const _Loading();
      _selectedResult = null;
    });
    try {
      final page = await _service.search(
        trimmed,
        filter: filter,
        sort: sort,
        vinylOnly: vinylOnly,
      );
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
    SearchFilter filter,
    SearchSort sort,
    bool vinylOnly,
  ) async {
    try {
      final page = await _service.search(
        query,
        filter: filter,
        sort: sort,
        vinylOnly: vinylOnly,
      );
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
        filter: _lastFilter,
        sort: _lastSort,
        vinylOnly: _lastVinylOnly,
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
    _shakeSub?.cancel();
    searchTabReselectedNotifier.removeListener(_onTabReselected);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentSearch() async {
    final repo = _savedSearchRepository;
    if (repo == null) return;
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save search'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search name'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    await repo.save(
      SavedSearch(
        id: const Uuid().v4(),
        name: name,
        type: SavedSearchType.discogsSearch,
        payloadJson: jsonEncode({
          'query': query,
          'filter': _filter.name,
          'schemaVersion': 1,
        }),
        schemaVersion: 1,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search "$name" saved')));
    }
  }

  Future<void> _loadSavedSearch() async {
    final result = await context.push<SavedSearch>(
      AppRoutes.savedSearches,
      extra: SavedSearchType.discogsSearch,
    );
    if (result == null || !mounted) return;
    final payload = jsonDecode(result.payloadJson) as Map<String, dynamic>;
    final query = payload['query'] as String;
    final filter = SearchFilter.values.byName(
      payload['filter'] as String? ?? SearchFilter.all.name,
    );
    _controller.text = query;
    setState(() => _filter = filter);
    _savedSearchRepository?.updateLastUsed(result.id, DateTime.now());
    _onSubmit(query);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!mounted || !_shakeActive) return;
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null && shell.currentIndex != 0) return;
    final x = event.x, y = event.y, z = event.z;
    if (sqrt(x * x + y * y + z * z) < _kShakeThreshold) return;
    final now = DateTime.now();
    if (now.difference(_lastShake) < _kShakeCooldown) return;
    _lastShake = now;
    context.go(AppRoutes.searchRelease(_kRickAstleyReleaseId));
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
          padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSubmit,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: AppLocalizations.of(
                              context,
                            )!.searchClearTooltip,
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
              if (hasQuery)
                IconButton(
                  key: const Key('save-search-button'),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: 'Save search',
                  onPressed: _saveCurrentSearch,
                ),
              IconButton(
                key: const Key('load-saved-search-button'),
                icon: const Icon(Icons.bookmarks_outlined),
                tooltip: 'Saved searches',
                onPressed: _loadSavedSearch,
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SearchFilterChips(
                vinylOnly: _vinylOnly,
                onVinylOnlyChanged: _setVinylOnly,
                selected: _filter,
                onChanged: (f) {
                  setState(() => _filter = f);
                  // Re-run the current search immediately under the new scope
                  // (US-85) — the user shouldn't have to re-type. The
                  // skip-guard compares the filter, so identical text still
                  // re-searches.
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) _onSubmit(text);
                },
              ),
            ),
            _SearchSortMenu(
              selected: _sort,
              onChanged: (s) {
                setState(() => _sort = s);
                // Same as a filter change: re-run from page 1 in the new
                // order (US-133).
                final text = _controller.text.trim();
                if (text.isNotEmpty) _onSubmit(text);
              },
            ),
          ],
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
      _Results(:final items) when items.isEmpty => _NoResultsState(
        onShowAllFormats: _lastVinylOnly ? () => _setVinylOnly(false) : null,
      ),
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
  const _SearchFilterChips({
    required this.selected,
    required this.onChanged,
    required this.vinylOnly,
    required this.onVinylOnlyChanged,
  });

  final SearchFilter selected;
  final ValueChanged<SearchFilter> onChanged;
  // Independent on/off toggle (US-142), combinable with any scope chip.
  final bool vinylOnly;
  final ValueChanged<bool> onVinylOnlyChanged;

  static const _choices = [
    SearchFilter.release,
    SearchFilter.artist,
    SearchFilter.label,
  ];

  String _filterLabel(BuildContext context, SearchFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    return switch (filter) {
      SearchFilter.release => l10n.searchFilterRelease,
      SearchFilter.artist => l10n.searchFilterArtist,
      SearchFilter.label => l10n.searchFilterLabel,
      SearchFilter.all => '',
    };
  }

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
              label: Text(_filterLabel(context, filter)),
              selected: selected == filter,
              onSelected: (isSelected) =>
                  onChanged(isSelected ? filter : SearchFilter.all),
            ),
          FilterChip(
            key: const Key('search-vinyl-only-chip'),
            avatar: vinylOnly ? null : const Icon(Icons.album, size: 18),
            label: Text(AppLocalizations.of(context)!.searchVinylOnly),
            selected: vinylOnly,
            onSelected: onVinylOnlyChanged,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort menu (US-133)
// ---------------------------------------------------------------------------

/// Compact menu next to the filter chips that picks the result order. Shows
/// the current order as text so a non-default sort is visible at a glance.
class _SearchSortMenu extends StatelessWidget {
  const _SearchSortMenu({required this.selected, required this.onChanged});

  final SearchSort selected;
  final ValueChanged<SearchSort> onChanged;

  static String label(AppLocalizations l10n, SearchSort sort) => switch (sort) {
    SearchSort.relevance => l10n.searchSortRelevance,
    SearchSort.newestFirst => l10n.searchSortNewestFirst,
    SearchSort.oldestFirst => l10n.searchSortOldestFirst,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<SearchSort>(
        key: const Key('search-sort-button'),
        tooltip: l10n.searchSortTooltip,
        initialValue: selected,
        onSelected: (s) {
          if (s != selected) onChanged(s);
        },
        itemBuilder: (_) => [
          for (final sort in SearchSort.values)
            CheckedPopupMenuItem(
              key: Key('search-sort-option-${sort.name}'),
              value: sort,
              checked: sort == selected,
              child: Text(label(l10n, sort)),
            ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  label(l10n, selected),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    // Scrollable so the message never overflows when the chip rows wrap in
    // the narrow wide-layout pane on a short screen.
    return Center(
      child: SingleChildScrollView(
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
            Text(
              AppLocalizations.of(context)!.searchEmptyTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.searchEmptyBody,
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
  const _NoResultsState({this.onShowAllFormats});

  /// Set when the empty result came from a vinyl-only search (US-142): the
  /// message names the filter and offers to switch it off.
  final VoidCallback? onShowAllFormats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scrollable so the message never overflows when the chip rows wrap in
    // the narrow wide-layout pane on a short screen.
    return Center(
      child: SingleChildScrollView(
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
              AppLocalizations.of(context)!.searchNoResultsTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              onShowAllFormats != null
                  ? AppLocalizations.of(context)!.searchNoResultsVinylOnlyBody
                  : AppLocalizations.of(context)!.searchNoResultsBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onShowAllFormats != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('search-show-all-formats-button'),
                onPressed: onShowAllFormats,
                child: Text(AppLocalizations.of(context)!.searchShowAllFormats),
              ),
            ],
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
    // Scrollable so the message never overflows when the chip rows wrap in
    // the narrow wide-layout pane on a short screen.
    return Center(
      child: SingleChildScrollView(
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
            Text(
              AppLocalizations.of(context)!.searchSelectResultTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.searchSelectResultBody,
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
              AppLocalizations.of(context)!.cachedResultsBanner,
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

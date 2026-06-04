import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/services/discogs_search_service.dart';
import '../../application/use_cases/add_to_collection_use_case.dart';
import '../../application/use_cases/add_to_wishlist_use_case.dart';
import '../../domain/models/release_search_result.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../shared/errors/app_error.dart';
import '../widgets/release_search_result_card.dart';
import 'release_detail_screen.dart';

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
  });

  final List<ReleaseSearchResult> items;
  final int currentPage;
  final int totalPages;
  final int totalResults;
  final bool isLoadingMore;
  final AppError? paginationError;

  bool get hasMore => currentPage < totalPages;

  _Results copyWith({
    List<ReleaseSearchResult>? items,
    int? currentPage,
    int? totalPages,
    int? totalResults,
    bool? isLoadingMore,
    AppError? paginationError,
    bool clearPaginationError = false,
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
  });

  final DiscogsSearchService? searchService;
  final AddToCollectionUseCase? addToCollectionUseCase;
  final AddToWishlistUseCase? addToWishlistUseCase;
  final CachedReleaseMetadataRepository? cacheRepository;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final DiscogsSearchService _service;
  final _controller = TextEditingController();
  _SearchState _state = const _Idle();
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _service = widget.searchService ?? DiscogsSearchService();
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      _lastQuery = '';
      setState(() => _state = const _Idle());
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
    final alreadyHasResults =
        _state is _Results && !(_state as _Results).isLoadingMore;
    if (trimmed == _lastQuery && (_state is _Loading || alreadyHasResults)) {
      return;
    }
    _lastQuery = trimmed;
    setState(() => _state = const _Loading());
    try {
      final page = await _service.search(trimmed);
      if (!mounted) return;
      setState(
        () => _state = _Results(
          items: page.items,
          currentPage: page.currentPage,
          totalPages: page.totalPages,
          totalResults: page.totalResults,
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _state = _SearchError(e));
    }
  }

  Future<void> _loadMore() async {
    if (_state is! _Results) return;
    final current = _state as _Results;
    if (!current.hasMore || current.isLoadingMore) return;

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
      if (!mounted) return;
      setState(
        () => _state = _Results(
          items: [...current.items, ...page.items],
          currentPage: page.currentPage,
          totalPages: page.totalPages,
          totalResults: page.totalResults,
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _state = current.copyWith(isLoadingMore: false, paginationError: e),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = _controller.text.isNotEmpty;

    return Column(
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
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
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
      ) =>
        _ResultsList(
          items: items,
          totalResults: totalResults,
          isLoadingMore: isLoadingMore,
          paginationError: paginationError,
          onLoadMore: hasMore && !isLoadingMore ? _loadMore : null,
          onRetry: _loadMore,
          addToCollectionUseCase: widget.addToCollectionUseCase,
          addToWishlistUseCase: widget.addToWishlistUseCase,
          cacheRepository: widget.cacheRepository,
        ),
      _SearchError(:final error) => _SearchErrorState(error: error),
    };
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
  const _SearchErrorState({required this.error});

  final AppError error;

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
    this.addToCollectionUseCase,
    this.addToWishlistUseCase,
    this.cacheRepository,
  });

  final List<ReleaseSearchResult> items;
  final int totalResults;
  final bool isLoadingMore;
  final AppError? paginationError;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final AddToCollectionUseCase? addToCollectionUseCase;
  final AddToWishlistUseCase? addToWishlistUseCase;
  final CachedReleaseMetadataRepository? cacheRepository;

  @override
  State<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<_ResultsList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      final isRateLimit = widget.paginationError is RateLimitedError;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextButton.icon(
          key: const Key('pagination-retry'),
          onPressed: widget.onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(
            isRateLimit
                ? 'Rate limited — tap to retry'
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReleaseDetailScreen(
                      releaseId: item.id,
                      initialArtist: item.artist,
                      initialTitle: item.title,
                      addToCollectionUseCase: widget.addToCollectionUseCase,
                      addToWishlistUseCase: widget.addToWishlistUseCase,
                      cacheRepository: widget.cacheRepository,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

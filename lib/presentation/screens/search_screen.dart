import 'package:flutter/material.dart';

import '../../application/services/discogs_search_service.dart';
import '../../domain/models/release_search_result.dart';
import '../../shared/errors/app_error.dart';
import '../widgets/release_search_result_card.dart';

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

class _Results extends _SearchState {
  const _Results(this.items);
  final List<ReleaseSearchResult> items;
}

class _SearchError extends _SearchState {
  const _SearchError(this.error);
  final AppError error;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.searchService});

  final DiscogsSearchService? searchService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final DiscogsSearchService _service;
  final _controller = TextEditingController();
  _SearchState _state = const _Idle();

  @override
  void initState() {
    super.initState();
    _service = widget.searchService ?? DiscogsSearchService();
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    if (_controller.text.isEmpty) {
      setState(() => _state = const _Idle());
    } else {
      setState(() {});
    }
  }

  Future<void> _onSubmit(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _state = const _Loading());
    try {
      final results = await _service.search(query);
      if (!mounted) return;
      setState(() => _state = _Results(results));
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _state = _SearchError(e));
    }
  }

  @override
  void dispose() {
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
      _Results(:final items) => _ResultsList(items: items),
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
              'Type an artist, album, or label name and press Search.',
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
        NoTokenError() =>
          'Connect a Discogs token in Settings to search.',
        InvalidTokenError() =>
          'Your Discogs token is not valid. Go to Settings to reconnect.',
        RateLimitedError() =>
          'Too many requests. Wait a moment and try again.',
        NetworkError() => 'No internet connection.',
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
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
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

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.items});

  final List<ReleaseSearchResult> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) =>
          ReleaseSearchResultCard(result: items[index]),
    );
  }
}

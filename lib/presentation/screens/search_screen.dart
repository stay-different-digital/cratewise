import 'package:flutter/material.dart';

import '../../domain/models/release_search_result.dart';
import '../widgets/release_search_result_card.dart';

// Placeholder data — replaced with Discogs API results in a later slice.
const _fakeResults = <ReleaseSearchResult>[
  ReleaseSearchResult(
    id: 249504,
    title: 'Kind of Blue',
    artist: 'Miles Davis',
    format: 'LP',
    label: 'Columbia',
    year: 1959,
    country: 'US',
  ),
  ReleaseSearchResult(
    id: 14524953,
    title: 'Abbey Road',
    artist: 'The Beatles',
    format: 'LP',
    label: 'Apple Records',
    year: 1969,
    country: 'UK',
  ),
  ReleaseSearchResult(
    id: 4657838,
    title: 'Random Access Memories',
    artist: 'Daft Punk',
    format: '2xLP',
    label: 'Columbia',
    year: 2013,
    country: 'EU',
  ),
  ReleaseSearchResult(
    id: 870481,
    title: 'Back to Black',
    artist: 'Amy Winehouse',
    format: 'LP',
    label: 'Island Records',
    year: 2006,
    country: 'UK',
  ),
  ReleaseSearchResult(
    id: 7528137,
    title: 'Music Has the Right to Children',
    artist: 'Boards of Canada',
    format: '2xLP',
    label: 'Warp Records',
    year: 1998,
    country: 'UK',
  ),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() => setState(() {});

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
        Expanded(
          child:
              hasQuery ? const _ResultsList() : const _EmptyState(),
        ),
      ],
    );
  }
}

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
              'Type an artist, album, or label name to get started.',
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
  const _ResultsList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _fakeResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) =>
          ReleaseSearchResultCard(result: _fakeResults[index]),
    );
  }
}

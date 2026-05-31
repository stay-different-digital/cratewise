import 'package:flutter/material.dart';

import '../../domain/models/collection_item.dart';
import '../widgets/collection_item_card.dart';

List<CollectionItem> _fakeItems() => [
      CollectionItem(
        id: 'fake-1',
        discogsReleaseId: 249504,
        artist: 'Miles Davis',
        title: 'Kind of Blue',
        label: 'Columbia',
        catno: 'CL 1355',
        format: 'LP',
        country: 'US',
        year: 1959,
        coverUrl: null,
        mediaCondition: RecordCondition.veryGoodPlus,
        sleeveCondition: RecordCondition.veryGood,
        tags: const ['jazz', 'classic'],
        storageLocation: 'Shelf A1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      CollectionItem(
        id: 'fake-2',
        discogsReleaseId: 352310,
        artist: 'Massive Attack',
        title: 'Mezzanine',
        label: 'Virgin',
        catno: null,
        format: 'LP',
        country: 'UK',
        year: 1998,
        coverUrl: null,
        mediaCondition: RecordCondition.nearMint,
        sleeveCondition: RecordCondition.nearMint,
        tags: const [],
        storageLocation: null,
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      ),
      CollectionItem(
        id: 'fake-3',
        discogsReleaseId: 8386,
        artist: 'The Prodigy',
        title: 'Music for the Jilted Generation',
        label: null,
        catno: null,
        format: null,
        country: 'UK',
        year: null,
        coverUrl: null,
        mediaCondition: RecordCondition.veryGood,
        sleeveCondition: RecordCondition.good,
        tags: const [],
        storageLocation: null,
        createdAt: DateTime(2026, 1, 3),
        updatedAt: DateTime(2026, 1, 3),
      ),
    ];

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, this.items});

  final List<CollectionItem>? items;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late final List<CollectionItem> _items;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.items ?? _fakeItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search your collection…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
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
        Expanded(
          child: _items.isEmpty
              ? const _EmptyCollectionState()
              : _CollectionList(items: _items),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _CollectionList extends StatelessWidget {
  const _CollectionList({required this.items});

  final List<CollectionItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => CollectionItemCard(item: items[index]),
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
              'Your collection is empty',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a release on Discogs and tap "Add to Collection" to start building your collection.',
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

import 'package:flutter/material.dart';

import '../../domain/models/wishlist_item.dart';
import '../widgets/wishlist_item_card.dart';

// Placeholder items shown before local storage is connected.
final _kFakeItems = <WishlistItem>[
  WishlistItem(
    id: 'fake-1',
    discogsReleaseId: 249504,
    artist: 'Miles Davis',
    title: 'Kind Of Blue',
    priority: WishlistPriority.mustHave,
    label: 'Columbia',
    year: 1959,
    format: 'Vinyl, LP',
    targetPrice: 45.00,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  WishlistItem(
    id: 'fake-2',
    discogsReleaseId: 870099,
    artist: 'John Coltrane',
    title: 'A Love Supreme',
    priority: WishlistPriority.high,
    label: 'Impulse!',
    year: 1965,
    format: 'Vinyl, LP',
    createdAt: DateTime(2026, 1, 2),
    updatedAt: DateTime(2026, 1, 2),
  ),
  WishlistItem(
    id: 'fake-3',
    discogsReleaseId: 305076,
    artist: 'Aphex Twin',
    title: 'Selected Ambient Works 85-92',
    priority: WishlistPriority.medium,
    year: 1992,
    createdAt: DateTime(2026, 1, 3),
    updatedAt: DateTime(2026, 1, 3),
  ),
];

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key, this.items});

  final List<WishlistItem>? items;

  @override
  Widget build(BuildContext context) {
    final displayItems = items ?? _kFakeItems;
    if (displayItems.isEmpty) return const _EmptyWishlistState();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: displayItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          WishlistItemCard(item: displayItems[index]),
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
              'Your wishlist is empty',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a release on Discogs and tap "Add to Wishlist" to start tracking records you want.',
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

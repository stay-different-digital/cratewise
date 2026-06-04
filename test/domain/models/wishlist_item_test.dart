import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 1, 1);
  final updatedAt = DateTime(2026, 1, 2);

  WishlistItem base() => WishlistItem(
    id: 'wish-1',
    discogsReleaseId: 249504,
    artist: 'Miles Davis',
    title: 'Kind Of Blue',
    priority: WishlistPriority.high,
    createdAt: createdAt,
    updatedAt: updatedAt,
    label: 'Columbia',
    catno: 'CL 1355',
    format: 'Vinyl, LP, Album',
    country: 'US',
    year: 1959,
    coverUrl: 'https://i.discogs.com/cover.jpg',
    targetPrice: 35.00,
    notes: 'Original pressing preferred.',
  );

  group('WishlistItem', () {
    test('stores all required fields', () {
      final item = base();
      expect(item.id, 'wish-1');
      expect(item.discogsReleaseId, 249504);
      expect(item.artist, 'Miles Davis');
      expect(item.title, 'Kind Of Blue');
      expect(item.priority, WishlistPriority.high);
      expect(item.createdAt, createdAt);
      expect(item.updatedAt, updatedAt);
    });

    test('stores all optional fields', () {
      final item = base();
      expect(item.label, 'Columbia');
      expect(item.catno, 'CL 1355');
      expect(item.format, 'Vinyl, LP, Album');
      expect(item.country, 'US');
      expect(item.year, 1959);
      expect(item.coverUrl, 'https://i.discogs.com/cover.jpg');
      expect(item.targetPrice, 35.00);
      expect(item.notes, 'Original pressing preferred.');
    });

    test('optional fields default to null', () {
      final item = WishlistItem(
        id: 'wish-2',
        discogsReleaseId: 1,
        artist: 'Unknown',
        title: 'Untitled',
        priority: WishlistPriority.low,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      expect(item.label, isNull);
      expect(item.catno, isNull);
      expect(item.format, isNull);
      expect(item.country, isNull);
      expect(item.year, isNull);
      expect(item.coverUrl, isNull);
      expect(item.targetPrice, isNull);
      expect(item.notes, isNull);
    });

    group('copyWith', () {
      test('returns equal item when no overrides given', () {
        final item = base();
        final copy = item.copyWith();
        expect(copy.id, item.id);
        expect(copy.title, item.title);
        expect(copy.priority, item.priority);
        expect(copy.targetPrice, item.targetPrice);
      });

      test('overrides specified fields', () {
        final newUpdated = DateTime(2026, 6, 1);
        final copy = base().copyWith(
          priority: WishlistPriority.mustHave,
          notes: 'Any pressing is fine.',
          targetPrice: 20.00,
          updatedAt: newUpdated,
        );
        expect(copy.priority, WishlistPriority.mustHave);
        expect(copy.notes, 'Any pressing is fine.');
        expect(copy.targetPrice, 20.00);
        expect(copy.updatedAt, newUpdated);
      });

      test('does not mutate original', () {
        final item = base();
        item.copyWith(priority: WishlistPriority.low);
        expect(item.priority, WishlistPriority.high);
      });
    });
  });

  group('WishlistPriority', () {
    test('four priority values are defined', () {
      expect(WishlistPriority.values.length, 4);
    });

    test('label returns human-readable string', () {
      expect(WishlistPriority.low.label, 'Low');
      expect(WishlistPriority.medium.label, 'Medium');
      expect(WishlistPriority.high.label, 'High');
      expect(WishlistPriority.mustHave.label, 'Must have');
    });
  });
}

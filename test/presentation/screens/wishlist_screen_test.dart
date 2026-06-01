import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/presentation/screens/wishlist_screen.dart';
import 'package:cratewise/presentation/widgets/wishlist_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WishlistItem _makeItem({
  String id = 'w-1',
  int releaseId = 1,
  String artist = 'Test Artist',
  String title = 'Test Album',
  WishlistPriority priority = WishlistPriority.medium,
  String? label,
  int? year,
  String? format,
  double? targetPrice,
}) =>
    WishlistItem(
      id: id,
      discogsReleaseId: releaseId,
      artist: artist,
      title: title,
      priority: priority,
      label: label,
      year: year,
      format: format,
      targetPrice: targetPrice,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WishlistScreen — empty state', () {
    testWidgets('shows empty state when items list is empty', (tester) async {
      await tester.pumpWidget(_wrap(const WishlistScreen(items: [])));
      expect(find.byType(WishlistItemCard), findsNothing);
      expect(find.text('Your wishlist is empty'), findsOneWidget);
    });

    testWidgets('empty state shows helpful copy', (tester) async {
      await tester.pumpWidget(_wrap(const WishlistScreen(items: [])));
      expect(
        find.textContaining('Add to Wishlist'),
        findsOneWidget,
      );
    });

    testWidgets('empty state shows bookmark icon', (tester) async {
      await tester.pumpWidget(_wrap(const WishlistScreen(items: [])));
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });
  });

  group('WishlistScreen — list', () {
    testWidgets('shows WishlistItemCard for each item', (tester) async {
      final items = [
        _makeItem(id: 'a', releaseId: 1),
        _makeItem(id: 'b', releaseId: 2),
        _makeItem(id: 'c', releaseId: 3),
      ];
      await tester.pumpWidget(_wrap(WishlistScreen(items: items)));
      expect(find.byType(WishlistItemCard), findsNWidgets(3));
    });

    testWidgets('shows single card for single item', (tester) async {
      await tester.pumpWidget(_wrap(WishlistScreen(items: [_makeItem()])));
      expect(find.byType(WishlistItemCard), findsOneWidget);
    });

    testWidgets('default (null items) shows fake data cards', (tester) async {
      await tester.pumpWidget(_wrap(const WishlistScreen()));
      expect(find.byType(WishlistItemCard), findsWidgets);
      expect(find.text('Your wishlist is empty'), findsNothing);
    });
  });

  group('WishlistItemCard — content', () {
    testWidgets('shows artist text', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(item: _makeItem(artist: 'Miles Davis'))),
      );
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('shows title text', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(item: _makeItem(title: 'Kind Of Blue'))),
      );
      expect(find.text('Kind Of Blue'), findsOneWidget);
    });

    testWidgets('shows priority label', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(
          item: _makeItem(priority: WishlistPriority.mustHave),
        )),
      );
      expect(find.text('Must have'), findsOneWidget);
    });

    testWidgets('shows Low priority label', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(
          item: _makeItem(priority: WishlistPriority.low),
        )),
      );
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('shows High priority label', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(
          item: _makeItem(priority: WishlistPriority.high),
        )),
      );
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('shows meta row with label · year · format', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(
          item: _makeItem(label: 'Columbia', year: 1959, format: 'Vinyl, LP'),
        )),
      );
      expect(find.text('Columbia · 1959 · Vinyl, LP'), findsOneWidget);
    });

    testWidgets('shows partial meta when some fields are null', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(
          item: _makeItem(label: 'Impulse!', year: 1965),
        )),
      );
      expect(find.text('Impulse! · 1965'), findsOneWidget);
    });

    testWidgets('shows target price when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(item: _makeItem(targetPrice: 35.0))),
      );
      expect(find.text('35.00'), findsOneWidget);
    });

    testWidgets('does not show target price when null', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(item: _makeItem())),
      );
      expect(find.byIcon(Icons.sell_outlined), findsNothing);
    });

    testWidgets('shows cover placeholder icon when coverUrl is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(item: _makeItem())),
      );
      expect(find.byIcon(Icons.album), findsOneWidget);
    });
  });
}

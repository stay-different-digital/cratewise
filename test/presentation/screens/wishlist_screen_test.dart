import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/wishlist_screen.dart';
import 'package:cratewise/presentation/widgets/wishlist_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  _FakeWishlistRepository({this.items = const [], this.throwsOnLoad = false});

  final List<WishlistItem> items;
  final bool throwsOnLoad;
  int loadCallCount = 0;

  @override
  Future<List<WishlistItem>> getAll() async {
    loadCallCount++;
    if (throwsOnLoad) throw Exception('db error');
    return List.of(items);
  }

  @override
  Future<WishlistItem?> getById(String id) async =>
      items.where((i) => i.id == id).firstOrNull;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;

  @override
  Future<void> add(WishlistItem item) async {}

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _FlippingWishlistRepository implements WishlistRepository {
  _FlippingWishlistRepository({required this.successItems});

  final List<WishlistItem> successItems;
  int _callCount = 0;

  @override
  Future<List<WishlistItem>> getAll() async {
    _callCount++;
    if (_callCount == 1) throw Exception('first load fails');
    return List.of(successItems);
  }

  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

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
  group('WishlistScreen — loading state', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides loading indicator after load completes', (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('WishlistScreen — empty state', () {
    testWidgets('shows empty state when repository returns no items',
        (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(WishlistItemCard), findsNothing);
      expect(find.text('Your wishlist is empty'), findsOneWidget);
    });

    testWidgets('empty state shows helpful copy', (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Add to Wishlist'), findsOneWidget);
    });

    testWidgets('empty state shows bookmark icon', (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });
  });

  group('WishlistScreen — list', () {
    testWidgets('shows WishlistItemCard for each item', (tester) async {
      final repo = _FakeWishlistRepository(items: [
        _makeItem(id: 'a', releaseId: 1),
        _makeItem(id: 'b', releaseId: 2),
        _makeItem(id: 'c', releaseId: 3),
      ]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(WishlistItemCard), findsNWidgets(3));
    });

    testWidgets('shows single card for single item', (tester) async {
      final repo = _FakeWishlistRepository(items: [_makeItem()]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(WishlistItemCard), findsOneWidget);
    });

    testWidgets('does not show empty state when items present', (tester) async {
      final repo = _FakeWishlistRepository(items: [_makeItem()]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Your wishlist is empty'), findsNothing);
    });

    testWidgets('shows artist name', (tester) async {
      final repo = _FakeWishlistRepository(
        items: [_makeItem(artist: 'Miles Davis')],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('shows title', (tester) async {
      final repo = _FakeWishlistRepository(
        items: [_makeItem(title: 'Kind Of Blue')],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Kind Of Blue'), findsOneWidget);
    });
  });

  group('WishlistScreen — error state', () {
    testWidgets('shows error message when load fails', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not load'), findsOneWidget);
    });

    testWidgets('shows Retry button in error state', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry calls getAll again', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repo.loadCallCount, 2);
    });

    testWidgets('retry can recover to loaded state', (tester) async {
      final repo = _FlippingWishlistRepository(
        successItems: [_makeItem(artist: 'Recovered Artist')],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered Artist'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
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

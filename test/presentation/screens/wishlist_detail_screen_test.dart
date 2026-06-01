import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/wishlist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  _FakeWishlistRepository({
    this.item,
    this.throwsOnLoad = false,
    this.throwsOnUpdate = false,
    this.throwsOnRemove = false,
  });

  final WishlistItem? item;
  final bool throwsOnLoad;
  final bool throwsOnUpdate;
  final bool throwsOnRemove;
  int loadCallCount = 0;
  int updateCallCount = 0;
  int removeCallCount = 0;
  WishlistItem? updatedItem;
  String? removedId;

  @override
  Future<WishlistItem?> getById(String id) async {
    loadCallCount++;
    if (throwsOnLoad) throw Exception('db error');
    return item;
  }

  @override
  Future<void> update(WishlistItem item) async {
    updateCallCount++;
    updatedItem = item;
    if (throwsOnUpdate) throw Exception('update error');
  }

  @override
  Future<void> remove(String id) async {
    removeCallCount++;
    removedId = id;
    if (throwsOnRemove) throw Exception('remove error');
  }

  @override
  Future<List<WishlistItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(WishlistItem item) async {}
}

class _FlippingWishlistRepository implements WishlistRepository {
  _FlippingWishlistRepository({required this.successItem});

  final WishlistItem successItem;
  int _callCount = 0;

  @override
  Future<WishlistItem?> getById(String id) async {
    _callCount++;
    if (_callCount == 1) throw Exception('first load fails');
    return successItem;
  }

  @override
  Future<List<WishlistItem>> getAll() async => [];
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
  String artist = 'Test Artist',
  String title = 'Test Album',
  WishlistPriority priority = WishlistPriority.medium,
  String? label,
  String? catno,
  String? format,
  String? country,
  int? year,
  String? coverUrl,
  double? targetPrice,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    WishlistItem(
      id: id,
      discogsReleaseId: 1,
      artist: artist,
      title: title,
      priority: priority,
      label: label,
      catno: catno,
      format: format,
      country: country,
      year: year,
      coverUrl: coverUrl,
      targetPrice: targetPrice,
      notes: notes,
      createdAt: createdAt ?? DateTime(2026, 1, 15),
      updatedAt: updatedAt ?? DateTime(2026, 3, 20),
    );

Widget _wrap(Widget child) => MaterialApp(home: child);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WishlistDetailScreen — loading state', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      expect(find.byKey(const Key('wishlist-detail-loading')), findsOneWidget);
    });

    testWidgets('loading indicator gone after item loads', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wishlist-detail-loading')), findsNothing);
    });
  });

  group('WishlistDetailScreen — not found state', () {
    testWidgets('shows not found message when item does not exist',
        (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'missing', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item not found.'), findsOneWidget);
    });

    testWidgets('not found state does not show loading indicator',
        (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'missing', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wishlist-detail-loading')), findsNothing);
    });
  });

  group('WishlistDetailScreen — error state', () {
    testWidgets('shows error message when load throws', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load this item.'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('wishlist-detail-retry-button')),
        findsOneWidget,
      );
    });

    testWidgets('retry button calls getById again', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wishlist-detail-retry-button')));
      await tester.pumpAndSettle();
      expect(repo.loadCallCount, greaterThan(1));
    });

    testWidgets('retry-to-recovery shows loaded content', (tester) async {
      final repo = _FlippingWishlistRepository(
        successItem: _makeItem(title: 'Recovered Album'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      // First call failed — error shown
      expect(find.text('Could not load this item.'), findsOneWidget);
      // Tap retry — second call succeeds
      await tester.tap(find.byKey(const Key('wishlist-detail-retry-button')));
      await tester.pumpAndSettle();
      expect(find.text('Recovered Album'), findsWidgets);
    });
  });

  group('WishlistDetailScreen — loaded header', () {
    testWidgets('app bar shows item title when loaded', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem(title: 'Wish Title'));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wish Title'), findsWidgets);
    });

    testWidgets('shows artist name', (tester) async {
      final repo =
          _FakeWishlistRepository(item: _makeItem(artist: 'Wish Artist'));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wish Artist'), findsOneWidget);
    });
  });

  group('WishlistDetailScreen — loaded mandatory fields', () {
    testWidgets('shows priority label', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(priority: WishlistPriority.high),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('shows formatted target price when set', (tester) async {
      final repo =
          _FakeWishlistRepository(item: _makeItem(targetPrice: 29.99));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('29.99'), findsOneWidget);
    });

    testWidgets('shows Not set for target price when null', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('shows created date', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(createdAt: DateTime(2026, 1, 15)),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('2026-01-15'), findsOneWidget);
    });

    testWidgets('shows updated date', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(updatedAt: DateTime(2026, 3, 20)),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('2026-03-20'), findsOneWidget);
    });
  });

  group('WishlistDetailScreen — optional info fields', () {
    testWidgets('shows label when provided', (tester) async {
      final repo =
          _FakeWishlistRepository(item: _makeItem(label: 'Blue Note'));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Blue Note'), findsOneWidget);
    });

    testWidgets('hides label row when label is null', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Label'), findsNothing);
    });

    testWidgets('shows catno when label is null but catno is set',
        (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem(catno: 'BN-1568'));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('BN-1568'), findsOneWidget);
    });

    testWidgets('shows label and catno combined when both set', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(label: 'Verve', catno: 'V6-8612'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Verve'), findsOneWidget);
      expect(find.textContaining('V6-8612'), findsOneWidget);
    });

    testWidgets('shows format when provided', (tester) async {
      final repo =
          _FakeWishlistRepository(item: _makeItem(format: 'Vinyl, LP'));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vinyl, LP'), findsOneWidget);
    });

    testWidgets('shows country when provided', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem(country: 'US'));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('US'), findsOneWidget);
    });

    testWidgets('shows year when provided', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem(year: 1969));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('1969'), findsOneWidget);
    });
  });

  group('WishlistDetailScreen — notes section', () {
    testWidgets('shows notes section when notes provided', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(notes: 'Looking for NM copy'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Looking for NM copy'), findsOneWidget);
    });

    testWidgets('hides notes section when notes is null', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('hides notes section when notes is empty', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem(notes: ''));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsNothing);
    });
  });

  group('WishlistDetailScreen — edit buttons', () {
    testWidgets('edit-priority-button visible when loaded', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-priority-button')), findsOneWidget);
    });

    testWidgets('edit-target-price-button visible when loaded', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('edit-target-price-button')),
        findsOneWidget,
      );
    });

    testWidgets('edit-notes-button visible when loaded', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-notes-button')), findsOneWidget);
    });
  });

  group('WishlistDetailScreen — edit priority', () {
    testWidgets('tapping edit-priority-button opens sheet', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-priority-button')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Priority'), findsOneWidget);
    });

    testWidgets('saving priority calls repository.update', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-priority-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-priority-button')));
      await tester.pumpAndSettle();
      expect(repo.updateCallCount, 1);
    });

    testWidgets('saving priority shows success snackbar', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-priority-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-priority-button')));
      await tester.pumpAndSettle();
      expect(find.text('Priority saved.'), findsOneWidget);
    });

    testWidgets('priority save error shows error message', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-priority-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-priority-button')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save priority'),
        findsOneWidget,
      );
    });
  });

  group('WishlistDetailScreen — edit target price', () {
    testWidgets('tapping edit-target-price-button opens sheet',
        (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-target-price-button')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Target Price'), findsOneWidget);
    });

    testWidgets('saving valid price calls repository.update', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-target-price-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('target-price-text-field')),
        '19.99',
      );
      await tester.tap(find.byKey(const Key('save-target-price-button')));
      await tester.pumpAndSettle();
      expect(repo.updateCallCount, 1);
      expect(repo.updatedItem?.targetPrice, 19.99);
    });

    testWidgets('saving empty price clears to Not set', (tester) async {
      final repo =
          _FakeWishlistRepository(item: _makeItem(targetPrice: 29.99));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-target-price-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('target-price-text-field')),
        '',
      );
      await tester.tap(find.byKey(const Key('save-target-price-button')));
      await tester.pumpAndSettle();
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('invalid price shows validation error', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-target-price-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('target-price-text-field')),
        'abc',
      );
      await tester.tap(find.byKey(const Key('save-target-price-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('valid price'), findsOneWidget);
    });

    testWidgets('target price save error shows error message', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-target-price-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('target-price-text-field')),
        '9.99',
      );
      await tester.tap(find.byKey(const Key('save-target-price-button')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save target price'),
        findsOneWidget,
      );
    });
  });

  group('WishlistDetailScreen — edit notes', () {
    testWidgets('tapping edit-notes-button opens sheet', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Notes'), findsOneWidget);
    });

    testWidgets('saving notes calls repository.update', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('notes-text-field')),
        'New note text',
      );
      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();
      expect(repo.updateCallCount, 1);
    });

    testWidgets('saving notes shows success snackbar', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();
      expect(find.text('Notes saved.'), findsOneWidget);
    });

    testWidgets('clearing notes hides notes section after save',
        (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(notes: 'Old note'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old note'), findsOneWidget);
      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('notes-text-field')),
        '',
      );
      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsNothing);
      expect(find.text('Old note'), findsNothing);
    });

    testWidgets('notes save error shows error message', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save notes'), findsOneWidget);
    });
  });

  group('WishlistDetailScreen — remove item', () {
    testWidgets('shows overflow menu button when loaded', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-overflow-menu')), findsOneWidget);
    });

    testWidgets('overflow menu not shown while loading', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      expect(find.byKey(const Key('detail-overflow-menu')), findsNothing);
    });

    testWidgets('tapping overflow menu shows Remove from wishlist option',
        (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Remove from wishlist'), findsOneWidget);
    });

    testWidgets('tapping Remove option shows confirmation dialog',
        (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from wishlist'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from wishlist?'), findsOneWidget);
    });

    testWidgets('confirmation dialog mentions Discogs not affected',
        (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from wishlist'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Discogs'), findsOneWidget);
    });

    testWidgets('tapping Cancel does not call repository.remove',
        (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from wishlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel-remove-button')));
      await tester.pumpAndSettle();
      expect(repo.removeCallCount, 0);
    });

    testWidgets('tapping Remove calls repository.remove', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from wishlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();
      expect(repo.removeCallCount, 1);
    });

    testWidgets('navigates back after successful remove', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('go-to-detail'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WishlistDetailScreen(
                        itemId: 'w-1',
                        repository: repo,
                      ),
                    ),
                  ),
                  child: const Text('Go to detail'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('go-to-detail')));
      await tester.pumpAndSettle();
      expect(find.byType(WishlistDetailScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from wishlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();

      expect(find.byType(WishlistDetailScreen), findsNothing);
    });

    testWidgets('remove error shows snackbar', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(),
        throwsOnRemove: true,
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from wishlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not remove'), findsOneWidget);
    });
  });
}

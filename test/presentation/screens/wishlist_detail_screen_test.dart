import 'package:cratewise/application/use_cases/add_to_collection_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/pending_discogs_deletion.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/pending_discogs_deletion_repository.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/wishlist_detail_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeThumbnailRepository implements ThumbnailRepository {
  _FakeThumbnailRepository({this.pathToReturn});
  final String? pathToReturn;

  @override
  Future<String?> getLocalPath(int releaseId) async => pathToReturn;
  @override
  Future<void> save(int releaseId, List<int> bytes) async {}
  @override
  Future<void> remove(int releaseId) async {}
  @override
  Future<bool> exists(int releaseId) async => pathToReturn != null;
  @override
  Future<int> totalSizeBytes() async => 0;
  @override
  Future<List<ThumbnailEntry>> listEntries() async => [];
  @override
  Future<void> removeAll() async {}
}

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
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
  @override
  Future<void> deleteAll() async {}
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

class _UpdatingWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _UpdatingWishlistRepository({required this.first, required this.second});

  final WishlistItem first;
  final WishlistItem second;
  int _calls = 0;

  @override
  Future<WishlistItem?> getById(String id) async {
    _calls++;
    return _calls == 1 ? first : second;
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

class _SuccessThenErrorWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _SuccessThenErrorWishlistRepository({required this.successItem});

  final WishlistItem successItem;
  int _calls = 0;

  @override
  Future<WishlistItem?> getById(String id) async {
    _calls++;
    if (_calls == 1) return successItem;
    throw Exception('refresh error');
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

class _FakeCollectionRepository implements CollectionRepository {
  _FakeCollectionRepository({
    this.alreadyContains = false,
    this.throwOnAdd = false,
  });

  final bool alreadyContains;
  final bool throwOnAdd;
  int addCallCount = 0;
  CollectionItem? addedItem;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => alreadyContains;

  @override
  Future<void> add(CollectionItem item) async {
    addCallCount++;
    if (throwOnAdd) throw Exception('add error');
    addedItem = item;
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> deleteAll() async {}
}

class _RecordingDeletionRepository implements PendingDiscogsDeletionRepository {
  int addCallCount = 0;

  @override
  Future<void> add(PendingDiscogsDeletion deletion) async {
    addCallCount++;
  }

  @override
  Future<List<PendingDiscogsDeletion>> getByType(
    DeletionEntityType entityType,
  ) async => [];
  @override
  Future<bool> containsRelease(
    int discogsReleaseId,
    DeletionEntityType entityType,
  ) async => false;
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> removeByRelease(
    int discogsReleaseId,
    DeletionEntityType entityType,
  ) async {}
  @override
  Future<void> deleteAllByType(DeletionEntityType entityType) async {}
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
}) => WishlistItem(
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

// Pushes the detail screen on top of a home route so Navigator.pop() returns
// to a real previous route (mirrors the existing remove-flow tests).
Future<void> _pumpPushedDetail(
  WidgetTester tester,
  WishlistRepository repo, {
  AddToCollectionUseCase? addToCollectionUseCase,
  PendingDiscogsDeletionRepository? deletionRepository,
}) async {
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
                    addToCollectionUseCase: addToCollectionUseCase,
                    deletionRepository: deletionRepository,
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
}

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
    testWidgets('shows not found message when item does not exist', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'missing', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item not found.'), findsOneWidget);
    });

    testWidgets('not found state does not show loading indicator', (
      tester,
    ) async {
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
      expect(find.textContaining('Could not load this item'), findsOneWidget);
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
      expect(find.textContaining('Could not load this item'), findsOneWidget);
      // Tap retry — second call succeeds
      await tester.tap(find.byKey(const Key('wishlist-detail-retry-button')));
      await tester.pumpAndSettle();
      expect(find.text('Recovered Album'), findsWidgets);
    });
  });

  group('WishlistDetailScreen — loaded header', () {
    testWidgets('app bar shows item title when loaded', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(title: 'Wish Title'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wish Title'), findsWidgets);
    });

    testWidgets('shows artist name', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(artist: 'Wish Artist'),
      );
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
      final repo = _FakeWishlistRepository(item: _makeItem(targetPrice: 29.99));
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
      expect(find.textContaining('Jan 15, 2026'), findsOneWidget);
    });

    testWidgets('shows updated date', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(updatedAt: DateTime(2026, 3, 20)),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Mar 20, 2026'), findsOneWidget);
    });
  });

  group('WishlistDetailScreen — optional info fields', () {
    testWidgets('shows label when provided', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem(label: 'Blue Note'));
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

    testWidgets('shows catno when label is null but catno is set', (
      tester,
    ) async {
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
      final repo = _FakeWishlistRepository(
        item: _makeItem(format: 'Vinyl, LP'),
      );
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
      expect(find.byKey(const Key('edit-target-price-button')), findsOneWidget);
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
      expect(find.textContaining('Could not save priority'), findsOneWidget);
    });
  });

  group('WishlistDetailScreen — edit target price', () {
    testWidgets('tapping edit-target-price-button opens sheet', (tester) async {
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
      final repo = _FakeWishlistRepository(item: _makeItem(targetPrice: 29.99));
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

    testWidgets('clearing notes hides notes section after save', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository(item: _makeItem(notes: 'Old note'));
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old note'), findsOneWidget);
      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('notes-text-field')), '');
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

  group('WishlistDetailScreen — local-first', () {
    testWidgets('loads without a Discogs token', (tester) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(artist: 'Offline Artist'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Offline Artist'), findsOneWidget);
    });

    testWidgets('loads without network (simulated by local-only fake repo)', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository(
        item: _makeItem(artist: 'No Network Artist'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('No Network Artist'), findsOneWidget);
    });

    testWidgets('not found state mentions device storage', (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'nonexistent-id', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('device storage'), findsOneWidget);
    });

    testWidgets('error state mentions device storage', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('device storage'), findsOneWidget);
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

    testWidgets('tapping overflow menu shows Remove from wishlist option', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Remove from wishlist'), findsOneWidget);
    });

    testWidgets('tapping Remove option shows confirmation dialog', (
      tester,
    ) async {
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

    testWidgets('confirmation dialog mentions Discogs not affected', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from wishlist'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your Discogs account is not affected'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Cancel does not call repository.remove', (
      tester,
    ) async {
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
                      builder: (_) =>
                          WishlistDetailScreen(itemId: 'w-1', repository: repo),
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

  group('WishlistDetailScreen — thumbnail cache', () {
    testWidgets(
      'renders loaded state without crash when thumbnailRepository returns null',
      (tester) async {
        final repo = _FakeWishlistRepository(
          item: _makeItem(artist: 'Thumb Artist'),
        );
        final thumbRepo = _FakeThumbnailRepository();
        await tester.pumpWidget(
          _wrap(
            WishlistDetailScreen(
              itemId: 'w-1',
              repository: repo,
              thumbnailRepository: thumbRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Thumb Artist'), findsOneWidget);
      },
    );

    testWidgets(
      'renders loaded state without crash when thumbnailRepository returns a cached path',
      (tester) async {
        final repo = _FakeWishlistRepository(
          item: _makeItem(artist: 'Thumb Artist'),
        );
        final thumbRepo = _FakeThumbnailRepository(
          pathToReturn: '/fake/thumb.jpg',
        );
        await tester.pumpWidget(
          _wrap(
            WishlistDetailScreen(
              itemId: 'w-1',
              repository: repo,
              thumbnailRepository: thumbRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Thumb Artist'), findsOneWidget);
      },
    );
  });

  group('WishlistDetailScreen — sync status', () {
    testWidgets('shows "Saved on this device" for localOnly', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved on this device'), findsOneWidget);
    });

    testWidgets('shows "Synced" for synced status', (tester) async {
      final repo = _FakeWishlistRepository(
        item: WishlistItem(
          id: 'w-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          priority: WishlistPriority.medium,
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 3, 20),
          syncStatus: SyncStatus.synced,
        ),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows "Waiting to sync" for pending status', (tester) async {
      final repo = _FakeWishlistRepository(
        item: WishlistItem(
          id: 'w-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          priority: WishlistPriority.medium,
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 3, 20),
          syncStatus: SyncStatus.pending,
        ),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Waiting to sync'), findsOneWidget);
    });

    testWidgets('shows "Sync failed" for failed status', (tester) async {
      final repo = _FakeWishlistRepository(
        item: WishlistItem(
          id: 'w-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          priority: WishlistPriority.medium,
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 3, 20),
          syncStatus: SyncStatus.failed,
        ),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sync failed'), findsOneWidget);
    });

    testWidgets('shows "Needs review" for conflict status', (tester) async {
      final repo = _FakeWishlistRepository(
        item: WishlistItem(
          id: 'w-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          priority: WishlistPriority.medium,
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 3, 20),
          syncStatus: SyncStatus.conflict,
        ),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Needs review'), findsOneWidget);
    });

    testWidgets('shows "Offline" for offline status', (tester) async {
      final repo = _FakeWishlistRepository(
        item: WishlistItem(
          id: 'w-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          priority: WishlistPriority.medium,
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 3, 20),
          syncStatus: SyncStatus.offline,
        ),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);
    });
  });

  group('WishlistDetailScreen — pull-to-refresh', () {
    testWidgets('RefreshIndicator present on loaded state', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('PTR triggers getById again', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(repo.loadCallCount, 1);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      expect(repo.loadCallCount, 2);
    });

    testWidgets('PTR updates displayed item', (tester) async {
      final repo = _UpdatingWishlistRepository(
        first: _makeItem(title: 'Old Title'),
        second: _makeItem(title: 'New Title'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old Title'), findsWidgets);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      expect(find.text('New Title'), findsWidgets);
    });

    testWidgets('PTR error keeps existing item visible', (tester) async {
      final repo = _SuccessThenErrorWishlistRepository(
        successItem: _makeItem(artist: 'Kept Artist'),
      );
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kept Artist'), findsOneWidget);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      expect(find.text('Kept Artist'), findsOneWidget);
    });

    testWidgets('no RefreshIndicator in error state', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });

  group('WishlistDetailScreen — safe area', () {
    testWidgets('loaded body has SafeArea with top: false', (tester) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(WishlistDetailScreen(itemId: 'w-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
      expect(safeAreas.any((sa) => !sa.top), isTrue);
    });
  });

  group('WishlistDetailScreen — move to collection (US-86)', () {
    testWidgets('shows the Add to collection button on a loaded item', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(
          WishlistDetailScreen(
            itemId: 'w-1',
            repository: repo,
            addToCollectionUseCase: AddToCollectionUseCase(
              _FakeCollectionRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add-to-collection-button')), findsOneWidget);
    });

    testWidgets(
      'successful add removes the wishlist item, pops, and shows a snackbar',
      (tester) async {
        final wishlistRepo = _FakeWishlistRepository(item: _makeItem());
        final collRepo = _FakeCollectionRepository();
        await _pumpPushedDetail(
          tester,
          wishlistRepo,
          addToCollectionUseCase: AddToCollectionUseCase(collRepo),
        );

        await tester.tap(find.byKey(const Key('add-to-collection-button')));
        await tester.pumpAndSettle();

        expect(collRepo.addCallCount, 1);
        expect(wishlistRepo.removeCallCount, 1);
        expect(find.byType(WishlistDetailScreen), findsNothing);
        expect(find.text('Moved to your collection.'), findsOneWidget);
      },
    );

    testWidgets('the added collection item carries the release fields', (
      tester,
    ) async {
      final wishlistRepo = _FakeWishlistRepository(
        item: _makeItem(
          artist: 'Aphex Twin',
          title: 'Selected Ambient Works',
          label: 'Apollo',
          catno: 'AMB 3922',
        ),
      );
      final collRepo = _FakeCollectionRepository();
      await _pumpPushedDetail(
        tester,
        wishlistRepo,
        addToCollectionUseCase: AddToCollectionUseCase(collRepo),
      );

      await tester.tap(find.byKey(const Key('add-to-collection-button')));
      await tester.pumpAndSettle();

      expect(collRepo.addedItem?.artist, 'Aphex Twin');
      expect(collRepo.addedItem?.title, 'Selected Ambient Works');
      expect(collRepo.addedItem?.label, 'Apollo');
      expect(collRepo.addedItem?.catno, 'AMB 3922');
      expect(collRepo.addedItem?.syncStatus, SyncStatus.localOnly);
    });

    testWidgets('add failure leaves the wishlist item intact (no pop)', (
      tester,
    ) async {
      final wishlistRepo = _FakeWishlistRepository(item: _makeItem());
      final collRepo = _FakeCollectionRepository(throwOnAdd: true);
      await _pumpPushedDetail(
        tester,
        wishlistRepo,
        addToCollectionUseCase: AddToCollectionUseCase(collRepo),
      );

      await tester.tap(find.byKey(const Key('add-to-collection-button')));
      await tester.pumpAndSettle();

      expect(wishlistRepo.removeCallCount, 0);
      expect(find.byType(WishlistDetailScreen), findsOneWidget);
      expect(find.textContaining('Your wishlist is unchanged'), findsOneWidget);
    });

    testWidgets(
      'already-in-collection removes from wishlist without a duplicate add',
      (tester) async {
        final wishlistRepo = _FakeWishlistRepository(item: _makeItem());
        final collRepo = _FakeCollectionRepository(alreadyContains: true);
        await _pumpPushedDetail(
          tester,
          wishlistRepo,
          addToCollectionUseCase: AddToCollectionUseCase(collRepo),
        );

        await tester.tap(find.byKey(const Key('add-to-collection-button')));
        await tester.pumpAndSettle();

        expect(collRepo.addCallCount, 0);
        expect(wishlistRepo.removeCallCount, 1);
        expect(find.byType(WishlistDetailScreen), findsNothing);
        expect(
          find.text('Already in your collection — removed from wishlist.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('the move creates no Discogs tombstone by default', (
      tester,
    ) async {
      final wishlistRepo = _FakeWishlistRepository(
        item: WishlistItem(
          id: 'w-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          priority: WishlistPriority.medium,
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 3, 20),
          syncStatus: SyncStatus.synced,
        ),
      );
      final deletionRepo = _RecordingDeletionRepository();
      await _pumpPushedDetail(
        tester,
        wishlistRepo,
        addToCollectionUseCase: AddToCollectionUseCase(
          _FakeCollectionRepository(),
        ),
        deletionRepository: deletionRepo,
      );

      await tester.tap(find.byKey(const Key('add-to-collection-button')));
      await tester.pumpAndSettle();

      expect(deletionRepo.addCallCount, 0);
      expect(wishlistRepo.removeCallCount, 1);
    });
  });
}

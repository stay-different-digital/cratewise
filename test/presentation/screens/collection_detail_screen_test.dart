import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/presentation/screens/collection_detail_screen.dart';
import 'package:cratewise/shared/route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeCollectionRepository({
    this.item,
    this.throwsOnLoad = false,
    this.throwsOnUpdate = false,
    this.throwsOnRemove = false,
  });

  final CollectionItem? item;
  final bool throwsOnLoad;
  final bool throwsOnUpdate;
  final bool throwsOnRemove;
  int loadCallCount = 0;
  int updateCallCount = 0;
  int removeCallCount = 0;
  CollectionItem? lastUpdatedItem;

  @override
  Future<CollectionItem?> getById(String id) async {
    loadCallCount++;
    if (throwsOnLoad) throw Exception('db error');
    return item;
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {
    updateCallCount++;
    lastUpdatedItem = item;
    if (throwsOnUpdate) throw Exception('update error');
  }

  @override
  Future<void> remove(String id) async {
    removeCallCount++;
    if (throwsOnRemove) throw Exception('remove error');
  }
}

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

class _FlippingCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _FlippingCollectionRepository({required this.successItem});

  final CollectionItem successItem;
  int _callCount = 0;

  @override
  Future<CollectionItem?> getById(String id) async {
    _callCount++;
    if (_callCount == 1) throw Exception('first load fails');
    return successItem;
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _UpdatingCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _UpdatingCollectionRepository({required this.first, required this.second});

  final CollectionItem first;
  final CollectionItem second;
  int _calls = 0;

  @override
  Future<CollectionItem?> getById(String id) async {
    _calls++;
    return _calls == 1 ? first : second;
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _SuccessThenErrorCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _SuccessThenErrorCollectionRepository({required this.successItem});

  final CollectionItem successItem;
  int _calls = 0;

  @override
  Future<CollectionItem?> getById(String id) async {
    _calls++;
    if (_calls == 1) return successItem;
    throw Exception('refresh error');
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _ThenRemovedCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _ThenRemovedCollectionRepository({required this.firstItem});

  final CollectionItem firstItem;
  int _calls = 0;

  @override
  Future<CollectionItem?> getById(String id) async {
    _calls++;
    return _calls == 1 ? firstItem : null;
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _makeItem({
  String id = 'test-1',
  String artist = 'Test Artist',
  String title = 'Test Album',
  String? label,
  String? catno,
  String? format,
  String? country,
  int? year,
  String? notes,
  List<String> tags = const [],
  String? storageLocation,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: artist,
  title: title,
  label: label,
  catno: catno,
  format: format,
  country: country,
  year: year,
  coverUrl: null,
  notes: notes,
  mediaCondition: RecordCondition.veryGood,
  sleeveCondition: RecordCondition.nearMint,
  tags: tags,
  storageLocation: storageLocation,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
  updatedAt: updatedAt ?? DateTime(2026, 3, 15),
);

Widget _wrap(Widget child) => MaterialApp(home: child);

Widget _wrapWithObserver(Widget child) =>
    MaterialApp(navigatorObservers: [appRouteObserver], home: child);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionDetailScreen — loading state', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides loading indicator after load completes', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('CollectionDetailScreen — loaded state', () {
    testWidgets('shows item title in app bar', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(title: 'Kind of Blue'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kind of Blue'), findsWidgets);
    });

    testWidgets('shows artist', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(artist: 'Miles Davis'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('shows media condition', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(RecordCondition.veryGood.label),
        findsOneWidget,
      );
    });

    testWidgets('shows sleeve condition', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(RecordCondition.nearMint.label),
        findsOneWidget,
      );
    });

    testWidgets('shows label when provided', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(label: 'Blue Note'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Blue Note'), findsOneWidget);
    });

    testWidgets('shows catno when provided without label', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(catno: 'BN 1577'));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('BN 1577'), findsOneWidget);
    });

    testWidgets('combines label and catno with separator', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(label: 'Blue Note', catno: 'BN 1577'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Blue Note — BN 1577'), findsOneWidget);
    });

    testWidgets('shows format when provided', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(format: 'LP'));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('LP'), findsOneWidget);
    });

    testWidgets('shows country when provided', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(country: 'US'));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('US'), findsOneWidget);
    });

    testWidgets('shows year when provided', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(year: 1959));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1959'), findsOneWidget);
    });

    testWidgets('shows notes section when notes is present', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(notes: 'Original pressing. Excellent.'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original pressing. Excellent.'), findsOneWidget);
    });

    testWidgets('does not show notes section when notes is null', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem(notes: null));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('shows tags when provided', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(tags: ['jazz', 'essential']),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('jazz'), findsOneWidget);
      expect(find.text('essential'), findsOneWidget);
    });

    testWidgets('does not show tags section when tags list is empty', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem(tags: []));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tags'), findsNothing);
    });

    testWidgets('shows storage location when provided', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(storageLocation: 'Shelf B3'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Shelf B3'), findsOneWidget);
    });

    testWidgets('shows created date', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(createdAt: DateTime(2026, 1, 5)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Jan 5, 2026'), findsOneWidget);
    });

    testWidgets('shows updated date', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2026, 6, 20)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Jun 20, 2026'), findsOneWidget);
    });

    testWidgets('renders without error when all optional fields are null', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(
          label: null,
          catno: null,
          format: null,
          country: null,
          year: null,
          notes: null,
          tags: [],
          storageLocation: null,
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item not found.'), findsNothing);
      expect(find.textContaining('Could not load'), findsNothing);
    });
  });

  group('CollectionDetailScreen — not found state', () {
    testWidgets('shows not found message when item does not exist', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(itemId: 'nonexistent-id', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item not found.'), findsOneWidget);
    });

    testWidgets('shows descriptive not found body text', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(itemId: 'nonexistent-id', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('may have been removed'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — error state', () {
    testWidgets('shows error message when load fails', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not load'), findsOneWidget);
    });

    testWidgets('shows Retry button in error state', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry calls getById again', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repo.loadCallCount, 2);
    });

    testWidgets('retry can recover to loaded state', (tester) async {
      final repo = _FlippingCollectionRepository(
        successItem: _makeItem(artist: 'Recovered Artist'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered Artist'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('CollectionDetailScreen — wide layout', () {
    testWidgets('renders without error at wide breakpoint', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeCollectionRepository(
        item: _makeItem(
          artist: 'Miles Davis',
          title: 'Kind of Blue',
          label: 'Columbia',
          notes: 'A classic.',
          tags: ['jazz'],
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Miles Davis'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — edit conditions', () {
    testWidgets('shows edit button when loaded', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-conditions-button')), findsOneWidget);
    });

    testWidgets('does not show edit button while loading', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byKey(const Key('edit-conditions-button')), findsNothing);
    });

    testWidgets('does not show edit button in not-found state', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'nonexistent', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-conditions-button')), findsNothing);
    });

    testWidgets('does not show edit button in error state', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-conditions-button')), findsNothing);
    });

    testWidgets('tapping edit button opens sheet with title', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Conditions'), findsOneWidget);
    });

    testWidgets('sheet shows Save button', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-conditions-button')), findsOneWidget);
    });

    testWidgets('tapping Save calls repository.update', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
    });

    testWidgets('shows success snackbar after save', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.text('Conditions saved.'), findsOneWidget);
    });

    testWidgets('save updates updatedAt shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2026, 2, 15)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Feb 15, 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Feb 15, 2026'), findsNothing);
    });

    testWidgets('save error shows error message in sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
    });

    testWidgets('save error does not close sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-conditions-button')), findsOneWidget);
    });

    testWidgets('changing media condition and saving updates displayed value', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('media-condition-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(RecordCondition.mint.label).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining(RecordCondition.mint.label), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — edit tags', () {
    testWidgets('shows edit tags button when loaded', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-tags-button')), findsOneWidget);
    });

    testWidgets('does not show edit tags button while loading', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byKey(const Key('edit-tags-button')), findsNothing);
    });

    testWidgets('does not show edit tags button in not-found state', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'nonexistent', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-tags-button')), findsNothing);
    });

    testWidgets('does not show edit tags button in error state', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-tags-button')), findsNothing);
    });

    testWidgets('tapping edit tags button opens sheet with title', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Tags'), findsOneWidget);
    });

    testWidgets('sheet shows existing tags as chips', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(tags: ['jazz', 'essential']),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tag-chip-jazz')), findsOneWidget);
      expect(find.byKey(const Key('tag-chip-essential')), findsOneWidget);
    });

    testWidgets('can add a tag', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('tag-input-field')), 'soul');
      await tester.tap(find.byKey(const Key('add-tag-button')));
      await tester.pump();

      expect(find.byKey(const Key('tag-chip-soul')), findsOneWidget);
    });

    testWidgets('can remove a tag', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(tags: ['jazz']));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('tag-chip-jazz')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('tag-chip-jazz')), findsNothing);
    });

    testWidgets('does not add empty tag', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-tag-button')));
      await tester.pump();

      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('does not add duplicate tag (case-insensitive)', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem(tags: ['jazz']));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('tag-input-field')), 'Jazz');
      await tester.tap(find.byKey(const Key('add-tag-button')));
      await tester.pump();

      expect(find.byType(InputChip), findsOneWidget);
    });

    testWidgets('tapping Save calls repository.update', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
    });

    testWidgets('shows success snackbar after save', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.text('Tags saved.'), findsOneWidget);
    });

    testWidgets('save updates tags shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(tags: ['jazz']));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('tag-input-field')), 'soul');
      await tester.tap(find.byKey(const Key('add-tag-button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.text('soul'), findsOneWidget);
    });

    testWidgets('save updates updatedAt shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2025, 11, 5)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Nov 5, 2025'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nov 5, 2025'), findsNothing);
    });

    testWidgets('save error shows error message in sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
    });

    testWidgets('save error does not close sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-tags-button')), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — edit notes', () {
    testWidgets('shows edit notes button when loaded', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-notes-button')), findsOneWidget);
    });

    testWidgets('does not show edit notes button while loading', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byKey(const Key('edit-notes-button')), findsNothing);
    });

    testWidgets('does not show edit notes button in not-found state', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'nonexistent', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-notes-button')), findsNothing);
    });

    testWidgets('does not show edit notes button in error state', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-notes-button')), findsNothing);
    });

    testWidgets('tapping edit notes button opens sheet with title', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Notes'), findsOneWidget);
    });

    testWidgets('sheet shows Save button', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-notes-button')), findsOneWidget);
    });

    testWidgets('sheet pre-fills existing notes', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(notes: 'Existing note text'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('notes-text-field')),
          matching: find.text('Existing note text'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Save calls repository.update', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
    });

    testWidgets('shows success snackbar after save', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.text('Notes saved.'), findsOneWidget);
    });

    testWidgets('save updates notes shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(notes: 'Old note text'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old note text'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('notes-text-field')),
        'New note text',
      );
      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.text('New note text'), findsOneWidget);
      expect(find.text('Old note text'), findsNothing);
    });

    testWidgets('save updates updatedAt shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2025, 12, 10)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Dec 10, 2025'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dec 10, 2025'), findsNothing);
    });

    testWidgets('clearing notes hides the notes section', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(notes: 'Some note'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('notes-text-field')), '');
      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('save error shows error message in sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
    });

    testWidgets('save error does not close sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-notes-button')), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — edit storage location', () {
    testWidgets('shows edit storage location button when loaded', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('edit-storage-location-button')),
        findsOneWidget,
      );
    });

    testWidgets('does not show edit storage location button while loading', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(
        find.byKey(const Key('edit-storage-location-button')),
        findsNothing,
      );
    });

    testWidgets(
      'does not show edit storage location button in not-found state',
      (tester) async {
        final repo = _FakeCollectionRepository();
        await tester.pumpWidget(
          _wrap(
            CollectionDetailScreen(itemId: 'nonexistent', repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('edit-storage-location-button')),
          findsNothing,
        );
      },
    );

    testWidgets('does not show edit storage location button in error state', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('edit-storage-location-button')),
        findsNothing,
      );
    });

    testWidgets('tapping button opens sheet with title', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Storage Location'), findsOneWidget);
    });

    testWidgets('sheet shows Save button', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('save-storage-location-button')),
        findsOneWidget,
      );
    });

    testWidgets('sheet pre-fills existing storage location', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(storageLocation: 'Studio crate'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('storage-location-text-field')),
          matching: find.text('Studio crate'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Save calls repository.update', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-storage-location-button')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
    });

    testWidgets('shows success snackbar after save', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-storage-location-button')));
      await tester.pumpAndSettle();

      expect(find.text('Storage location saved.'), findsOneWidget);
    });

    testWidgets('save updates storage location shown on screen', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(storageLocation: 'Box A'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Box A'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('storage-location-text-field')),
        'Shelf 2',
      );
      await tester.tap(find.byKey(const Key('save-storage-location-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Shelf 2'), findsOneWidget);
      expect(find.textContaining('Box A'), findsNothing);
    });

    testWidgets('save updates updatedAt shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2025, 9, 3)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sep 3, 2025'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-storage-location-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sep 3, 2025'), findsNothing);
    });

    testWidgets('clearing storage location hides Location row', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(storageLocation: 'Living room shelf'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Living room shelf'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('storage-location-text-field')),
        '',
      );
      await tester.tap(find.byKey(const Key('save-storage-location-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Living room shelf'), findsNothing);
      expect(find.text('Location'), findsNothing);
    });

    testWidgets('save error shows error message in sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-storage-location-button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not save storage location'),
        findsOneWidget,
      );
    });

    testWidgets('save error does not close sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-storage-location-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-storage-location-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('save-storage-location-button')),
        findsOneWidget,
      );
    });
  });

  group('CollectionDetailScreen — remove item', () {
    testWidgets('shows overflow menu button when loaded', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-overflow-menu')), findsOneWidget);
    });

    testWidgets('does not show overflow menu button while loading', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byKey(const Key('detail-overflow-menu')), findsNothing);
    });

    testWidgets('does not show overflow menu button in not-found state', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'nonexistent', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-overflow-menu')), findsNothing);
    });

    testWidgets('does not show overflow menu button in error state', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-overflow-menu')), findsNothing);
    });

    testWidgets('tapping overflow menu shows Remove from Cratewise option', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();

      expect(find.text('Remove from Cratewise'), findsOneWidget);
    });

    testWidgets('tapping Remove option shows confirmation dialog', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Cratewise'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirmation dialog mentions Discogs not affected', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Cratewise'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Your Discogs collection is not affected'),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping Cancel closes dialog without calling repository.remove',
      (tester) async {
        final repo = _FakeCollectionRepository(item: _makeItem());
        await tester.pumpWidget(
          _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('detail-overflow-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove from Cratewise'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('cancel-remove-button')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(repo.removeCallCount, 0);
      },
    );

    testWidgets('tapping Remove calls repository.remove', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Cratewise'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();

      expect(repo.removeCallCount, 1);
    });

    testWidgets('navigates back after successful remove', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('go-to-detail'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CollectionDetailScreen(
                        itemId: 'test-1',
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
      expect(find.byType(CollectionDetailScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Cratewise'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();

      expect(find.byType(CollectionDetailScreen), findsNothing);
    });

    testWidgets('remove error shows snackbar', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnRemove: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Cratewise'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not remove'), findsOneWidget);
    });

    testWidgets('remove error does not navigate back', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnRemove: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('go-to-detail'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CollectionDetailScreen(
                        itemId: 'test-1',
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

      await tester.tap(find.byKey(const Key('detail-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Cratewise'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();

      expect(find.byType(CollectionDetailScreen), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — local-first', () {
    testWidgets('loads without a Discogs token', (tester) async {
      // No token passed or required — repository is purely local.
      final repo = _FakeCollectionRepository(
        item: _makeItem(artist: 'Offline Artist'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Offline Artist'), findsOneWidget);
    });

    testWidgets('loads without network (simulated by local-only fake repo)', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(artist: 'No Network Artist'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('No Network Artist'), findsOneWidget);
    });

    testWidgets('not found state mentions device storage', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(itemId: 'nonexistent-id', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('device storage'), findsOneWidget);
    });

    testWidgets('error state mentions device storage', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('device storage'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — thumbnail cache', () {
    testWidgets(
      'renders loaded state without crash when thumbnailRepository returns null',
      (tester) async {
        final repo = _FakeCollectionRepository(
          item: _makeItem(artist: 'Thumb Artist'),
        );
        final thumbRepo = _FakeThumbnailRepository();
        await tester.pumpWidget(
          _wrap(
            CollectionDetailScreen(
              itemId: 'test-1',
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
        final repo = _FakeCollectionRepository(
          item: _makeItem(artist: 'Thumb Artist'),
        );
        final thumbRepo = _FakeThumbnailRepository(
          pathToReturn: '/fake/thumb.jpg',
        );
        await tester.pumpWidget(
          _wrap(
            CollectionDetailScreen(
              itemId: 'test-1',
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

  group('CollectionDetailScreen — sync status', () {
    testWidgets('shows "Saved on this device" for localOnly', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved on this device'), findsOneWidget);
    });

    testWidgets('shows "Synced" for synced status', (tester) async {
      final repo = _FakeCollectionRepository(
        item: CollectionItem(
          id: 'test-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          coverUrl: null,
          mediaCondition: RecordCondition.veryGood,
          sleeveCondition: RecordCondition.nearMint,
          tags: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 3, 15),
          syncStatus: SyncStatus.synced,
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows "Waiting to sync" for pending status', (tester) async {
      final repo = _FakeCollectionRepository(
        item: CollectionItem(
          id: 'test-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          coverUrl: null,
          mediaCondition: RecordCondition.veryGood,
          sleeveCondition: RecordCondition.nearMint,
          tags: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 3, 15),
          syncStatus: SyncStatus.pending,
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Waiting to sync'), findsOneWidget);
    });

    testWidgets('shows "Sync failed" for failed status', (tester) async {
      final repo = _FakeCollectionRepository(
        item: CollectionItem(
          id: 'test-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          coverUrl: null,
          mediaCondition: RecordCondition.veryGood,
          sleeveCondition: RecordCondition.nearMint,
          tags: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 3, 15),
          syncStatus: SyncStatus.failed,
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sync failed'), findsOneWidget);
    });

    testWidgets('shows "Needs review" for conflict status', (tester) async {
      final repo = _FakeCollectionRepository(
        item: CollectionItem(
          id: 'test-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          coverUrl: null,
          mediaCondition: RecordCondition.veryGood,
          sleeveCondition: RecordCondition.nearMint,
          tags: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 3, 15),
          syncStatus: SyncStatus.conflict,
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Needs review'), findsOneWidget);
    });

    testWidgets('shows "Offline" for offline status', (tester) async {
      final repo = _FakeCollectionRepository(
        item: CollectionItem(
          id: 'test-1',
          discogsReleaseId: 1,
          artist: 'Test Artist',
          title: 'Test Album',
          coverUrl: null,
          mediaCondition: RecordCondition.veryGood,
          sleeveCondition: RecordCondition.nearMint,
          tags: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 3, 15),
          syncStatus: SyncStatus.offline,
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — pull-to-refresh', () {
    testWidgets('RefreshIndicator present on loaded state', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('PTR triggers getById again', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
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
      final repo = _UpdatingCollectionRepository(
        first: _makeItem(title: 'Old Title'),
        second: _makeItem(title: 'New Title'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
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
      final repo = _SuccessThenErrorCollectionRepository(
        successItem: _makeItem(artist: 'Kept Artist'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
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
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });

  group('CollectionDetailScreen — safe area', () {
    testWidgets('loaded body has SafeArea with top: false', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
      expect(safeAreas.any((sa) => !sa.top), isTrue);
    });
  });

  group('CollectionDetailScreen — live-reload on route pop', () {
    testWidgets('silent re-fetch after sheet dismiss reflects updated item', (
      tester,
    ) async {
      final repo = _UpdatingCollectionRepository(
        first: _makeItem(title: 'Old Title'),
        second: _makeItem(title: 'New Title'),
      );
      await tester.pumpWidget(
        _wrapWithObserver(
          CollectionDetailScreen(itemId: 'test-1', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old Title'), findsWidgets);

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      // Dismiss sheet by tapping the modal barrier above it
      await tester.tapAt(const Offset(200, 50));
      await tester.pumpAndSettle();

      expect(find.text('New Title'), findsWidgets);
      expect(find.text('Old Title'), findsNothing);
    });

    testWidgets(
      'silent re-fetch after sheet dismiss transitions to not-found if item removed',
      (tester) async {
        final repo = _ThenRemovedCollectionRepository(
          firstItem: _makeItem(title: 'Will Be Removed'),
        );
        await tester.pumpWidget(
          _wrapWithObserver(
            CollectionDetailScreen(itemId: 'test-1', repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Will Be Removed'), findsWidgets);

        await tester.tap(find.byKey(const Key('edit-conditions-button')));
        await tester.pumpAndSettle();

        // Dismiss sheet by tapping the modal barrier above it
        await tester.tapAt(const Offset(200, 50));
        await tester.pumpAndSettle();

        expect(find.text('Item not found.'), findsOneWidget);
        expect(find.text('Will Be Removed'), findsNothing);
      },
    );
  });
}

import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/presentation/screens/collection_detail_screen.dart';
import 'package:cratewise/presentation/screens/collection_screen.dart';
import 'package:cratewise/presentation/widgets/collection_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  _FakeCollectionRepository({this.items = const [], this.throwsOnLoad = false});

  final List<CollectionItem> items;
  final bool throwsOnLoad;
  int loadCallCount = 0;

  @override
  Future<List<CollectionItem>> getAll() async {
    loadCallCount++;
    if (throwsOnLoad) throw Exception('db error');
    return List.of(items);
  }

  @override
  Future<CollectionItem?> getById(String id) async =>
      items.where((i) => i.id == id).firstOrNull;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;

  @override
  Future<void> add(CollectionItem item) async {}

  @override
  Future<void> update(CollectionItem item) async {}

  @override
  Future<void> remove(String id) async {}
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
}

class _FlippingCollectionRepository implements CollectionRepository {
  _FlippingCollectionRepository({required this.successItems});

  final List<CollectionItem> successItems;
  int _callCount = 0;

  @override
  Future<List<CollectionItem>> getAll() async {
    _callCount++;
    if (_callCount == 1) throw Exception('first load fails');
    return List.of(successItems);
  }

  @override
  Future<CollectionItem?> getById(String id) async => null;
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
  int releaseId = 1,
  String artist = 'Test Artist',
  String title = 'Test Album',
  String? label,
  int? year,
  String? format,
  String? storageLocation,
}) =>
    CollectionItem(
      id: id,
      discogsReleaseId: releaseId,
      artist: artist,
      title: title,
      label: label,
      format: format,
      year: year,
      coverUrl: null,
      mediaCondition: RecordCondition.veryGood,
      sleeveCondition: RecordCondition.veryGood,
      tags: const [],
      storageLocation: storageLocation,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionScreen — loading state', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      // Before pumping async load: loading state visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides loading indicator after load completes', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('CollectionScreen — empty state', () {
    testWidgets('shows empty state title when collection is empty',
        (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Your collection is empty'), findsOneWidget);
    });

    testWidgets('shows offline capability in empty state body text',
        (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('saved on this device'), findsOneWidget);
    });

    testWidgets('shows how-to-add hint in empty state', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Search tab'), findsOneWidget);
    });

    testWidgets('does not show any CollectionItemCard when empty',
        (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionItemCard), findsNothing);
    });
  });

  group('CollectionScreen — list', () {
    testWidgets('shows one card per item', (tester) async {
      final repo = _FakeCollectionRepository(
        items: [_makeItem(id: 'a'), _makeItem(id: 'b'), _makeItem(id: 'c')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionItemCard), findsNWidgets(3));
    });

    testWidgets('shows artist name', (tester) async {
      final repo =
          _FakeCollectionRepository(items: [_makeItem(artist: 'Miles Davis')]);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('shows title', (tester) async {
      final repo = _FakeCollectionRepository(
          items: [_makeItem(title: 'Kind of Blue')]);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Kind of Blue'), findsOneWidget);
    });

    testWidgets('does not show empty state text when items present',
        (tester) async {
      final repo = _FakeCollectionRepository(items: [_makeItem()]);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Your collection is empty'), findsNothing);
    });
  });

  group('CollectionScreen — error state', () {
    testWidgets('shows error message when load fails', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('device storage'), findsOneWidget);
    });

    testWidgets('shows Retry button in error state', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry calls getAll again', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repo.loadCallCount, 2);
    });

    testWidgets('retry can recover to loaded state', (tester) async {
      final repo = _FlippingCollectionRepository(
        successItems: [_makeItem(artist: 'Recovered Artist')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      // First load fails — error state
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      // Second load succeeds
      expect(find.text('Recovered Artist'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('CollectionScreen — search field', () {
    testWidgets('shows search field', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('search field present during loading state', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      // Before settle — still loading
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('clear button hidden when search is empty', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Clear search'), findsNothing);
    });

    testWidgets('clear button appears after typing', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'jazz');
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsOneWidget);
    });

    testWidgets('clear button hides after tapping clear', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'jazz');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });

  group('CollectionScreen — navigation', () {
    testWidgets('tapping a card opens CollectionDetailScreen', (tester) async {
      final repo = _FakeCollectionRepository(
        items: [_makeItem(id: 'detail-id-1')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CollectionItemCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(CollectionDetailScreen), findsOneWidget);
    });

    testWidgets('detail screen shows data for the tapped item', (tester) async {
      final repo = _FakeCollectionRepository(
        items: [_makeItem(id: 'my-unique-id', artist: 'Detail Artist')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CollectionItemCard).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Detail Artist'), findsOneWidget);
    });

    testWidgets('back navigation returns to collection list', (tester) async {
      final repo = _FakeCollectionRepository(
        items: [_makeItem(id: 'nav-test-id', artist: 'Return Artist')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CollectionItemCard).first);
      await tester.pumpAndSettle();
      // Detail screen is shown
      expect(find.byType(CollectionDetailScreen), findsOneWidget);
      // Navigate back
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();
      // Collection list is visible again
      expect(find.text('Return Artist'), findsOneWidget);
    });
  });

  group('CollectionItemCard — optional fields', () {
    testWidgets('shows label when provided', (tester) async {
      final repo =
          _FakeCollectionRepository(items: [_makeItem(label: 'Blue Note')]);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Blue Note'), findsOneWidget);
    });

    testWidgets('shows year when provided', (tester) async {
      final repo =
          _FakeCollectionRepository(items: [_makeItem(year: 1959)]);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('1959'), findsOneWidget);
    });

    testWidgets('shows format when provided', (tester) async {
      final repo =
          _FakeCollectionRepository(items: [_makeItem(format: 'LP')]);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('LP'), findsOneWidget);
    });

    testWidgets('shows storage location when provided', (tester) async {
      final repo =
          _FakeCollectionRepository(items: [_makeItem(storageLocation: 'Shelf B3')]);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Shelf B3'), findsOneWidget);
    });

    testWidgets('renders without error when all optional fields are null',
        (tester) async {
      final repo = _FakeCollectionRepository(
        items: [_makeItem(label: null, year: null, format: null, storageLocation: null)],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionItemCard), findsOneWidget);
    });

    testWidgets('joins label, year, and format with separator', (tester) async {
      final repo = _FakeCollectionRepository(
        items: [_makeItem(label: 'Columbia', year: 1959, format: 'LP')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Columbia · 1959 · LP'), findsOneWidget);
    });
  });

  group('CollectionScreen — local-first', () {
    testWidgets('loads without a Discogs token', (tester) async {
      // No token is passed or required — repository is purely local.
      final repo = _FakeCollectionRepository(
        items: [_makeItem(artist: 'Offline Artist')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Offline Artist'), findsOneWidget);
    });

    testWidgets('loads without network (simulated by local-only fake repo)',
        (tester) async {
      final repo = _FakeCollectionRepository(
        items: [_makeItem(artist: 'No Network Artist')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('No Network Artist'), findsOneWidget);
    });

    testWidgets('empty state mentions device storage', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('saved on this device'), findsOneWidget);
    });

    testWidgets('empty state mentions offline capability', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('without internet'), findsOneWidget);
    });

    testWidgets('error state message mentions device storage', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('device storage'), findsOneWidget);
    });
  });

  group('CollectionScreen — iPad layout', () {
    testWidgets('shows GridView at wide breakpoint', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeCollectionRepository(
        items: [_makeItem(id: 'a'), _makeItem(id: 'b')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('GridView shows all item cards', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeCollectionRepository(
        items: [
          _makeItem(id: 'a', artist: 'Artist A'),
          _makeItem(id: 'b', artist: 'Artist B'),
          _makeItem(id: 'c', artist: 'Artist C'),
          _makeItem(id: 'd', artist: 'Artist D'),
        ],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionItemCard), findsNWidgets(4));
    });

    testWidgets('narrow screen does not show GridView', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeCollectionRepository(
        items: [_makeItem(id: 'a'), _makeItem(id: 'b')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(CollectionItemCard), findsNWidgets(2));
    });

    testWidgets('tapping card in GridView opens CollectionDetailScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeCollectionRepository(
        items: [_makeItem(id: 'grid-detail-1', artist: 'Grid Artist')],
      );
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CollectionItemCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(CollectionDetailScreen), findsOneWidget);
    });

    testWidgets('empty state shows without GridView at wide breakpoint',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(_wrap(CollectionScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(find.text('Your collection is empty'), findsOneWidget);
    });
  });

  group('CollectionScreen — thumbnail cache', () {
    testWidgets('renders list without crash when thumbnailRepository returns null',
        (tester) async {
      final repo = _FakeCollectionRepository(items: [_makeItem()]);
      final thumbRepo = _FakeThumbnailRepository();
      await tester.pumpWidget(
        _wrap(CollectionScreen(repository: repo, thumbnailRepository: thumbRepo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CollectionItemCard), findsOneWidget);
    });

    testWidgets(
        'renders list without crash when thumbnailRepository returns a cached path',
        (tester) async {
      final repo = _FakeCollectionRepository(items: [_makeItem()]);
      final thumbRepo = _FakeThumbnailRepository(pathToReturn: '/fake/thumb.jpg');
      await tester.pumpWidget(
        _wrap(CollectionScreen(repository: repo, thumbnailRepository: thumbRepo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CollectionItemCard), findsOneWidget);
      expect(find.byKey(const Key('collection-cached-cover')), findsOneWidget);
    });
  });
}

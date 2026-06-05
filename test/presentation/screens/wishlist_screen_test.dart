import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/wishlist_detail_screen.dart';
import 'package:cratewise/presentation/screens/wishlist_screen.dart';
import 'package:cratewise/presentation/widgets/wishlist_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

class _UpdatingWishlistRepository implements WishlistRepository {
  _UpdatingWishlistRepository({required this.first, required this.second});

  final List<WishlistItem> first;
  final List<WishlistItem> second;
  int _calls = 0;

  @override
  Future<List<WishlistItem>> getAll() async {
    _calls++;
    return _calls == 1 ? List.of(first) : List.of(second);
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

class _SuccessThenErrorWishlistRepository implements WishlistRepository {
  _SuccessThenErrorWishlistRepository({required this.successItems});

  final List<WishlistItem> successItems;
  int _calls = 0;

  @override
  Future<List<WishlistItem>> getAll() async {
    _calls++;
    if (_calls == 1) return List.of(successItems);
    throw Exception('refresh error');
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
}) => WishlistItem(
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

GoRouter _makeWishlistRouter({
  required WishlistRepository repo,
  ThumbnailRepository? thumbnailRepo,
}) {
  return GoRouter(
    initialLocation: '/wishlist',
    routes: [
      GoRoute(
        path: '/wishlist',
        builder: (_, _) => Scaffold(
          body: WishlistScreen(
            repository: repo,
            thumbnailRepository: thumbnailRepo,
          ),
        ),
        routes: [
          GoRoute(
            path: ':itemId',
            builder: (_, state) => WishlistDetailScreen(
              itemId: state.pathParameters['itemId']!,
              repository: repo,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _wrapNavigable(GoRouter router) =>
    MaterialApp.router(routerConfig: router);

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
    testWidgets('shows empty state when repository returns no items', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(WishlistItemCard), findsNothing);
      expect(find.text('Your wishlist is empty'), findsOneWidget);
    });

    testWidgets('shows offline capability in empty state body text', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('saved on this device'), findsOneWidget);
    });

    testWidgets('shows how-to-add hint in empty state', (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Search tab'), findsOneWidget);
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
      final repo = _FakeWishlistRepository(
        items: [
          _makeItem(id: 'a', releaseId: 1),
          _makeItem(id: 'b', releaseId: 2),
          _makeItem(id: 'c', releaseId: 3),
        ],
      );
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
      expect(find.textContaining('device storage'), findsOneWidget);
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
        _wrap(
          WishlistItemCard(
            item: _makeItem(priority: WishlistPriority.mustHave),
          ),
        ),
      );
      expect(find.text('Must have'), findsOneWidget);
    });

    testWidgets('shows Low priority label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WishlistItemCard(item: _makeItem(priority: WishlistPriority.low)),
        ),
      );
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('shows High priority label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WishlistItemCard(item: _makeItem(priority: WishlistPriority.high)),
        ),
      );
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('shows meta row with label · year · format', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WishlistItemCard(
            item: _makeItem(label: 'Columbia', year: 1959, format: 'Vinyl, LP'),
          ),
        ),
      );
      expect(find.text('Columbia · 1959 · Vinyl, LP'), findsOneWidget);
    });

    testWidgets('shows partial meta when some fields are null', (tester) async {
      await tester.pumpWidget(
        _wrap(WishlistItemCard(item: _makeItem(label: 'Impulse!', year: 1965))),
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
      await tester.pumpWidget(_wrap(WishlistItemCard(item: _makeItem())));
      expect(find.byIcon(Icons.sell_outlined), findsNothing);
    });

    testWidgets('shows cover placeholder icon when coverUrl is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(WishlistItemCard(item: _makeItem())));
      expect(find.byIcon(Icons.album), findsOneWidget);
    });
  });

  group('WishlistScreen — local-first', () {
    testWidgets('loads without a Discogs token', (tester) async {
      final repo = _FakeWishlistRepository(
        items: [_makeItem(artist: 'Offline Artist')],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Offline Artist'), findsOneWidget);
    });

    testWidgets('loads without network (simulated by local-only fake repo)', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository(
        items: [_makeItem(artist: 'No Network Artist')],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('No Network Artist'), findsOneWidget);
    });

    testWidgets('empty state mentions device storage', (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('saved on this device'), findsOneWidget);
    });

    testWidgets('empty state mentions offline capability', (tester) async {
      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('without internet'), findsOneWidget);
    });

    testWidgets('error state message mentions device storage', (tester) async {
      final repo = _FakeWishlistRepository(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.textContaining('device storage'), findsOneWidget);
    });
  });

  group('WishlistScreen — navigation', () {
    testWidgets('tapping a card opens WishlistDetailScreen', (tester) async {
      final repo = _FakeWishlistRepository(
        items: [_makeItem(id: 'detail-id-1')],
      );
      final router = _makeWishlistRouter(repo: repo);
      await tester.pumpWidget(_wrapNavigable(router));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(WishlistItemCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(WishlistDetailScreen), findsOneWidget);
    });

    testWidgets('detail screen shows data for the tapped item', (tester) async {
      final repo = _FakeWishlistRepository(
        items: [_makeItem(id: 'unique-id', artist: 'Nav Artist')],
      );
      final router = _makeWishlistRouter(repo: repo);
      await tester.pumpWidget(_wrapNavigable(router));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(WishlistItemCard).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Nav Artist'), findsOneWidget);
    });

    testWidgets('back navigation returns to wishlist list', (tester) async {
      final repo = _FakeWishlistRepository(
        items: [_makeItem(id: 'back-nav-id', artist: 'Return Artist')],
      );
      final router = _makeWishlistRouter(repo: repo);
      await tester.pumpWidget(_wrapNavigable(router));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(WishlistItemCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(WishlistDetailScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Return Artist'), findsOneWidget);
    });
  });

  group('WishlistScreen — thumbnail cache', () {
    testWidgets(
      'renders list without crash when thumbnailRepository returns null',
      (tester) async {
        final repo = _FakeWishlistRepository(items: [_makeItem()]);
        final thumbRepo = _FakeThumbnailRepository();
        await tester.pumpWidget(
          _wrap(
            WishlistScreen(repository: repo, thumbnailRepository: thumbRepo),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(WishlistItemCard), findsOneWidget);
      },
    );

    testWidgets(
      'renders list without crash when thumbnailRepository returns a cached path',
      (tester) async {
        final repo = _FakeWishlistRepository(items: [_makeItem()]);
        final thumbRepo = _FakeThumbnailRepository(
          pathToReturn: '/fake/thumb.jpg',
        );
        await tester.pumpWidget(
          _wrap(
            WishlistScreen(repository: repo, thumbnailRepository: thumbRepo),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(WishlistItemCard), findsOneWidget);
        expect(find.byKey(const Key('wishlist-cached-cover')), findsOneWidget);
      },
    );
  });

  group('WishlistScreen — iPad layout', () {
    testWidgets('shows GridView at wide breakpoint', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeWishlistRepository(
        items: [
          _makeItem(id: 'a'),
          _makeItem(id: 'b'),
        ],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('GridView shows all item cards', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeWishlistRepository(
        items: [
          _makeItem(id: 'a', artist: 'Artist A'),
          _makeItem(id: 'b', artist: 'Artist B'),
          _makeItem(id: 'c', artist: 'Artist C'),
        ],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(WishlistItemCard), findsNWidgets(3));
    });

    testWidgets('narrow screen does not show GridView', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeWishlistRepository(
        items: [
          _makeItem(id: 'a'),
          _makeItem(id: 'b'),
        ],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(WishlistItemCard), findsNWidgets(2));
    });

    testWidgets('tapping card in GridView opens WishlistDetailScreen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeWishlistRepository(
        items: [_makeItem(id: 'grid-detail-1', artist: 'Grid Artist')],
      );
      final router = _makeWishlistRouter(repo: repo);
      await tester.pumpWidget(_wrapNavigable(router));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(WishlistItemCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(WishlistDetailScreen), findsOneWidget);
    });

    testWidgets('empty state shows without GridView at wide breakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeWishlistRepository();
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(find.text('Your wishlist is empty'), findsOneWidget);
    });
  });

  group('WishlistScreen — pull-to-refresh', () {
    testWidgets('RefreshIndicator present on loaded list', (tester) async {
      final repo = _FakeWishlistRepository(items: [_makeItem()]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('PTR triggers getAll again', (tester) async {
      final repo = _FakeWishlistRepository(items: [_makeItem()]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(repo.loadCallCount, 1);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      expect(repo.loadCallCount, 2);
    });

    testWidgets('PTR updates list with new items', (tester) async {
      final repo = _UpdatingWishlistRepository(
        first: [_makeItem(id: 'a', artist: 'Before')],
        second: [_makeItem(id: 'b', artist: 'After')],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Before'), findsOneWidget);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      expect(find.text('After'), findsOneWidget);
      expect(find.text('Before'), findsNothing);
    });

    testWidgets('PTR error keeps existing items visible', (tester) async {
      final repo = _SuccessThenErrorWishlistRepository(
        successItems: [_makeItem(artist: 'Kept Artist')],
      );
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
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
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });

  group('WishlistScreen — search filter', () {
    final miles = _makeItem(
      id: '1',
      artist: 'Miles Davis',
      title: 'Kind of Blue',
    );
    final coltrane = _makeItem(
      id: '2',
      artist: 'John Coltrane',
      title: 'A Love Supreme',
    );

    testWidgets('filters by artist when query matches', (tester) async {
      final repo = _FakeWishlistRepository(items: [miles, coltrane]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('Miles Davis'), findsOneWidget);
      expect(find.text('John Coltrane'), findsNothing);
    });

    testWidgets('filters by title when query matches', (tester) async {
      final repo = _FakeWishlistRepository(items: [miles, coltrane]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'supreme');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('John Coltrane'), findsOneWidget);
      expect(find.text('Miles Davis'), findsNothing);
    });

    testWidgets('shows no-results message when filter matches nothing', (
      tester,
    ) async {
      final repo = _FakeWishlistRepository(items: [miles, coltrane]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzznomatch');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.textContaining('No results'), findsOneWidget);
      expect(find.byType(WishlistItemCard), findsNothing);
    });

    testWidgets('no-results message includes the search query', (tester) async {
      final repo = _FakeWishlistRepository(items: [miles, coltrane]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'jazz fusion');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(
        find.textContaining('No results for "jazz fusion"'),
        findsOneWidget,
      );
    });

    testWidgets('clearing search restores the full list', (tester) async {
      final repo = _FakeWishlistRepository(items: [miles, coltrane]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('John Coltrane'), findsNothing);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.text('Miles Davis'), findsOneWidget);
      expect(find.text('John Coltrane'), findsOneWidget);
    });

    testWidgets('filter is case-insensitive', (tester) async {
      final repo = _FakeWishlistRepository(items: [miles, coltrane]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'MILES');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('Miles Davis'), findsOneWidget);
      expect(find.text('John Coltrane'), findsNothing);
    });

    testWidgets('list is not filtered before debounce fires', (tester) async {
      final repo = _FakeWishlistRepository(items: [miles, coltrane]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(); // single frame — debounce not yet fired

      expect(find.text('Miles Davis'), findsOneWidget);
      expect(find.text('John Coltrane'), findsOneWidget);
    });

    testWidgets('filter works in iPad GridView layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeWishlistRepository(items: [miles, coltrane]);
      await tester.pumpWidget(_wrap(WishlistScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('Miles Davis'), findsOneWidget);
      expect(find.text('John Coltrane'), findsNothing);

      await tester.binding.setSurfaceSize(null);
    });
  });
}

import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/cached_release_metadata_repository.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/presentation/screens/collection_statistics_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  _FakeCollectionRepository(this._items);
  final List<CollectionItem> _items;
  int getAllCallCount = 0;

  @override
  Future<List<CollectionItem>> getAll() async {
    getAllCallCount++;
    return List.of(_items);
  }

  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> deleteAll() async {}
}

class _ErrorCollectionRepository implements CollectionRepository {
  @override
  Future<List<CollectionItem>> getAll() => Future.error('db error');
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> deleteAll() async {}
}

class _FakeMetadataRepository implements CachedReleaseMetadataRepository {
  _FakeMetadataRepository([this._items = const []]);
  final List<CachedReleaseMetadata> _items;

  @override
  Future<List<CachedReleaseMetadata>> getAll() async => List.of(_items);
  @override
  Future<CachedReleaseMetadata?> getByReleaseId(int id) async => null;
  @override
  Future<void> save(CachedReleaseMetadata m) async {}
  @override
  Future<void> remove(int id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _item({
  String id = 'x',
  int discogsReleaseId = 1,
  String artist = 'Artist',
}) => CollectionItem(
  id: id,
  discogsReleaseId: discogsReleaseId,
  artist: artist,
  title: 'Title',
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: const [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

CachedReleaseMetadata _meta({
  required int releaseId,
  required List<String> genres,
  required List<String> styles,
}) => CachedReleaseMetadata(
  discogsReleaseId: releaseId,
  artist: 'Artist',
  title: 'Title',
  genres: genres,
  styles: styles,
  tracklist: const [],
  identifiers: const [],
  fetchedAt: DateTime(2024),
  cacheSource: 'discogs',
  syncStatus: SyncStatus.localOnly,
);

Widget _wrap(Widget child) => MaterialApp(home: child);

Widget _screen({
  List<CollectionItem> items = const [],
  List<CachedReleaseMetadata> metadata = const [],
  CollectionRepository? collectionRepo,
}) => _wrap(
  CollectionStatisticsScreen(
    repository: collectionRepo ?? _FakeCollectionRepository(items),
    metadataRepository: _FakeMetadataRepository(metadata),
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionStatisticsScreen (US-115 / US-123)', () {
    testWidgets('shows loading indicator before future completes', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(items: [_item()]));
      // Do not pumpAndSettle — future hasn't completed yet.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is a tab: no app bar and no back button (US-140)', (
      tester,
    ) async {
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.text('Collection statistics'), findsNothing);
    });

    testWidgets('reloads when the tab becomes visible again (US-140)', (
      tester,
    ) async {
      final items = [_item(id: 'a', discogsReleaseId: 1)];
      final repo = _FakeCollectionRepository(items);
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      // go_router hides inactive tabs with TickerMode(enabled: false).
      await tester.pumpWidget(
        _wrap(
          ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (_, on, child) => TickerMode(enabled: on, child: child!),
            child: CollectionStatisticsScreen(
              repository: repo,
              metadataRepository: _FakeMetadataRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.getAllCallCount, 1);
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-total')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      // Leave the tab, add a record elsewhere, come back.
      visible.value = false;
      await tester.pump();
      items.add(_item(id: 'b', discogsReleaseId: 2));
      expect(repo.getAllCallCount, 1, reason: 'no reload while hidden');
      visible.value = true;
      await tester.pumpAndSettle();

      expect(repo.getAllCallCount, 2);
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-total')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows total records count', (tester) async {
      await tester.pumpWidget(
        _screen(
          items: [
            _item(id: '1'),
            _item(id: '2'),
            _item(id: '3'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final statTile = find.byKey(const Key('stat-total'));
      expect(statTile, findsOneWidget);
      expect(
        find.descendant(of: statTile, matching: find.text('3')),
        findsOneWidget,
      );
    });

    testWidgets('shows zero records for empty collection', (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();
      final statTile = find.byKey(const Key('stat-total'));
      expect(statTile, findsOneWidget);
      expect(
        find.descendant(of: statTile, matching: find.text('0')),
        findsOneWidget,
      );
    });

    testWidgets('shows error message when repo throws', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CollectionStatisticsScreen(
            repository: _ErrorCollectionRepository(),
            metadataRepository: _FakeMetadataRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load statistics.'), findsOneWidget);
    });

    testWidgets('calls getAll exactly once (no Discogs API calls)', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository([_item()]);
      await tester.pumpWidget(
        _wrap(
          CollectionStatisticsScreen(
            repository: repo,
            metadataRepository: _FakeMetadataRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.getAllCallCount, 1);
    });

    testWidgets('shows overview section stat chips', (tester) async {
      await tester.pumpWidget(_screen(items: [_item()]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stat-total')), findsOneWidget);
      expect(find.byKey(const Key('stat-artists')), findsOneWidget);
      expect(find.byKey(const Key('stat-labels')), findsOneWidget);
      expect(find.byKey(const Key('stat-missing-cover')), findsOneWidget);
      expect(find.byKey(const Key('stat-missing-year')), findsOneWidget);
    });

    testWidgets('genre section visible when metadata available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          items: [_item(id: '1', discogsReleaseId: 42)],
          metadata: [
            _meta(releaseId: 42, genres: ['Rock'], styles: ['Punk']),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('By genre'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
    });

    testWidgets('style section visible when metadata available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          items: [_item(id: '1', discogsReleaseId: 42)],
          metadata: [
            _meta(releaseId: 42, genres: [], styles: ['Punk']),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('By style'), findsOneWidget);
      expect(find.text('Punk'), findsOneWidget);
    });

    testWidgets('genre/style sections absent when no metadata', (tester) async {
      await tester.pumpWidget(_screen(items: [_item()]));
      await tester.pumpAndSettle();
      expect(find.text('By genre'), findsNothing);
      expect(find.text('By style'), findsNothing);
    });
  });
}

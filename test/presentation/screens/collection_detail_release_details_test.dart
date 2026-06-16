import 'package:cratewise/application/services/discogs_release_detail_service.dart';
import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/release_detail.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/cached_release_metadata_repository.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/presentation/screens/collection_detail_screen.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeCollectionRepository({this.item});

  final CollectionItem? item;

  @override
  Future<CollectionItem?> getById(String id) async => item;
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

class _FakeCacheRepository implements CachedReleaseMetadataRepository {
  _FakeCacheRepository({this.metadata});

  final CachedReleaseMetadata? metadata;

  @override
  Future<CachedReleaseMetadata?> getByReleaseId(int discogsReleaseId) async =>
      metadata;
  @override
  Future<void> save(CachedReleaseMetadata metadata) async {}
  @override
  Future<void> remove(int discogsReleaseId) async {}
}

class _FakeDetailService extends DiscogsReleaseDetailService {
  _FakeDetailService({this.detail, this.error, super.cacheRepository});

  final ReleaseDetail? detail;
  final AppError? error;
  int fetchCallCount = 0;

  @override
  Future<ReleaseDetail> fetchDetail(int releaseId) async {
    fetchCallCount++;
    if (error != null) throw error!;
    return detail!;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _makeItem() => CollectionItem(
  id: 'test-1',
  discogsReleaseId: 193467,
  artist: 'Test Artist',
  title: 'Test Album',
  coverUrl: null,
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: const [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

const _tracks = [
  ReleaseTrack(position: 'A1', title: 'Opening Track', duration: '4:20'),
  ReleaseTrack(position: 'B2', title: 'Closing Track', duration: '6:01'),
];

ReleaseDetail _makeDetail() => const ReleaseDetail(
  id: 193467,
  title: 'Test Album',
  artist: 'Test Artist',
  label: 'Warp Records',
  catno: 'WARP123',
  format: '2×LP, Album',
  country: 'UK',
  year: 1999,
  genres: ['Electronic'],
  styles: ['IDM', 'Ambient'],
  tracklist: _tracks,
  notes: 'Gatefold sleeve.',
  coverUrl: null,
  identifiers: [],
);

CachedReleaseMetadata _makeMetadata() => CachedReleaseMetadata(
  discogsReleaseId: 193467,
  artist: 'Test Artist',
  title: 'Test Album',
  label: 'Warp Records',
  catno: 'WARP123',
  format: '2×LP, Album',
  country: 'UK',
  year: 1999,
  genres: const ['Electronic'],
  styles: const ['IDM', 'Ambient'],
  tracklist: _tracks,
  notes: 'Gatefold sleeve.',
  identifiers: const [],
  coverUrl: null,
  fetchedAt: DateTime(2026, 6, 10),
  cacheSource: 'api',
  syncStatus: SyncStatus.localOnly,
);

Widget _wrap(Widget child) => MaterialApp(home: child);

void _expectFullDetails() {
  expect(find.text('Label'), findsOneWidget);
  expect(find.text('Warp Records — WARP123'), findsOneWidget);
  expect(find.text('Format'), findsOneWidget);
  expect(find.text('2×LP, Album'), findsOneWidget);
  expect(find.text('Country'), findsOneWidget);
  expect(find.text('UK'), findsOneWidget);
  expect(find.text('Released'), findsOneWidget);
  expect(find.text('1999'), findsOneWidget);
  expect(find.text('Genre'), findsOneWidget);
  expect(find.text('Electronic'), findsOneWidget);
  expect(find.text('Style'), findsOneWidget);
  expect(find.text('IDM, Ambient'), findsOneWidget);
  expect(find.text('Discogs ID'), findsOneWidget);
  expect(find.text('193467'), findsOneWidget);
  expect(find.text('Tracklist'), findsOneWidget);
  expect(find.text('Opening Track'), findsOneWidget);
  expect(find.text('Closing Track'), findsOneWidget);
  expect(find.text('Release Notes'), findsOneWidget);
  expect(find.text('Gatefold sleeve.'), findsOneWidget);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionDetailScreen — release details (US-74)', () {
    testWidgets('always shows the Discogs ID from the local item', (
      tester,
    ) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discogs ID'), findsOneWidget);
      expect(find.text('193467'), findsOneWidget);
    });

    testWidgets('shows full release details from cached metadata '
        'without calling the API', (tester) async {
      final service = _FakeDetailService(
        detail: _makeDetail(),
        cacheRepository: _FakeCacheRepository(metadata: _makeMetadata()),
      );
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(
            itemId: 'test-1',
            repository: _FakeCollectionRepository(item: _makeItem()),
            releaseDetailService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      _expectFullDetails();
      expect(service.fetchCallCount, 0);
    });

    testWidgets('fetches details live when the release is not cached', (
      tester,
    ) async {
      final service = _FakeDetailService(
        detail: _makeDetail(),
        cacheRepository: _FakeCacheRepository(),
      );
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(
            itemId: 'test-1',
            repository: _FakeCollectionRepository(item: _makeItem()),
            releaseDetailService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      _expectFullDetails();
      expect(service.fetchCallCount, 1);
    });

    testWidgets('local item view is unchanged when no cache and fetch fails', (
      tester,
    ) async {
      final service = _FakeDetailService(
        error: const NoTokenError(),
        cacheRepository: _FakeCacheRepository(),
      );
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(
            itemId: 'test-1',
            repository: _FakeCollectionRepository(item: _makeItem()),
            releaseDetailService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Album'), findsWidgets);
      expect(find.text('Tracklist'), findsNothing);
      expect(find.text('Genre'), findsNothing);
      expect(find.text('Release Notes'), findsNothing);
      // The locally known rows still render.
      expect(find.text('Discogs ID'), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
    });
  });
}

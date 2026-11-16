import 'dart:io';

import 'package:cratewise/application/services/thumbnail_cache_service.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/collection_detail_screen.dart';
import 'package:cratewise/presentation/screens/wishlist_detail_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _StubThumbnailRepository implements ThumbnailRepository {
  @override
  Future<String?> getLocalPath(int releaseId) async => null;
  @override
  Future<void> save(int releaseId, List<int> bytes) async {}
  @override
  Future<void> remove(int releaseId) async {}
  @override
  Future<bool> exists(int releaseId) async => false;
  @override
  Future<int> totalSizeBytes() async => 0;
  @override
  Future<List<ThumbnailEntry>> listEntries() async => [];
  @override
  Future<void> removeAll() async {}
}

/// Records getOrFetch calls and returns a configurable path, standing in for
/// the cache-or-download behaviour without any network.
class _FakeThumbnailCacheService extends ThumbnailCacheService {
  _FakeThumbnailCacheService({this.pathToReturn})
    : super(repository: _StubThumbnailRepository());

  final String? pathToReturn;
  final List<(int, String?)> calls = [];

  @override
  Future<String?> getOrFetch(int releaseId, String? imageUrl) async {
    calls.add((releaseId, imageUrl));
    return pathToReturn;
  }
}

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

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeWishlistRepository({this.item});
  final WishlistItem? item;

  @override
  Future<WishlistItem?> getById(String id) async => item;
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

const _coverUrl = 'https://i.discogs.com/cover-150.jpg';

CollectionItem _makeCollectionItem({String? coverUrl = _coverUrl}) =>
    CollectionItem(
      id: 'c-1',
      discogsReleaseId: 193467,
      artist: 'Test Artist',
      title: 'Test Album',
      coverUrl: coverUrl,
      mediaCondition: RecordCondition.notSet,
      sleeveCondition: RecordCondition.notSet,
      tags: const [],
      syncStatus: SyncStatus.localOnly,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

WishlistItem _makeWishlistItem({String? coverUrl = _coverUrl}) => WishlistItem(
  id: 'w-1',
  discogsReleaseId: 193467,
  artist: 'Test Artist',
  title: 'Test Album',
  priority: WishlistPriority.medium,
  coverUrl: coverUrl,
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

Widget _wrap(Widget child) => MaterialApp(home: child);

/// A real 1×1 transparent PNG so Image.file can decode successfully.
const _kTransparentPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82,
];

String _writeTempPng() {
  final file = File(
    '${Directory.systemTemp.path}/cratewise_test_cover_'
    '${DateTime.now().microsecondsSinceEpoch}.png',
  );
  file.writeAsBytesSync(_kTransparentPng);
  return file.path;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionDetailScreen — cover image (US-75)', () {
    testWidgets('requests the cover via getOrFetch with the item cover URL', (
      tester,
    ) async {
      final cache = _FakeThumbnailCacheService(pathToReturn: _writeTempPng());
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(
            itemId: 'c-1',
            repository: _FakeCollectionRepository(item: _makeCollectionItem()),
            thumbnailCacheService: cache,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(cache.calls, contains((193467, _coverUrl)));
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('No cover'), findsNothing);
    });

    testWidgets('shows the placeholder when no URL and nothing cached', (
      tester,
    ) async {
      final cache = _FakeThumbnailCacheService();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(
            itemId: 'c-1',
            repository: _FakeCollectionRepository(
              item: _makeCollectionItem(coverUrl: null),
            ),
            thumbnailCacheService: cache,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No cover'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('WishlistDetailScreen — cover image (US-75)', () {
    testWidgets('requests the cover via getOrFetch with the item cover URL', (
      tester,
    ) async {
      final cache = _FakeThumbnailCacheService(pathToReturn: _writeTempPng());
      await tester.pumpWidget(
        _wrap(
          WishlistDetailScreen(
            itemId: 'w-1',
            repository: _FakeWishlistRepository(item: _makeWishlistItem()),
            thumbnailCacheService: cache,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(cache.calls, contains((193467, _coverUrl)));
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('No cover'), findsNothing);
    });

    testWidgets('shows the placeholder when no URL and nothing cached', (
      tester,
    ) async {
      final cache = _FakeThumbnailCacheService();
      await tester.pumpWidget(
        _wrap(
          WishlistDetailScreen(
            itemId: 'w-1',
            repository: _FakeWishlistRepository(
              item: _makeWishlistItem(coverUrl: null),
            ),
            thumbnailCacheService: cache,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No cover'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}

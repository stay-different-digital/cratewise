import 'package:cratewise/application/use_cases/build_wishlist_csv_export_preview_use_case.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/csv/wishlist_csv_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  _FakeWishlistRepository(this._items);

  final List<WishlistItem> _items;

  @override
  Future<List<WishlistItem>> getAll() async => _items;

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<bool> containsRelease(int id) async => false;

  @override
  Future<void> add(WishlistItem item) async {}

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _ThrowingWishlistRepository implements WishlistRepository {
  @override
  Future<List<WishlistItem>> getAll() => Future.error(Exception('DB error'));

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<bool> containsRelease(int id) async => false;

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

WishlistItem _item(String id, {String artist = 'Artist'}) => WishlistItem(
      id: id,
      discogsReleaseId: 1,
      artist: artist,
      title: 'Title',
      priority: WishlistPriority.low,
      syncStatus: SyncStatus.localOnly,
      createdAt: DateTime.utc(2024),
      updatedAt: DateTime.utc(2024),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BuildWishlistCsvExportPreviewUseCase', () {
    group('on success', () {
      test('returns WishlistCsvExportPreviewReady', () async {
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _FakeWishlistRepository([_item('a')]),
        );
        final result = await uc.execute();
        expect(result, isA<WishlistCsvExportPreviewReady>());
      });

      test('preview contains all items', () async {
        final items = [_item('a'), _item('b')];
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _FakeWishlistRepository(items),
        );
        final result = await uc.execute() as WishlistCsvExportPreviewReady;
        expect(result.preview.items, items);
      });

      test('preview rowCount equals item count', () async {
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _FakeWishlistRepository([_item('a'), _item('b'), _item('c')]),
        );
        final result = await uc.execute() as WishlistCsvExportPreviewReady;
        expect(result.preview.rowCount, 3);
      });

      test('preview headers equal wishlistCsvHeaders', () async {
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _FakeWishlistRepository([]),
        );
        final result = await uc.execute() as WishlistCsvExportPreviewReady;
        expect(result.preview.headers, wishlistCsvHeaders);
      });

      test('sampleRows contains at most 3 rows', () async {
        final items = List.generate(10, (i) => _item('item-$i'));
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _FakeWishlistRepository(items),
        );
        final result = await uc.execute() as WishlistCsvExportPreviewReady;
        expect(result.preview.sampleRows.length, 3);
      });

      test('sampleRows is empty when no items', () async {
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _FakeWishlistRepository([]),
        );
        final result = await uc.execute() as WishlistCsvExportPreviewReady;
        expect(result.preview.sampleRows, isEmpty);
      });

      test('first sample row artist column matches first item', () async {
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _FakeWishlistRepository(
            [_item('a', artist: 'John Coltrane')],
          ),
        );
        final result = await uc.execute() as WishlistCsvExportPreviewReady;
        expect(result.preview.sampleRows.first[0], 'John Coltrane');
      });

      test('sample row length matches header count', () async {
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _FakeWishlistRepository([_item('a')]),
        );
        final result = await uc.execute() as WishlistCsvExportPreviewReady;
        expect(
          result.preview.sampleRows.first.length,
          result.preview.headers.length,
        );
      });
    });

    group('on repository error', () {
      test('returns WishlistCsvExportPreviewError', () async {
        final uc = BuildWishlistCsvExportPreviewUseCase(
          repository: _ThrowingWishlistRepository(),
        );
        final result = await uc.execute();
        expect(result, isA<WishlistCsvExportPreviewError>());
      });
    });
  });
}

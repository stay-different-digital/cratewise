import 'package:cratewise/application/use_cases/build_collection_csv_export_preview_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/infrastructure/csv/collection_csv_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  _FakeCollectionRepository(this._items);

  final List<CollectionItem> _items;

  @override
  Future<List<CollectionItem>> getAll() async => _items;

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

class _ThrowingCollectionRepository implements CollectionRepository {
  @override
  Future<List<CollectionItem>> getAll() => Future.error(Exception('DB error'));

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
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _item(
  String id, {
  String artist = 'Artist',
  String title = 'Title',
}) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: artist,
  title: title,
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BuildCollectionCsvExportPreviewUseCase', () {
    group('on success', () {
      test('returns CollectionCsvExportPreviewReady', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository([_item('a')]),
        );
        final result = await uc.execute();
        expect(result, isA<CollectionCsvExportPreviewReady>());
      });

      test('preview contains all items', () async {
        final items = [_item('a'), _item('b'), _item('c')];
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository(items),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(result.preview.items, items);
      });

      test('preview rowCount equals item count', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository([_item('a'), _item('b')]),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(result.preview.rowCount, 2);
      });

      test('preview headers equal collectionCsvHeaders', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository([]),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(result.preview.headers, collectionCsvHeaders);
      });

      test('sampleRows contains at most 3 rows', () async {
        final items = List.generate(10, (i) => _item('item-$i'));
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository(items),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(result.preview.sampleRows.length, 3);
      });

      test('sampleRows is empty when no items', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository([]),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(result.preview.sampleRows, isEmpty);
      });

      test('sampleRows has 1 entry for 1 item', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository([_item('a')]),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(result.preview.sampleRows.length, 1);
      });

      test('sampleRows has 2 entries for 2 items', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository([_item('a'), _item('b')]),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(result.preview.sampleRows.length, 2);
      });

      test('first sample row artist column matches first item', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository([
            _item('a', artist: 'Miles Davis'),
          ]),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(result.preview.sampleRows.first[0], 'Miles Davis');
      });

      test('sample row length matches header count', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _FakeCollectionRepository([_item('a')]),
        );
        final result = await uc.execute() as CollectionCsvExportPreviewReady;
        expect(
          result.preview.sampleRows.first.length,
          result.preview.headers.length,
        );
      });
    });

    group('on repository error', () {
      test('returns CollectionCsvExportPreviewError', () async {
        final uc = BuildCollectionCsvExportPreviewUseCase(
          repository: _ThrowingCollectionRepository(),
        );
        final result = await uc.execute();
        expect(result, isA<CollectionCsvExportPreviewError>());
      });
    });
  });
}

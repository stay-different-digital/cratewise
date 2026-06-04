import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/csv_collection_export_preview.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _item(String id) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: 'Artist',
  title: 'Title',
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
);

void main() {
  group('CsvCollectionExportPreview', () {
    test('rowCount returns items.length', () {
      final preview = CsvCollectionExportPreview(
        items: [_item('a'), _item('b'), _item('c')],
        headers: const ['H1', 'H2'],
        sampleRows: const [],
      );
      expect(preview.rowCount, 3);
    });

    test('rowCount is zero for empty items', () {
      final preview = CsvCollectionExportPreview(
        items: const [],
        headers: const ['H1'],
        sampleRows: const [],
      );
      expect(preview.rowCount, 0);
    });

    test('headers are stored as provided', () {
      const headers = ['Artist', 'Title', 'Year'];
      final preview = CsvCollectionExportPreview(
        items: const [],
        headers: headers,
        sampleRows: const [],
      );
      expect(preview.headers, headers);
    });

    test('sampleRows are stored as provided', () {
      const sampleRows = [
        ['Miles Davis', 'Kind of Blue', '1959'],
        ['John Coltrane', 'A Love Supreme', '1965'],
      ];
      final preview = CsvCollectionExportPreview(
        items: const [],
        headers: const [],
        sampleRows: sampleRows,
      );
      expect(preview.sampleRows, sampleRows);
    });
  });
}

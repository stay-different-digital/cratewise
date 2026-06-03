import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/csv_collection_import_preview.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:flutter_test/flutter_test.dart';

CsvCollectionImportRow _row(int rowIndex, {int discogsReleaseId = 1}) =>
    CsvCollectionImportRow(
      rowIndex: rowIndex,
      artist: 'Miles Davis',
      title: 'Kind of Blue',
      discogsReleaseId: discogsReleaseId,
      mediaCondition: RecordCondition.nearMint,
      sleeveCondition: RecordCondition.veryGoodPlus,
      tags: const [],
    );

void main() {
  group('CsvCollectionImportRow', () {
    test('displayName combines artist and title with en-dash', () {
      final row = _row(0);
      expect(row.displayName, 'Miles Davis – Kind of Blue');
    });

    test('optional fields default to null', () {
      final row = _row(0);
      expect(row.label, isNull);
      expect(row.catno, isNull);
      expect(row.format, isNull);
      expect(row.country, isNull);
      expect(row.year, isNull);
      expect(row.notes, isNull);
      expect(row.storageLocation, isNull);
    });

    test('stores all optional fields when provided', () {
      const row = CsvCollectionImportRow(
        rowIndex: 0,
        artist: 'Herbie Hancock',
        title: 'Head Hunters',
        discogsReleaseId: 9999,
        mediaCondition: RecordCondition.veryGoodPlus,
        sleeveCondition: RecordCondition.veryGood,
        tags: ['funk', 'jazz'],
        label: 'Columbia',
        catno: 'PC 32731',
        format: 'LP',
        country: 'US',
        year: 1973,
        notes: 'Original pressing',
        storageLocation: 'Shelf B',
      );
      expect(row.label, 'Columbia');
      expect(row.catno, 'PC 32731');
      expect(row.format, 'LP');
      expect(row.country, 'US');
      expect(row.year, 1973);
      expect(row.notes, 'Original pressing');
      expect(row.storageLocation, 'Shelf B');
      expect(row.tags, ['funk', 'jazz']);
    });
  });

  group('CsvCollectionImportPreview', () {
    test('counts are zero when all lists are empty', () {
      const preview = CsvCollectionImportPreview(
        validRows: [],
        skippedRows: [],
        failedRows: [],
      );
      expect(preview.validCount, 0);
      expect(preview.skippedCount, 0);
      expect(preview.failedCount, 0);
      expect(preview.totalCount, 0);
    });

    test('totalCount sums all three lists', () {
      final preview = CsvCollectionImportPreview(
        validRows: [_row(0), _row(1, discogsReleaseId: 2)],
        skippedRows: [
          const SkippedRow(rowIndex: 2, reason: 'Duplicate release ID in file'),
        ],
        failedRows: [
          const FailedRow(rowIndex: 3, safeErrorMessage: 'Missing artist'),
          const FailedRow(rowIndex: 4, safeErrorMessage: 'Missing title'),
        ],
      );
      expect(preview.validCount, 2);
      expect(preview.skippedCount, 1);
      expect(preview.failedCount, 2);
      expect(preview.totalCount, 5);
    });

    test('validCount only counts valid rows', () {
      final preview = CsvCollectionImportPreview(
        validRows: [_row(0)],
        skippedRows: [],
        failedRows: [
          const FailedRow(rowIndex: 1, safeErrorMessage: 'Missing artist'),
        ],
      );
      expect(preview.validCount, 1);
    });
  });
}

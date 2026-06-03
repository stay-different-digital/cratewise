import 'package:cratewise/domain/models/csv_wishlist_import_preview.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

CsvWishlistImportRow _row(int rowIndex, {int discogsReleaseId = 1}) =>
    CsvWishlistImportRow(
      rowIndex: rowIndex,
      artist: 'Herbie Hancock',
      title: 'Head Hunters',
      discogsReleaseId: discogsReleaseId,
      priority: WishlistPriority.high,
    );

void main() {
  group('CsvWishlistImportRow', () {
    test('displayName combines artist and title with en-dash', () {
      final row = _row(0);
      expect(row.displayName, 'Herbie Hancock – Head Hunters');
    });

    test('optional fields default to null', () {
      final row = _row(0);
      expect(row.label, isNull);
      expect(row.catno, isNull);
      expect(row.format, isNull);
      expect(row.country, isNull);
      expect(row.year, isNull);
      expect(row.targetPrice, isNull);
      expect(row.notes, isNull);
    });

    test('stores all optional fields when provided', () {
      const row = CsvWishlistImportRow(
        rowIndex: 0,
        artist: 'Miles Davis',
        title: 'Bitches Brew',
        discogsReleaseId: 777,
        priority: WishlistPriority.mustHave,
        label: 'Columbia',
        catno: 'GP 26',
        format: '2xLP',
        country: 'US',
        year: 1970,
        targetPrice: 35.50,
        notes: 'Double LP',
      );
      expect(row.label, 'Columbia');
      expect(row.catno, 'GP 26');
      expect(row.format, '2xLP');
      expect(row.country, 'US');
      expect(row.year, 1970);
      expect(row.targetPrice, 35.50);
      expect(row.notes, 'Double LP');
    });
  });

  group('CsvWishlistImportPreview', () {
    test('counts are zero when all lists are empty', () {
      const preview = CsvWishlistImportPreview(
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
      final preview = CsvWishlistImportPreview(
        validRows: [_row(0), _row(1, discogsReleaseId: 2)],
        skippedRows: [
          const SkippedRow(rowIndex: 2, reason: 'Duplicate release ID in file'),
        ],
        failedRows: [
          const FailedRow(rowIndex: 3, safeErrorMessage: 'Missing artist'),
        ],
      );
      expect(preview.validCount, 2);
      expect(preview.skippedCount, 1);
      expect(preview.failedCount, 1);
      expect(preview.totalCount, 4);
    });

    test('skippedCount only counts skipped rows', () {
      final preview = CsvWishlistImportPreview(
        validRows: [_row(0)],
        skippedRows: [
          const SkippedRow(rowIndex: 1, reason: 'Duplicate release ID in file'),
          const SkippedRow(rowIndex: 2, reason: 'Duplicate release ID in file'),
        ],
        failedRows: [],
      );
      expect(preview.skippedCount, 2);
    });
  });
}

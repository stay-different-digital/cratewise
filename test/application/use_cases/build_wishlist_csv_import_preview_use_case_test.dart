import 'package:cratewise/application/use_cases/build_wishlist_csv_import_preview_use_case.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kValidCsv =
    '''Artist,Title,Label,Catalog Number,Format,Country,Year,Discogs Release ID,Target Price,Priority,Notes,Created Date,Updated Date
Herbie Hancock,Head Hunters,Columbia,KC 32731,LP,US,1973,99999,25.00,High,Original pressing,2024-01-15T10:00:00.000000Z,2024-06-01T12:30:00.000000Z''';

const _kValidCsvTwoRows = '''Artist,Title,Discogs Release ID,Priority
Herbie Hancock,Head Hunters,99999,High
John Coltrane,A Love Supreme,11111,Must have''';

const _kDuplicateCsv = '''Artist,Title,Discogs Release ID,Priority
Herbie Hancock,Head Hunters,99999,High
Herbie Hancock,Head Hunters,99999,High''';

const _kMissingColumnCsv = '''Artist,Title
Herbie Hancock,Head Hunters''';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const useCase = BuildWishlistCsvImportPreviewUseCase();

  group('BuildWishlistCsvImportPreviewUseCase.execute', () {
    group('valid CSV', () {
      test('returns ready result with correct filename', () {
        final result = useCase.execute(
          filename: 'wishlist.csv',
          content: _kValidCsv,
        );
        expect(result, isA<WishlistCsvImportPreviewReady>());
        final ready = result as WishlistCsvImportPreviewReady;
        expect(ready.filename, 'wishlist.csv');
      });

      test('one valid row → validCount 1', () {
        final result = useCase.execute(
          filename: 'wishlist.csv',
          content: _kValidCsv,
        );
        final ready = result as WishlistCsvImportPreviewReady;
        expect(ready.preview.validCount, 1);
        expect(ready.preview.skippedCount, 0);
        expect(ready.preview.failedCount, 0);
      });

      test('two distinct rows → both valid', () {
        final result = useCase.execute(
          filename: 'wishlist.csv',
          content: _kValidCsvTwoRows,
        );
        final ready = result as WishlistCsvImportPreviewReady;
        expect(ready.preview.validCount, 2);
      });

      test('valid row fields are parsed correctly', () {
        final result = useCase.execute(
          filename: 'wishlist.csv',
          content: _kValidCsv,
        );
        final ready = result as WishlistCsvImportPreviewReady;
        final row = ready.preview.validRows.first;
        expect(row.artist, 'Herbie Hancock');
        expect(row.title, 'Head Hunters');
        expect(row.discogsReleaseId, 99999);
        expect(row.priority, WishlistPriority.high);
        expect(row.targetPrice, closeTo(25.0, 0.001));
      });
    });

    group('duplicate rows', () {
      test('duplicate release ID → first valid, second skipped', () {
        final result = useCase.execute(
          filename: 'wishlist.csv',
          content: _kDuplicateCsv,
        );
        final ready = result as WishlistCsvImportPreviewReady;
        expect(ready.preview.validCount, 1);
        expect(ready.preview.skippedCount, 1);
        expect(ready.preview.failedCount, 0);
      });
    });

    group('missing required columns', () {
      test('missing required columns → all rows failed', () {
        final result = useCase.execute(
          filename: 'wishlist.csv',
          content: _kMissingColumnCsv,
        );
        final ready = result as WishlistCsvImportPreviewReady;
        expect(ready.preview.failedCount, 1);
        expect(ready.preview.validCount, 0);
      });
    });

    group('empty CSV', () {
      test('empty content → ready with zero rows', () {
        final result = useCase.execute(filename: 'empty.csv', content: '');
        final ready = result as WishlistCsvImportPreviewReady;
        expect(ready.preview.totalCount, 0);
      });
    });
  });
}

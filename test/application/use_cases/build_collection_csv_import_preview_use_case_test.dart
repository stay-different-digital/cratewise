import 'package:cratewise/application/use_cases/build_collection_csv_import_preview_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kValidCsv = '''Artist,Title,Label,Catalog Number,Format,Country,Year,Discogs Release ID,Media Condition,Sleeve Condition,Notes,Tags,Storage Location,Created Date,Updated Date
Miles Davis,Kind of Blue,Columbia,CL 1355,LP,US,1959,12345,Near Mint (NM or M-),Very Good Plus (VG+),First pressing,jazz|classic,Shelf A,2024-01-15T10:00:00.000000Z,2024-06-01T12:30:00.000000Z''';

const _kValidCsvTwoRows = '''Artist,Title,Label,Catalog Number,Format,Country,Year,Discogs Release ID,Media Condition,Sleeve Condition,Notes,Tags,Storage Location,Created Date,Updated Date
Miles Davis,Kind of Blue,Columbia,CL 1355,LP,US,1959,12345,Near Mint (NM or M-),Very Good Plus (VG+),,,,
John Coltrane,A Love Supreme,Impulse!,A-77,LP,US,1965,99999,Very Good Plus (VG+),Very Good Plus (VG+),,,,''';

const _kDuplicateCsv = '''Artist,Title,Discogs Release ID,Media Condition,Sleeve Condition
Miles Davis,Kind of Blue,12345,Near Mint (NM or M-),Very Good Plus (VG+)
Miles Davis,Kind of Blue,12345,Near Mint (NM or M-),Very Good Plus (VG+)''';

const _kMissingColumnCsv = '''Artist,Title
Miles Davis,Kind of Blue''';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const useCase = BuildCollectionCsvImportPreviewUseCase();

  group('BuildCollectionCsvImportPreviewUseCase.execute', () {
    group('valid CSV', () {
      test('returns ready result with correct filename', () {
        final result = useCase.execute(
          filename: 'collection.csv',
          content: _kValidCsv,
        );
        expect(result, isA<CollectionCsvImportPreviewReady>());
        final ready = result as CollectionCsvImportPreviewReady;
        expect(ready.filename, 'collection.csv');
      });

      test('one valid row → validCount 1', () {
        final result = useCase.execute(
          filename: 'collection.csv',
          content: _kValidCsv,
        );
        final ready = result as CollectionCsvImportPreviewReady;
        expect(ready.preview.validCount, 1);
        expect(ready.preview.skippedCount, 0);
        expect(ready.preview.failedCount, 0);
      });

      test('two distinct rows → both valid', () {
        final result = useCase.execute(
          filename: 'collection.csv',
          content: _kValidCsvTwoRows,
        );
        final ready = result as CollectionCsvImportPreviewReady;
        expect(ready.preview.validCount, 2);
      });

      test('valid row fields are parsed correctly', () {
        final result = useCase.execute(
          filename: 'collection.csv',
          content: _kValidCsv,
        );
        final ready = result as CollectionCsvImportPreviewReady;
        final row = ready.preview.validRows.first;
        expect(row.artist, 'Miles Davis');
        expect(row.title, 'Kind of Blue');
        expect(row.discogsReleaseId, 12345);
        expect(row.mediaCondition, RecordCondition.nearMint);
        expect(row.sleeveCondition, RecordCondition.veryGoodPlus);
      });
    });

    group('duplicate rows', () {
      test('duplicate release ID → first valid, second skipped', () {
        final result = useCase.execute(
          filename: 'collection.csv',
          content: _kDuplicateCsv,
        );
        final ready = result as CollectionCsvImportPreviewReady;
        expect(ready.preview.validCount, 1);
        expect(ready.preview.skippedCount, 1);
        expect(ready.preview.failedCount, 0);
      });
    });

    group('missing required columns', () {
      test('missing required columns → all rows failed', () {
        final result = useCase.execute(
          filename: 'collection.csv',
          content: _kMissingColumnCsv,
        );
        final ready = result as CollectionCsvImportPreviewReady;
        expect(ready.preview.failedCount, 1);
        expect(ready.preview.validCount, 0);
      });
    });

    group('empty CSV', () {
      test('empty content → ready with zero rows', () {
        final result = useCase.execute(
          filename: 'empty.csv',
          content: '',
        );
        final ready = result as CollectionCsvImportPreviewReady;
        expect(ready.preview.totalCount, 0);
      });

      test('header-only CSV → ready with zero rows', () {
        const headerOnly =
            'Artist,Title,Discogs Release ID,Media Condition,Sleeve Condition';
        final result = useCase.execute(
          filename: 'headers.csv',
          content: headerOnly,
        );
        final ready = result as CollectionCsvImportPreviewReady;
        expect(ready.preview.totalCount, 0);
      });
    });
  });
}

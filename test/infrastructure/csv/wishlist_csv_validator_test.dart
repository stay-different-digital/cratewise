import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/infrastructure/csv/csv_parser.dart';
import 'package:cratewise/infrastructure/csv/wishlist_csv_validator.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kHeaders = [
  'Artist',
  'Title',
  'Label',
  'Catalog Number',
  'Format',
  'Country',
  'Year',
  'Discogs Release ID',
  'Target Price',
  'Priority',
  'Notes',
  'Created Date',
  'Updated Date',
];

// A fully valid data row matching _kHeaders.
const _kValidRow = [
  'Herbie Hancock', // Artist
  'Head Hunters', // Title
  'Columbia', // Label
  'KC 32731', // Catalog Number
  'LP', // Format
  'US', // Country
  '1973', // Year
  '99999', // Discogs Release ID
  '25.00', // Target Price
  'High', // Priority
  'Original pressing', // Notes
  '2024-01-15T10:00:00.000000Z', // Created Date
  '2024-06-01T12:30:00.000000Z', // Updated Date
];

CsvParseSuccess _success(List<List<String>> rows) =>
    CsvParseSuccess(headers: _kHeaders, rows: rows);

CsvParseSuccess _successFrom(List<String> headers, List<List<String>> rows) =>
    CsvParseSuccess(headers: headers, rows: rows);

List<String> _rowWith(int index, String value) {
  final row = List<String>.from(_kValidRow);
  row[index] = value;
  return row;
}

int _indexOf(String header) => _kHeaders.indexOf(header);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const validator = WishlistCsvValidator();

  group('WishlistCsvValidator.validate', () {
    group('empty input', () {
      test('no rows returns empty preview', () {
        final preview = validator.validate(_success([]));
        expect(preview.validCount, 0);
        expect(preview.skippedCount, 0);
        expect(preview.failedCount, 0);
      });
    });

    group('missing required columns', () {
      test('missing Artist column → all rows failed', () {
        final headers = List<String>.from(_kHeaders)..remove('Artist');
        final rows = [List<String>.from(_kValidRow)..removeAt(0)];
        final preview = validator.validate(_successFrom(headers, rows));
        expect(preview.failedCount, 1);
        expect(preview.validCount, 0);
      });

      test('missing Title column → all rows failed', () {
        final headers = List<String>.from(_kHeaders)..remove('Title');
        final rows = [List<String>.from(_kValidRow)..removeAt(1)];
        final preview = validator.validate(_successFrom(headers, rows));
        expect(preview.failedCount, 1);
      });

      test('missing Discogs Release ID → all rows failed', () {
        final headers = List<String>.from(_kHeaders)
          ..remove('Discogs Release ID');
        final rows = [
          List<String>.from(_kValidRow)
            ..removeAt(_indexOf('Discogs Release ID')),
        ];
        final preview = validator.validate(_successFrom(headers, rows));
        expect(preview.failedCount, 1);
      });

      test('missing Priority → all rows failed', () {
        final headers = List<String>.from(_kHeaders)..remove('Priority');
        final rows = [
          List<String>.from(_kValidRow)..removeAt(_indexOf('Priority')),
        ];
        final preview = validator.validate(_successFrom(headers, rows));
        expect(preview.failedCount, 1);
      });

      test('no data rows with missing column → empty preview', () {
        final headers = List<String>.from(_kHeaders)..remove('Artist');
        final preview = validator.validate(_successFrom(headers, []));
        expect(preview.totalCount, 0);
      });
    });

    group('artist validation', () {
      test('empty artist → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Artist'), '')]),
        );
        expect(preview.failedCount, 1);
        expect(preview.failedRows.first.safeErrorMessage, contains('artist'));
      });

      test('artist over 500 chars → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Artist'), 'A' * 501)]),
        );
        expect(preview.failedCount, 1);
      });
    });

    group('title validation', () {
      test('empty title → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Title'), '')]),
        );
        expect(preview.failedCount, 1);
        expect(preview.failedRows.first.safeErrorMessage, contains('title'));
      });

      test('title over 500 chars → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Title'), 'T' * 501)]),
        );
        expect(preview.failedCount, 1);
      });
    });

    group('Discogs Release ID validation', () {
      test('empty release ID → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Discogs Release ID'), '')]),
        );
        expect(preview.failedCount, 1);
      });

      test('zero release ID → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Discogs Release ID'), '0')]),
        );
        expect(preview.failedCount, 1);
      });

      test('negative release ID → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Discogs Release ID'), '-5')]),
        );
        expect(preview.failedCount, 1);
      });

      test('non-numeric release ID → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Discogs Release ID'), 'abc')]),
        );
        expect(preview.failedCount, 1);
      });
    });

    group('priority validation', () {
      test('valid priority label → stored correctly', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Priority'), 'Must have')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.priority, WishlistPriority.mustHave);
      });

      test('empty priority → defaults to medium', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Priority'), '')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.priority, WishlistPriority.medium);
      });

      test('invalid priority → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Priority'), 'Urgent')]),
        );
        expect(preview.failedCount, 1);
      });

      test('all standard priority labels are accepted', () {
        for (final priority in WishlistPriority.values) {
          final preview = validator.validate(
            _success([_rowWith(_indexOf('Priority'), priority.label)]),
          );
          expect(
            preview.validCount,
            1,
            reason: 'Expected ${priority.label} to be valid',
          );
        }
      });
    });

    group('target price validation', () {
      test('empty target price → valid with null price', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Target Price'), '')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.targetPrice, isNull);
      });

      test('valid decimal price → stored correctly', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Target Price'), '12.99')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.targetPrice, closeTo(12.99, 0.001));
      });

      test('zero target price → valid', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Target Price'), '0')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.targetPrice, 0.0);
      });

      test('negative target price → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Target Price'), '-5.00')]),
        );
        expect(preview.failedCount, 1);
      });

      test('non-numeric target price → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Target Price'), 'cheap')]),
        );
        expect(preview.failedCount, 1);
      });
    });

    group('year validation', () {
      test('empty year → valid with null year', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.year, isNull);
      });

      test('valid year → stored correctly', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '1970')]),
        );
        expect(preview.validRows.first.year, 1970);
      });

      test('year before 1900 → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '1800')]),
        );
        expect(preview.failedCount, 1);
      });

      test('year after 2100 → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '2200')]),
        );
        expect(preview.failedCount, 1);
      });

      test('non-numeric year → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), 'MCMLXX')]),
        );
        expect(preview.failedCount, 1);
      });
    });

    group('text length validation', () {
      test('notes over 500 chars → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Notes'), 'N' * 501)]),
        );
        expect(preview.failedCount, 1);
      });

      test('label at exactly 500 chars → valid', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Label'), 'L' * 500)]),
        );
        expect(preview.validCount, 1);
      });
    });

    group('duplicate detection', () {
      test('two rows with same release ID → first valid, second skipped', () {
        final row = List<String>.from(_kValidRow);
        final preview = validator.validate(_success([row, row]));
        expect(preview.validCount, 1);
        expect(preview.skippedCount, 1);
      });

      test('skipped row has correct rowIndex', () {
        final row = List<String>.from(_kValidRow);
        final preview = validator.validate(_success([row, row]));
        expect(preview.skippedRows.first.rowIndex, 1);
      });

      test('different release IDs → both valid', () {
        final row1 = List<String>.from(_kValidRow);
        final row2 = _rowWith(_indexOf('Discogs Release ID'), '111');
        final preview = validator.validate(_success([row1, row2]));
        expect(preview.validCount, 2);
        expect(preview.skippedCount, 0);
      });
    });

    group('valid row field mapping', () {
      test('artist is stored correctly', () {
        final preview = validator.validate(_success([_kValidRow]));
        expect(preview.validRows.first.artist, 'Herbie Hancock');
      });

      test('title is stored correctly', () {
        final preview = validator.validate(_success([_kValidRow]));
        expect(preview.validRows.first.title, 'Head Hunters');
      });

      test('discogsReleaseId is stored correctly', () {
        final preview = validator.validate(_success([_kValidRow]));
        expect(preview.validRows.first.discogsReleaseId, 99999);
      });

      test('rowIndex is stored correctly', () {
        final row1 = List<String>.from(_kValidRow);
        final row2 = _rowWith(_indexOf('Discogs Release ID'), '111');
        final preview = validator.validate(_success([row1, row2]));
        expect(preview.validRows[0].rowIndex, 0);
        expect(preview.validRows[1].rowIndex, 1);
      });

      test('empty optional fields map to null', () {
        final row = _rowWith(_indexOf('Label'), '');
        final preview = validator.validate(_success([row]));
        expect(preview.validRows.first.label, isNull);
      });
    });
  });
}

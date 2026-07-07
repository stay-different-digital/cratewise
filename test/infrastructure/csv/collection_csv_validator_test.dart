import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/infrastructure/csv/collection_csv_validator.dart';
import 'package:cratewise/infrastructure/csv/csv_parser.dart';
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
  'Media Condition',
  'Sleeve Condition',
  'Notes',
  'Tags',
  'Storage Location',
  'Created Date',
  'Updated Date',
];

// A fully valid data row matching _kHeaders.
const _kValidRow = [
  'Miles Davis', // Artist
  'Kind of Blue', // Title
  'Columbia', // Label
  'CL 1355', // Catalog Number
  'LP', // Format
  'US', // Country
  '1959', // Year
  '12345', // Discogs Release ID
  'Near Mint (NM or M-)', // Media Condition
  'Very Good Plus (VG+)', // Sleeve Condition
  'First pressing', // Notes
  'jazz|classic', // Tags
  'Shelf A', // Storage Location
  '2024-01-15T10:00:00.000000Z', // Created Date
  '2024-06-01T12:30:00.000000Z', // Updated Date
];

CsvParseSuccess _success(List<List<String>> rows) =>
    CsvParseSuccess(headers: _kHeaders, rows: rows);

CsvParseSuccess _successFrom(List<String> headers, List<List<String>> rows) =>
    CsvParseSuccess(headers: headers, rows: rows);

/// Returns a copy of [_kValidRow] with cell at [index] replaced by [value].
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
  const validator = CollectionCsvValidator();

  group('CollectionCsvValidator.validate', () {
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
        final success = _successFrom(headers, [
          List<String>.from(_kValidRow)..removeAt(0),
        ]);
        final preview = validator.validate(success);
        expect(preview.failedCount, 1);
        expect(preview.validCount, 0);
      });

      test('missing Title column → all rows failed', () {
        final headers = List<String>.from(_kHeaders)..remove('Title');
        final success = _successFrom(headers, [
          List<String>.from(_kValidRow)..removeAt(1),
        ]);
        final preview = validator.validate(success);
        expect(preview.failedCount, 1);
        expect(preview.validCount, 0);
      });

      test('missing Discogs Release ID → all rows failed', () {
        final headers = List<String>.from(_kHeaders)
          ..remove('Discogs Release ID');
        final rows = [
          List<String>.from(_kValidRow)
            ..removeAt(_indexOf('Discogs Release ID')),
        ];
        final success = _successFrom(headers, rows);
        final preview = validator.validate(success);
        expect(preview.failedCount, 1);
        expect(preview.validCount, 0);
      });

      test('missing Media Condition → all rows failed', () {
        final headers = List<String>.from(_kHeaders)..remove('Media Condition');
        final rows = [
          List<String>.from(_kValidRow)..removeAt(_indexOf('Media Condition')),
        ];
        final success = _successFrom(headers, rows);
        final preview = validator.validate(success);
        expect(preview.failedCount, 1);
      });

      test('missing Sleeve Condition → all rows failed', () {
        final headers = List<String>.from(_kHeaders)
          ..remove('Sleeve Condition');
        final rows = [
          List<String>.from(_kValidRow)..removeAt(_indexOf('Sleeve Condition')),
        ];
        final success = _successFrom(headers, rows);
        final preview = validator.validate(success);
        expect(preview.failedCount, 1);
      });

      test(
        'missing multiple required columns → failure message lists them',
        () {
          final headers = List<String>.from(_kHeaders)
            ..remove('Artist')
            ..remove('Title');
          final success = _successFrom(headers, [
            ['', '', '', ''],
          ]);
          final preview = validator.validate(success);
          expect(preview.failedRows.first.safeErrorMessage, contains('Artist'));
        },
      );

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

      test('artist at exactly 500 chars → valid', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Artist'), 'A' * 500)]),
        );
        expect(preview.validCount, 1);
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
        expect(
          preview.failedRows.first.safeErrorMessage,
          contains('Discogs Release ID'),
        );
      });

      test('zero release ID → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Discogs Release ID'), '0')]),
        );
        expect(preview.failedCount, 1);
      });

      test('negative release ID → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Discogs Release ID'), '-1')]),
        );
        expect(preview.failedCount, 1);
      });

      test('non-numeric release ID → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Discogs Release ID'), 'abc')]),
        );
        expect(preview.failedCount, 1);
      });

      test('positive integer release ID → valid', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Discogs Release ID'), '99999999')]),
        );
        expect(preview.validCount, 1);
      });
    });

    group('media condition validation', () {
      test('valid condition label → valid', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Media Condition'), 'Mint (M)')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.mediaCondition, RecordCondition.mint);
      });

      test('empty condition → maps to notSet', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Media Condition'), '')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.mediaCondition, RecordCondition.notSet);
      });

      test('invalid condition label → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Media Condition'), 'Excellent')]),
        );
        expect(preview.failedCount, 1);
      });

      test('all standard condition labels are accepted', () {
        for (final condition in RecordCondition.values) {
          final preview = validator.validate(
            _success([_rowWith(_indexOf('Media Condition'), condition.label)]),
          );
          expect(
            preview.validCount,
            1,
            reason: 'Expected ${condition.label} to be valid',
          );
        }
      });
    });

    group('sleeve condition validation', () {
      test('empty sleeve condition → maps to notSet', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Sleeve Condition'), '')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.sleeveCondition, RecordCondition.notSet);
      });

      test('invalid sleeve condition → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Sleeve Condition'), 'Unknown')]),
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

      test('valid year within range → stored correctly', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '1969')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.year, 1969);
      });

      test('year 1900 → valid', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '1900')]),
        );
        expect(preview.validCount, 1);
      });

      test('year 2100 → valid', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '2100')]),
        );
        expect(preview.validCount, 1);
      });

      test('year before 1900 → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '1899')]),
        );
        expect(preview.failedCount, 1);
      });

      test('year after 2100 → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), '2101')]),
        );
        expect(preview.failedCount, 1);
      });

      test('non-numeric year → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Year'), 'unknown')]),
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

      test('storage location over 500 chars → failed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Storage Location'), 'S' * 501)]),
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

    group('tags validation', () {
      test('tags split by pipe → stored as list', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Tags'), 'jazz|funk|soul')]),
        );
        expect(preview.validCount, 1);
        expect(preview.validRows.first.tags, ['jazz', 'funk', 'soul']);
      });

      test('empty tags → empty list', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Tags'), '')]),
        );
        expect(preview.validRows.first.tags, isEmpty);
      });

      test('tag over 100 chars → failed', () {
        final longTag = 'T' * 101;
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Tags'), longTag)]),
        );
        expect(preview.failedCount, 1);
      });

      test('tag at exactly 100 chars → valid', () {
        final tag = 'T' * 100;
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Tags'), tag)]),
        );
        expect(preview.validCount, 1);
      });

      test('tags with whitespace around pipe → trimmed', () {
        final preview = validator.validate(
          _success([_rowWith(_indexOf('Tags'), 'jazz | funk | soul')]),
        );
        expect(preview.validRows.first.tags, ['jazz', 'funk', 'soul']);
      });
    });

    group('duplicate detection', () {
      test('two rows with same release ID → first valid, second skipped', () {
        final row = List<String>.from(_kValidRow);
        final preview = validator.validate(_success([row, row]));
        expect(preview.validCount, 1);
        expect(preview.skippedCount, 1);
        expect(preview.failedCount, 0);
      });

      test('three rows with same release ID → first valid, rest skipped', () {
        final row = List<String>.from(_kValidRow);
        final preview = validator.validate(_success([row, row, row]));
        expect(preview.validCount, 1);
        expect(preview.skippedCount, 2);
      });

      test('skipped row has correct rowIndex', () {
        final row = List<String>.from(_kValidRow);
        final preview = validator.validate(_success([row, row]));
        expect(preview.skippedRows.first.rowIndex, 1);
      });

      test('different release IDs → both valid', () {
        final row1 = List<String>.from(_kValidRow);
        final row2 = _rowWith(_indexOf('Discogs Release ID'), '99999');
        final preview = validator.validate(_success([row1, row2]));
        expect(preview.validCount, 2);
        expect(preview.skippedCount, 0);
      });
    });

    group('valid row field mapping', () {
      test('artist is stored correctly', () {
        final preview = validator.validate(_success([_kValidRow]));
        expect(preview.validRows.first.artist, 'Miles Davis');
      });

      test('title is stored correctly', () {
        final preview = validator.validate(_success([_kValidRow]));
        expect(preview.validRows.first.title, 'Kind of Blue');
      });

      test('discogsReleaseId is stored correctly', () {
        final preview = validator.validate(_success([_kValidRow]));
        expect(preview.validRows.first.discogsReleaseId, 12345);
      });

      test('label is stored correctly', () {
        final preview = validator.validate(_success([_kValidRow]));
        expect(preview.validRows.first.label, 'Columbia');
      });

      test('rowIndex is stored correctly', () {
        final row1 = List<String>.from(_kValidRow);
        final row2 = _rowWith(_indexOf('Discogs Release ID'), '99999');
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

  group('DJ field validation (US-121)', () {
    const djHeaders = [
      'Artist',
      'Title',
      'Discogs Release ID',
      'Media Condition',
      'Sleeve Condition',
      'BPM',
      'Musical Key',
      'Energy',
      'Gig Crates',
    ];
    const djBase = [
      'DJ Artist',
      'DJ Track',
      '55555',
      'Near Mint (NM or M-)',
      'Very Good Plus (VG+)',
      '',
      '',
      '',
      '',
    ];

    CsvParseSuccess dj(List<String> row) =>
        CsvParseSuccess(headers: djHeaders, rows: [row]);

    test('valid BPM is parsed', () {
      final row = List<String>.from(djBase)..[5] = '128';
      final preview = validator.validate(dj(row));
      expect(preview.validRows.first.bpm, 128);
    });

    test('BPM below 20 fails', () {
      final row = List<String>.from(djBase)..[5] = '19';
      final preview = validator.validate(dj(row));
      expect(preview.failedRows, hasLength(1));
    });

    test('BPM above 300 fails', () {
      final row = List<String>.from(djBase)..[5] = '301';
      final preview = validator.validate(dj(row));
      expect(preview.failedRows, hasLength(1));
    });

    test('non-numeric BPM fails', () {
      final row = List<String>.from(djBase)..[5] = 'fast';
      final preview = validator.validate(dj(row));
      expect(preview.failedRows, hasLength(1));
    });

    test('empty BPM maps to null', () {
      final preview = validator.validate(dj(List<String>.from(djBase)));
      expect(preview.validRows.first.bpm, isNull);
    });

    test('valid musical key is parsed', () {
      final row = List<String>.from(djBase)..[6] = 'A major';
      final preview = validator.validate(dj(row));
      expect(preview.validRows.first.musicalKey, MusicalKey.aMajor);
    });

    test('invalid musical key fails', () {
      final row = List<String>.from(djBase)..[6] = 'X# diminished';
      final preview = validator.validate(dj(row));
      expect(preview.failedRows, hasLength(1));
    });

    test('musical key accepts ASCII flat spelling', () {
      final row = List<String>.from(djBase)..[6] = 'Ab major';
      final preview = validator.validate(dj(row));
      expect(preview.validRows.first.musicalKey, MusicalKey.abMajor);
    });

    test('musical key is case-insensitive', () {
      final row = List<String>.from(djBase)..[6] = 'a MINOR';
      final preview = validator.validate(dj(row));
      expect(preview.validRows.first.musicalKey, MusicalKey.aMinor);
    });

    test('musical key accepts the enum name', () {
      final row = List<String>.from(djBase)..[6] = 'bbMinor';
      final preview = validator.validate(dj(row));
      expect(preview.validRows.first.musicalKey, MusicalKey.bbMinor);
    });

    test('empty musical key maps to null', () {
      final preview = validator.validate(dj(List<String>.from(djBase)));
      expect(preview.validRows.first.musicalKey, isNull);
    });

    test('valid energy level is parsed', () {
      final row = List<String>.from(djBase)..[7] = '3';
      final preview = validator.validate(dj(row));
      expect(preview.validRows.first.energyLevel, 3);
    });

    test('energy below 1 fails', () {
      final row = List<String>.from(djBase)..[7] = '0';
      final preview = validator.validate(dj(row));
      expect(preview.failedRows, hasLength(1));
    });

    test('energy above 5 fails', () {
      final row = List<String>.from(djBase)..[7] = '6';
      final preview = validator.validate(dj(row));
      expect(preview.failedRows, hasLength(1));
    });

    test('empty energy maps to null', () {
      final preview = validator.validate(dj(List<String>.from(djBase)));
      expect(preview.validRows.first.energyLevel, isNull);
    });

    test('pipe-separated gig crates are parsed', () {
      final row = List<String>.from(djBase)..[8] = 'Summer Set|Techno Night';
      final preview = validator.validate(dj(row));
      expect(preview.validRows.first.gigCrates, ['Summer Set', 'Techno Night']);
    });

    test('empty gig crates maps to empty list', () {
      final preview = validator.validate(dj(List<String>.from(djBase)));
      expect(preview.validRows.first.gigCrates, isEmpty);
    });

    test(
      'DJ columns are optional — missing columns are ignored gracefully',
      () {
        final preview = validator.validate(_success([_kValidRow]));
        expect(preview.validRows.first.bpm, isNull);
        expect(preview.validRows.first.musicalKey, isNull);
        expect(preview.validRows.first.energyLevel, isNull);
        expect(preview.validRows.first.gigCrates, isEmpty);
      },
    );
  });
}

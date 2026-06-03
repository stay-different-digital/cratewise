import 'package:cratewise/infrastructure/csv/csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = CsvParser();

  group('CsvParser.parse', () {
    group('empty input', () {
      test('empty string returns success with no headers or rows', () {
        final result = parser.parse('');
        expect(result, isA<CsvParseSuccess>());
        final s = result as CsvParseSuccess;
        expect(s.headers, isEmpty);
        expect(s.rows, isEmpty);
      });

      test(
        'whitespace-only string returns success with no headers or rows',
        () {
          final result = parser.parse('   \n  \t  ');
          expect(result, isA<CsvParseSuccess>());
          final s = result as CsvParseSuccess;
          expect(s.headers, isEmpty);
          expect(s.rows, isEmpty);
        },
      );
    });

    group('header-only input', () {
      test('one line returns headers and empty rows', () {
        final result = parser.parse('Artist,Title,Year');
        expect(result, isA<CsvParseSuccess>());
        final s = result as CsvParseSuccess;
        expect(s.headers, ['Artist', 'Title', 'Year']);
        expect(s.rows, isEmpty);
      });

      test('header cells are trimmed', () {
        final result = parser.parse(' Artist , Title , Year ');
        final s = result as CsvParseSuccess;
        expect(s.headers, ['Artist', 'Title', 'Year']);
      });
    });

    group('data rows', () {
      test('single data row is returned correctly', () {
        final result = parser.parse('Artist,Title\nMiles Davis,Kind of Blue');
        final s = result as CsvParseSuccess;
        expect(s.rows.length, 1);
        expect(s.rows.first, ['Miles Davis', 'Kind of Blue']);
      });

      test('multiple data rows are all returned', () {
        final csv = 'Artist,Title\nA,B\nC,D\nE,F';
        final result = parser.parse(csv);
        final s = result as CsvParseSuccess;
        expect(s.rows.length, 3);
      });

      test('data cells are trimmed', () {
        final result = parser.parse(
          'Artist,Title\n Miles Davis , Kind of Blue ',
        );
        final s = result as CsvParseSuccess;
        expect(s.rows.first, ['Miles Davis', 'Kind of Blue']);
      });

      test('empty cell is preserved as empty string', () {
        final result = parser.parse(
          'Artist,Title,Year\nMiles Davis,Kind of Blue,',
        );
        final s = result as CsvParseSuccess;
        expect(s.rows.first[2], '');
      });

      test('header row is not included in rows', () {
        final result = parser.parse('Artist,Title\nMiles Davis,Kind of Blue');
        final s = result as CsvParseSuccess;
        expect(s.rows.first, isNot(contains('Artist')));
      });
    });

    group('line endings', () {
      test('CRLF line endings are normalised to LF', () {
        final csv =
            'Artist,Title\r\nMiles Davis,Kind of Blue\r\nHerbie Hancock,Head Hunters';
        final result = parser.parse(csv);
        final s = result as CsvParseSuccess;
        expect(s.rows.length, 2);
      });

      test('CR-only line endings are normalised to LF', () {
        final csv = 'Artist,Title\rMiles Davis,Kind of Blue';
        final result = parser.parse(csv);
        final s = result as CsvParseSuccess;
        expect(s.rows.length, 1);
      });
    });

    group('quoted fields', () {
      test('cell containing comma is handled correctly', () {
        final csv = 'Artist,Title\n"Davis, Miles",Kind of Blue';
        final result = parser.parse(csv);
        final s = result as CsvParseSuccess;
        expect(s.rows.first[0], 'Davis, Miles');
      });

      test('cell containing newline is handled correctly', () {
        final csv = '"Artist","Title"\n"Miles Davis","Kind of Blue"';
        final result = parser.parse(csv);
        final s = result as CsvParseSuccess;
        expect(s.rows.length, 1);
        expect(s.rows.first[0], 'Miles Davis');
      });
    });

    group('column count consistency', () {
      test('data row has same length as headers', () {
        final csv = 'A,B,C\n1,2,3';
        final result = parser.parse(csv);
        final s = result as CsvParseSuccess;
        expect(s.rows.first.length, s.headers.length);
      });

      test('header count matches declared columns', () {
        final csv = 'X,Y,Z,W\n1,2,3,4';
        final result = parser.parse(csv);
        final s = result as CsvParseSuccess;
        expect(s.headers.length, 4);
      });
    });
  });
}

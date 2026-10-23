import 'package:cratewise/infrastructure/csv/csv_cell_escape.dart';
import 'package:cratewise/infrastructure/csv/csv_parser.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formula-like cells are prefixed with a quote', () {
    expect(
      escapeCsvCell('=HYPERLINK("http://x","y")'),
      '\'=HYPERLINK("http://x","y")',
    );
    for (final c in ['+1', '-ziq', '@SUM(A1)', "'quoted"]) {
      expect(escapeCsvCell(c), "'$c");
    }
    expect(escapeCsvCell('Kind of Blue'), 'Kind of Blue');
    expect(escapeCsvCell('128'), '128');
    expect(escapeCsvCell(''), '');
  });

  test('export → parse round-trips every value unchanged', () {
    const values = [
      '=1+1',
      '-ziq',
      "'quoted",
      "''double",
      'plain',
      "it's",
      '128',
    ];
    final csv = const ListToCsvConverter().convert([
      ['title'],
      for (final v in values) [escapeCsvCell(v)],
    ]);

    final parsed = const CsvParser().parse(csv) as CsvParseSuccess;

    expect(parsed.rows.map((r) => r.single).toList(), values);
  });
}

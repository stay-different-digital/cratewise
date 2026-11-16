// Pins the exact CSV output and parsing captured with package:csv 6.0.0
// (US-157), so a library upgrade can't silently change exports or imports.
// One accepted change with csv 8: a cell with leading/trailing spaces is now
// quoted (" spaced ") so spreadsheets keep the spaces; re-importing gives
// the same result because cells are trimmed.

import 'package:cratewise/infrastructure/csv/csv_file_writer.dart';
import 'package:cratewise/infrastructure/csv/csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

List<Object> _parse(String input) {
  final r = const CsvParser().parse(input);
  return r is CsvParseSuccess ? [r.headers, r.rows] : ['fail'];
}

void main() {
  const headers = ['artist', 'title', 'notes'];
  const rows = [
    ['Miles Davis', 'Kind Of Blue', 'plain'],
    ['Simon, Garfunkel', 'He said "hi"', 'line1\nline2'],
    ['=SUM(A1)', '+1', '-x'],
    ['@user', 'Björk – Début', '🎶 émoji'],
    ['', ' spaced ', '12'],
  ];

  test('export text is byte-for-byte unchanged', () {
    expect(
      encodeCsv(headers, rows),
      'artist,title,notes\r\n'
      'Miles Davis,Kind Of Blue,plain\r\n'
      '"Simon, Garfunkel","He said ""hi""","line1\nline2"\r\n'
      "'=SUM(A1),'+1,'-x\r\n"
      "'@user,Björk – Début,🎶 émoji\r\n"
      '," spaced ",12',
    );
  });

  test('an export reads back to the original cells (cells are trimmed)', () {
    expect(_parse(encodeCsv(headers, rows)), [
      headers,
      [
        ['Miles Davis', 'Kind Of Blue', 'plain'],
        ['Simon, Garfunkel', 'He said "hi"', 'line1\nline2'],
        ['=SUM(A1)', '+1', '-x'],
        ['@user', 'Björk – Début', '🎶 émoji'],
        ['', 'spaced', '12'],
      ],
    ]);
  });

  test('import parsing is unchanged', () {
    expect(_parse('a,b\r\n1,2\r\n'), [
      ['a', 'b'],
      [
        ['1', '2'],
      ],
    ]);
    // Only commas separate fields: a semicolon file is one column.
    expect(_parse('a;b\n1;2\n'), [
      ['a;b'],
      [
        ['1;2'],
      ],
    ]);
    expect(_parse('a,b\n"x, y","say ""hi"""\n'), [
      ['a', 'b'],
      [
        ['x, y', 'say "hi"'],
      ],
    ]);
    expect(_parse('﻿a,b\n1,\n'), [
      ['a', 'b'],
      [
        ['1', ''],
      ],
    ]);
    expect(_parse('a,b\n"multi\nline",z\n'), [
      ['a', 'b'],
      [
        ['multi\nline', 'z'],
      ],
    ]);
    // Numbers stay text: leading zeros and decimals are kept.
    expect(_parse('a,b\n007,1.50\n'), [
      ['a', 'b'],
      [
        ['007', '1.50'],
      ],
    ]);
  });
}

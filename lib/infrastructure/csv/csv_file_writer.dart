import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import 'csv_cell_escape.dart';

abstract class CsvFileWriter {
  Future<String> write({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  });
}

class TempCsvFileWriter implements CsvFileWriter {
  const TempCsvFileWriter();

  @override
  Future<String> write({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    const converter = ListToCsvConverter();
    final allRows = <List<dynamic>>[
      headers,
      for (final row in rows) row.map(escapeCsvCell).toList(),
    ];
    final csvString = converter.convert(allRows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString('﻿$csvString');
    return file.path;
  }
}

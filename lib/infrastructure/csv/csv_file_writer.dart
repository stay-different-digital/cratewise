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
    final csvString = encodeCsv(headers, rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString('﻿$csvString');
    return file.path;
  }
}

/// The CSV text of an export, before the BOM is added: headers as-is, data
/// cells escaped against spreadsheet formulas (US-127). Pure, so its exact
/// output is pinned by a golden test.
String encodeCsv(List<String> headers, List<List<String>> rows) {
  return Csv().encode(<List<dynamic>>[
    headers,
    for (final row in rows) row.map(escapeCsvCell).toList(),
  ]);
}


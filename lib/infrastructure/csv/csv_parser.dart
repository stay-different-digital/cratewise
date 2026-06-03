import 'package:csv/csv.dart';

sealed class CsvParseResult {
  const CsvParseResult();
}

/// Successfully parsed CSV with a header row and zero or more data rows.
///
/// All cells are trimmed. The header row is not included in [rows].
class CsvParseSuccess extends CsvParseResult {
  const CsvParseSuccess({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

/// The content could not be interpreted as CSV.
class CsvParseFailure extends CsvParseResult {
  const CsvParseFailure(this.reason);

  /// Safe, user-facing reason.
  final String reason;
}

/// Parses a raw CSV string into headers and data rows using the [csv] package.
///
/// Handles empty content, header-only files, Windows line endings, and quoted
/// fields. Returns [CsvParseFailure] only for catastrophic parse errors.
class CsvParser {
  const CsvParser();

  CsvParseResult parse(String content) {
    final normalised = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    if (normalised.isEmpty) {
      return const CsvParseSuccess(headers: [], rows: []);
    }

    try {
      const converter = CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      );
      final rawRows = converter.convert(normalised);

      if (rawRows.isEmpty) {
        return const CsvParseSuccess(headers: [], rows: []);
      }

      final headers = rawRows.first.map((c) => c.toString().trim()).toList();

      if (rawRows.length == 1) {
        return CsvParseSuccess(headers: headers, rows: const []);
      }

      final dataRows = rawRows
          .skip(1)
          .map((row) => row.map((c) => c.toString().trim()).toList())
          .toList();

      return CsvParseSuccess(headers: headers, rows: dataRows);
    } catch (_) {
      return const CsvParseFailure('The file could not be read as a CSV');
    }
  }
}

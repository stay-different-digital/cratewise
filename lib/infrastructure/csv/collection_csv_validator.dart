import '../../domain/models/collection_item.dart';
import '../../domain/models/csv_collection_import_preview.dart';
import '../../domain/models/import_export_row_result.dart';
import 'csv_parser.dart';

const _kMaxTextLength = 500;
const _kMaxTagLength = 100;
const _kMinYear = 1900;
const _kMaxYear = 2100;

const _kRequiredColumns = [
  'Artist',
  'Title',
  'Discogs Release ID',
  'Media Condition',
  'Sleeve Condition',
];

sealed class _RowOutcome {}

final class _ValidOutcome extends _RowOutcome {
  _ValidOutcome(this.row);
  final CsvCollectionImportRow row;
}

final class _SkippedOutcome extends _RowOutcome {
  _SkippedOutcome(this.row);
  final SkippedRow row;
}

final class _FailedOutcome extends _RowOutcome {
  _FailedOutcome(this.row);
  final FailedRow row;
}

/// Validates a parsed collection CSV and classifies each row as valid,
/// skipped (duplicate release ID within the file), or failed.
class CollectionCsvValidator {
  const CollectionCsvValidator();

  CsvCollectionImportPreview validate(CsvParseSuccess parsed) {
    final headerIndex = _buildIndex(parsed.headers);

    final missingColumns = _kRequiredColumns
        .where((col) => !headerIndex.containsKey(col))
        .toList();

    if (missingColumns.isNotEmpty) {
      final noun = missingColumns.length == 1 ? 'column' : 'columns';
      final reason = 'Missing required $noun: ${missingColumns.join(', ')}';
      final failedRows = List.generate(
        parsed.rows.length,
        (i) => FailedRow(rowIndex: i, safeErrorMessage: reason),
      );
      return CsvCollectionImportPreview(
        validRows: const [],
        skippedRows: const [],
        failedRows: failedRows,
      );
    }

    final validRows = <CsvCollectionImportRow>[];
    final skippedRows = <SkippedRow>[];
    final failedRows = <FailedRow>[];
    final seenReleaseIds = <int>{};

    for (var i = 0; i < parsed.rows.length; i++) {
      final outcome = _validateRow(
        parsed.rows[i],
        i,
        headerIndex,
        seenReleaseIds,
      );
      switch (outcome) {
        case final _ValidOutcome o:
          seenReleaseIds.add(o.row.discogsReleaseId);
          validRows.add(o.row);
        case final _SkippedOutcome o:
          skippedRows.add(o.row);
        case final _FailedOutcome o:
          failedRows.add(o.row);
      }
    }

    return CsvCollectionImportPreview(
      validRows: validRows,
      skippedRows: skippedRows,
      failedRows: failedRows,
    );
  }

  _RowOutcome _validateRow(
    List<String> row,
    int rowIndex,
    Map<String, int> headerIndex,
    Set<int> seenReleaseIds,
  ) {
    String cell(String header) {
      final idx = headerIndex[header];
      if (idx == null || idx >= row.length) return '';
      return row[idx];
    }

    String? optCell(String header) {
      final v = cell(header);
      return v.isEmpty ? null : v;
    }

    _FailedOutcome fail(String msg) =>
        _FailedOutcome(FailedRow(rowIndex: rowIndex, safeErrorMessage: msg));

    // --- Required: artist ---
    final artist = cell('Artist');
    if (artist.isEmpty) return fail('Missing artist');
    if (artist.length > _kMaxTextLength) return fail('Artist name too long');

    // --- Required: title ---
    final title = cell('Title');
    if (title.isEmpty) return fail('Missing title');
    if (title.length > _kMaxTextLength) return fail('Title too long');

    // --- Required: Discogs Release ID ---
    final releaseIdStr = cell('Discogs Release ID');
    if (releaseIdStr.isEmpty) return fail('Missing Discogs Release ID');
    final releaseId = int.tryParse(releaseIdStr);
    if (releaseId == null || releaseId < 1) {
      return fail('Invalid Discogs Release ID');
    }

    // --- Duplicate check (first occurrence wins) ---
    if (seenReleaseIds.contains(releaseId)) {
      return _SkippedOutcome(
        SkippedRow(rowIndex: rowIndex, reason: 'Duplicate release ID in file'),
      );
    }

    // --- Conditions ---
    final mediaCondStr = cell('Media Condition');
    final mediaCondition = _parseCondition(mediaCondStr);
    if (mediaCondition == null) {
      return fail('Invalid media condition: $mediaCondStr');
    }

    final sleeveCondStr = cell('Sleeve Condition');
    final sleeveCondition = _parseCondition(sleeveCondStr);
    if (sleeveCondition == null) {
      return fail('Invalid sleeve condition: $sleeveCondStr');
    }

    // --- Optional: year ---
    final yearStr = cell('Year');
    int? year;
    if (yearStr.isNotEmpty) {
      year = int.tryParse(yearStr);
      if (year == null || year < _kMinYear || year > _kMaxYear) {
        return fail('Invalid year: $yearStr');
      }
    }

    // --- Optional text fields ---
    final label = optCell('Label');
    final catno = optCell('Catalog Number');
    final format = optCell('Format');
    final country = optCell('Country');
    final notes = optCell('Notes');
    final storageLocation = optCell('Storage Location');

    for (final field in [
      label,
      catno,
      format,
      country,
      notes,
      storageLocation,
    ]) {
      if (field != null && field.length > _kMaxTextLength) {
        return fail(
          'A text field exceeds the maximum length of $_kMaxTextLength characters',
        );
      }
    }

    // --- Optional: tags ---
    final tagsStr = cell('Tags');
    final tags = tagsStr.isEmpty
        ? <String>[]
        : tagsStr
              .split('|')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
    for (final tag in tags) {
      if (tag.length > _kMaxTagLength) {
        return fail(
          'A tag exceeds the maximum length of $_kMaxTagLength characters',
        );
      }
    }

    return _ValidOutcome(
      CsvCollectionImportRow(
        rowIndex: rowIndex,
        artist: artist,
        title: title,
        discogsReleaseId: releaseId,
        mediaCondition: mediaCondition,
        sleeveCondition: sleeveCondition,
        tags: tags,
        label: label,
        catno: catno,
        format: format,
        country: country,
        year: year,
        notes: notes,
        storageLocation: storageLocation,
      ),
    );
  }

  Map<String, int> _buildIndex(List<String> headers) {
    final map = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      map[headers[i]] = i;
    }
    return map;
  }

  RecordCondition? _parseCondition(String value) {
    if (value.isEmpty) return RecordCondition.notSet;
    for (final c in RecordCondition.values) {
      if (c.label == value) return c;
    }
    return null;
  }
}

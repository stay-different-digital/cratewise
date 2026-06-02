import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportExportRowResult', () {
    group('ValidRow', () {
      test('stores rowIndex and description', () {
        const row = ValidRow(rowIndex: 0, description: 'Miles Davis – Kind Of Blue');
        expect(row.rowIndex, 0);
        expect(row.description, 'Miles Davis – Kind Of Blue');
      });

      test('is an ImportExportRowResult', () {
        const row = ValidRow(rowIndex: 1, description: 'Artist – Title');
        expect(row, isA<ImportExportRowResult>());
      });
    });

    group('SkippedRow', () {
      test('stores rowIndex and reason', () {
        const row = SkippedRow(rowIndex: 2, reason: 'Already in collection');
        expect(row.rowIndex, 2);
        expect(row.reason, 'Already in collection');
      });

      test('is an ImportExportRowResult', () {
        const row = SkippedRow(rowIndex: 3, reason: 'Duplicate');
        expect(row, isA<ImportExportRowResult>());
      });
    });

    group('FailedRow', () {
      test('stores rowIndex and safeErrorMessage', () {
        const row = FailedRow(
          rowIndex: 4,
          safeErrorMessage: 'Could not parse release ID.',
        );
        expect(row.rowIndex, 4);
        expect(row.safeErrorMessage, 'Could not parse release ID.');
      });

      test('is an ImportExportRowResult', () {
        const row = FailedRow(rowIndex: 5, safeErrorMessage: 'Parse error.');
        expect(row, isA<ImportExportRowResult>());
      });

      test('safeErrorMessage does not contain token or secret', () {
        const row = FailedRow(rowIndex: 6, safeErrorMessage: 'Network error.');
        expect(row.safeErrorMessage.toLowerCase(), isNot(contains('token')));
        expect(row.safeErrorMessage.toLowerCase(), isNot(contains('secret')));
      });
    });

    group('sealed class pattern matching', () {
      test('switch is exhaustive over all subtypes', () {
        final List<ImportExportRowResult> rows = [
          const ValidRow(rowIndex: 0, description: 'Artist – Title'),
          const SkippedRow(rowIndex: 1, reason: 'Duplicate'),
          const FailedRow(rowIndex: 2, safeErrorMessage: 'Error.'),
        ];

        for (final row in rows) {
          final label = switch (row) {
            ValidRow() => 'valid',
            SkippedRow() => 'skipped',
            FailedRow() => 'failed',
          };
          expect(label, isNotEmpty);
        }
      });

      test('rowIndex is accessible on the base type', () {
        final List<ImportExportRowResult> rows = [
          const ValidRow(rowIndex: 10, description: 'A'),
          const SkippedRow(rowIndex: 20, reason: 'B'),
          const FailedRow(rowIndex: 30, safeErrorMessage: 'C'),
        ];
        expect(rows.map((r) => r.rowIndex).toList(), [10, 20, 30]);
      });
    });
  });
}

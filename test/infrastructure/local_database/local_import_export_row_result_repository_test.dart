import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/local_import_export_row_result_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('LocalImportExportRowResultRepository', () {
    late AppDatabase db;
    late LocalImportExportRowResultRepository repo;

    setUp(() {
      db = openTestDb();
      repo = LocalImportExportRowResultRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('addResult and getResults', () {
      test('returns empty list for unknown job', () async {
        expect(await repo.getResults('no-job'), isEmpty);
      });

      test('stores and retrieves a ValidRow', () async {
        const row = ValidRow(rowIndex: 0, description: 'Miles Davis – Kind Of Blue');
        await repo.addResult('j-1', row);
        final results = await repo.getResults('j-1');
        expect(results, hasLength(1));
        expect(results.first, isA<ValidRow>());
        expect((results.first as ValidRow).description, 'Miles Davis – Kind Of Blue');
        expect(results.first.rowIndex, 0);
      });

      test('stores and retrieves a SkippedRow', () async {
        const row = SkippedRow(rowIndex: 1, reason: 'Already in collection');
        await repo.addResult('j-1', row);
        final results = await repo.getResults('j-1');
        expect(results, hasLength(1));
        expect(results.first, isA<SkippedRow>());
        expect((results.first as SkippedRow).reason, 'Already in collection');
        expect(results.first.rowIndex, 1);
      });

      test('stores and retrieves a FailedRow', () async {
        const row = FailedRow(rowIndex: 2, safeErrorMessage: 'Could not parse row.');
        await repo.addResult('j-1', row);
        final results = await repo.getResults('j-1');
        expect(results, hasLength(1));
        expect(results.first, isA<FailedRow>());
        expect(
          (results.first as FailedRow).safeErrorMessage,
          'Could not parse row.',
        );
        expect(results.first.rowIndex, 2);
      });

      test('results for one job do not appear under a different job', () async {
        await repo.addResult('j-1', const ValidRow(rowIndex: 0, description: 'A'));
        expect(await repo.getResults('j-2'), isEmpty);
      });

      test('orders results by rowIndex ascending', () async {
        await repo.addResult('j-1', const SkippedRow(rowIndex: 5, reason: 'Dup'));
        await repo.addResult('j-1', const ValidRow(rowIndex: 2, description: 'B'));
        await repo.addResult('j-1', const FailedRow(rowIndex: 0, safeErrorMessage: 'Err'));
        final results = await repo.getResults('j-1');
        expect(results.map((r) => r.rowIndex).toList(), [0, 2, 5]);
      });

      test('stores a mix of all three result types for the same job', () async {
        await repo.addResult('j-1', const ValidRow(rowIndex: 0, description: 'Valid'));
        await repo.addResult('j-1', const SkippedRow(rowIndex: 1, reason: 'Skipped'));
        await repo.addResult('j-1', const FailedRow(rowIndex: 2, safeErrorMessage: 'Failed'));
        final results = await repo.getResults('j-1');
        expect(results, hasLength(3));
        expect(results[0], isA<ValidRow>());
        expect(results[1], isA<SkippedRow>());
        expect(results[2], isA<FailedRow>());
      });

      test('multiple results for same rowIndex are all stored', () async {
        await repo.addResult('j-1', const ValidRow(rowIndex: 0, description: 'First'));
        await repo.addResult('j-1', const ValidRow(rowIndex: 0, description: 'Second'));
        final results = await repo.getResults('j-1');
        expect(results, hasLength(2));
      });
    });

    group('removeAllForJob', () {
      test('removes all results for the specified job', () async {
        await repo.addResult('j-1', const ValidRow(rowIndex: 0, description: 'A'));
        await repo.addResult('j-1', const SkippedRow(rowIndex: 1, reason: 'B'));
        await repo.removeAllForJob('j-1');
        expect(await repo.getResults('j-1'), isEmpty);
      });

      test('does not affect other jobs', () async {
        await repo.addResult('j-1', const ValidRow(rowIndex: 0, description: 'A'));
        await repo.addResult('j-2', const ValidRow(rowIndex: 0, description: 'B'));
        await repo.removeAllForJob('j-1');
        expect(await repo.getResults('j-2'), hasLength(1));
      });

      test('is a no-op for unknown job', () async {
        await repo.addResult('j-1', const ValidRow(rowIndex: 0, description: 'A'));
        await repo.removeAllForJob('no-such-job');
        expect(await repo.getResults('j-1'), hasLength(1));
      });
    });

    group('security', () {
      test('FailedRow safeErrorMessage does not contain token or secret',
          () async {
        const row = FailedRow(rowIndex: 0, safeErrorMessage: 'Network error.');
        await repo.addResult('j-sec', row);
        final results = await repo.getResults('j-sec');
        final msg = (results.first as FailedRow).safeErrorMessage;
        expect(msg.toLowerCase(), isNot(contains('token')));
        expect(msg.toLowerCase(), isNot(contains('secret')));
      });

      test('sealed switch over persisted results is exhaustive', () async {
        await repo.addResult('j-1', const ValidRow(rowIndex: 0, description: 'A'));
        await repo.addResult('j-1', const SkippedRow(rowIndex: 1, reason: 'B'));
        await repo.addResult('j-1', const FailedRow(rowIndex: 2, safeErrorMessage: 'C'));
        final results = await repo.getResults('j-1');
        for (final result in results) {
          final label = switch (result) {
            ValidRow() => 'valid',
            SkippedRow() => 'skipped',
            FailedRow() => 'failed',
          };
          expect(label, isNotEmpty);
        }
      });
    });
  });
}

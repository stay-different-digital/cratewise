import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/local_import_export_job_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

ImportExportJob makeJob({
  String id = 'job-1',
  ImportExportJobType jobType = ImportExportJobType.csvCollectionExport,
  String source = 'Local collection',
  String target = 'export.csv',
  ImportExportStatus status = ImportExportStatus.idle,
  int? totalItems,
  int? validItems,
  int? skippedItems,
  int? failedItems,
  String? safeErrorMessage,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => ImportExportJob(
  id: id,
  jobType: jobType,
  source: source,
  target: target,
  status: status,
  totalItems: totalItems,
  validItems: validItems,
  skippedItems: skippedItems,
  failedItems: failedItems,
  safeErrorMessage: safeErrorMessage,
  createdAt: createdAt ?? DateTime(2026, 6, 1),
  updatedAt: updatedAt ?? DateTime(2026, 6, 1),
);

void main() {
  group('LocalImportExportJobRepository', () {
    late AppDatabase db;
    late LocalImportExportJobRepository repo;

    setUp(() {
      db = openTestDb();
      repo = LocalImportExportJobRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('add and getById', () {
      test('returns null when no job exists', () async {
        expect(await repo.getById('unknown'), isNull);
      });

      test('returns job after add', () async {
        await repo.add(makeJob(id: 'j-1'));
        final result = await repo.getById('j-1');
        expect(result, isNotNull);
        expect(result!.id, 'j-1');
      });

      test('returns null for different id', () async {
        await repo.add(makeJob(id: 'j-1'));
        expect(await repo.getById('j-2'), isNull);
      });

      test('persists all required fields', () async {
        final created = DateTime(2026, 5, 10, 12);
        final updated = DateTime(2026, 5, 11, 9);
        await repo.add(
          makeJob(
            id: 'j-2',
            jobType: ImportExportJobType.csvCollectionImport,
            source: 'import.csv',
            target: 'Local collection',
            status: ImportExportStatus.running,
            createdAt: created,
            updatedAt: updated,
          ),
        );
        final job = await repo.getById('j-2');
        expect(job, isNotNull);
        expect(job!.jobType, ImportExportJobType.csvCollectionImport);
        expect(job.source, 'import.csv');
        expect(job.target, 'Local collection');
        expect(job.status, ImportExportStatus.running);
        expect(job.createdAt, created);
        expect(job.updatedAt, updated);
      });

      test('persists optional count fields when set', () async {
        await repo.add(
          makeJob(
            id: 'j-3',
            totalItems: 100,
            validItems: 90,
            skippedItems: 5,
            failedItems: 5,
          ),
        );
        final job = await repo.getById('j-3');
        expect(job!.totalItems, 100);
        expect(job.validItems, 90);
        expect(job.skippedItems, 5);
        expect(job.failedItems, 5);
      });

      test('count fields are null when not set', () async {
        await repo.add(makeJob(id: 'j-4'));
        final job = await repo.getById('j-4');
        expect(job!.totalItems, isNull);
        expect(job.validItems, isNull);
        expect(job.skippedItems, isNull);
        expect(job.failedItems, isNull);
      });

      test('persists safeErrorMessage when set', () async {
        await repo.add(
          makeJob(
            id: 'j-5',
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Could not read source file.',
          ),
        );
        final job = await repo.getById('j-5');
        expect(job!.safeErrorMessage, 'Could not read source file.');
      });

      test('safeErrorMessage is null when not set', () async {
        await repo.add(makeJob(id: 'j-6'));
        final job = await repo.getById('j-6');
        expect(job!.safeErrorMessage, isNull);
      });
    });

    group('update', () {
      test('changes status', () async {
        await repo.add(makeJob(id: 'j-1', status: ImportExportStatus.idle));
        final original = (await repo.getById('j-1'))!;
        await repo.update(
          original.copyWith(status: ImportExportStatus.running),
        );
        final reloaded = await repo.getById('j-1');
        expect(reloaded!.status, ImportExportStatus.running);
      });

      test('sets safeErrorMessage and failed status', () async {
        await repo.add(makeJob(id: 'j-1', status: ImportExportStatus.running));
        final original = (await repo.getById('j-1'))!;
        await repo.update(
          original.copyWith(
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Import failed.',
          ),
        );
        final reloaded = await repo.getById('j-1');
        expect(reloaded!.status, ImportExportStatus.failed);
        expect(reloaded.safeErrorMessage, 'Import failed.');
      });

      test('clears safeErrorMessage', () async {
        await repo.add(
          makeJob(
            id: 'j-1',
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Old error.',
          ),
        );
        final original = (await repo.getById('j-1'))!;
        await repo.update(
          original.copyWith(
            status: ImportExportStatus.idle,
            clearSafeErrorMessage: true,
          ),
        );
        final reloaded = await repo.getById('j-1');
        expect(reloaded!.safeErrorMessage, isNull);
      });

      test('updates count fields', () async {
        await repo.add(makeJob(id: 'j-1'));
        final original = (await repo.getById('j-1'))!;
        await repo.update(
          original.copyWith(
            totalItems: 50,
            validItems: 45,
            skippedItems: 3,
            failedItems: 2,
          ),
        );
        final reloaded = await repo.getById('j-1');
        expect(reloaded!.totalItems, 50);
        expect(reloaded.validItems, 45);
        expect(reloaded.skippedItems, 3);
        expect(reloaded.failedItems, 2);
      });

      test('does not affect other jobs', () async {
        await repo.add(makeJob(id: 'j-1', source: 'A'));
        await repo.add(makeJob(id: 'j-2', source: 'B'));
        final first = (await repo.getById('j-1'))!;
        await repo.update(first.copyWith(status: ImportExportStatus.completed));
        final second = await repo.getById('j-2');
        expect(second!.status, ImportExportStatus.idle);
      });
    });

    group('getRecent', () {
      test('returns empty list when no jobs exist', () async {
        expect(await repo.getRecent(), isEmpty);
      });

      test('orders by createdAt descending', () async {
        await repo.add(makeJob(id: 'j-1', createdAt: DateTime(2026, 6, 1)));
        await repo.add(makeJob(id: 'j-2', createdAt: DateTime(2026, 6, 3)));
        await repo.add(makeJob(id: 'j-3', createdAt: DateTime(2026, 6, 2)));
        final recent = await repo.getRecent();
        expect(recent.map((j) => j.id).toList(), ['j-2', 'j-3', 'j-1']);
      });

      test('respects limit parameter', () async {
        for (var i = 1; i <= 5; i++) {
          await repo.add(makeJob(id: 'j-$i', createdAt: DateTime(2026, 6, i)));
        }
        final recent = await repo.getRecent(limit: 3);
        expect(recent, hasLength(3));
        expect(recent.first.id, 'j-5');
      });

      test('returns all jobs when count is below limit', () async {
        await repo.add(makeJob(id: 'j-1', createdAt: DateTime(2026, 6, 1)));
        await repo.add(makeJob(id: 'j-2', createdAt: DateTime(2026, 6, 2)));
        expect(await repo.getRecent(limit: 10), hasLength(2));
      });

      test('respects offset parameter', () async {
        for (var i = 1; i <= 5; i++) {
          await repo.add(makeJob(id: 'j-$i', createdAt: DateTime(2026, 6, i)));
        }
        // Newest first: j-5, j-4, j-3, j-2, j-1
        final page2 = await repo.getRecent(limit: 2, offset: 2);
        expect(page2, hasLength(2));
        expect(page2.first.id, 'j-3');
        expect(page2.last.id, 'j-2');
      });

      test('returns empty list when offset exceeds total count', () async {
        await repo.add(makeJob(id: 'j-1'));
        expect(await repo.getRecent(limit: 20, offset: 10), isEmpty);
      });
    });

    group('count', () {
      test('returns 0 when no jobs exist', () async {
        expect(await repo.count(), 0);
      });

      test('returns total job count', () async {
        await repo.add(makeJob(id: 'j-1', createdAt: DateTime(2026, 6, 1)));
        await repo.add(makeJob(id: 'j-2', createdAt: DateTime(2026, 6, 2)));
        expect(await repo.count(), 2);
      });

      test('decrements after remove', () async {
        await repo.add(makeJob(id: 'j-1'));
        await repo.add(makeJob(id: 'j-2', createdAt: DateTime(2026, 6, 2)));
        await repo.remove('j-1');
        expect(await repo.count(), 1);
      });
    });

    group('remove', () {
      test('deletes the job', () async {
        await repo.add(makeJob(id: 'j-1'));
        await repo.remove('j-1');
        expect(await repo.getById('j-1'), isNull);
      });

      test('does not affect other jobs', () async {
        await repo.add(makeJob(id: 'j-1'));
        await repo.add(makeJob(id: 'j-2', createdAt: DateTime(2026, 6, 2)));
        await repo.remove('j-1');
        expect(await repo.getById('j-2'), isNotNull);
      });

      test('is a no-op for unknown id', () async {
        await repo.add(makeJob(id: 'j-1'));
        await repo.remove('unknown');
        expect(await repo.getById('j-1'), isNotNull);
      });
    });

    group('all job types round-trip', () {
      for (final type in ImportExportJobType.values) {
        test('$type round-trips', () async {
          await repo.add(makeJob(id: type.name, jobType: type));
          final reloaded = await repo.getById(type.name);
          expect(reloaded!.jobType, type);
        });
      }
    });

    group('all status values round-trip', () {
      for (final status in ImportExportStatus.values) {
        test('$status round-trips', () async {
          await repo.add(makeJob(id: status.name, status: status));
          final reloaded = await repo.getById(status.name);
          expect(reloaded!.status, status);
        });
      }
    });

    group('security', () {
      test(
        'source and target fields do not contain tokens or secrets',
        () async {
          await repo.add(
            makeJob(
              id: 'j-sec',
              source: 'Local collection',
              target: 'export.csv',
            ),
          );
          final job = await repo.getById('j-sec');
          expect(job!.source.toLowerCase(), isNot(contains('token')));
          expect(job.source.toLowerCase(), isNot(contains('secret')));
          expect(job.target.toLowerCase(), isNot(contains('token')));
          expect(job.target.toLowerCase(), isNot(contains('secret')));
        },
      );

      test('safeErrorMessage does not contain token or secret', () async {
        await repo.add(
          makeJob(
            id: 'j-err',
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Network error.',
          ),
        );
        final job = await repo.getById('j-err');
        expect(job!.safeErrorMessage!.toLowerCase(), isNot(contains('token')));
        expect(job.safeErrorMessage!.toLowerCase(), isNot(contains('secret')));
      });
    });
  });
}

import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// In-memory fake — tests the contract surface, not a real implementation.
class FakeImportExportJobRepository implements ImportExportJobRepository {
  final _store = <String, ImportExportJob>{};

  @override
  Future<void> add(ImportExportJob job) async => _store[job.id] = job;

  @override
  Future<void> update(ImportExportJob job) async => _store[job.id] = job;

  @override
  Future<ImportExportJob?> getById(String id) async => _store[id];

  @override
  Future<List<ImportExportJob>> getRecent({int limit = 20}) async {
    final sorted = _store.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<void> remove(String id) async => _store.remove(id);
}

ImportExportJob makeJob({
  String id = 'job-1',
  ImportExportJobType jobType = ImportExportJobType.csvCollectionExport,
  String source = 'Local collection',
  String target = 'export.csv',
  ImportExportStatus status = ImportExportStatus.idle,
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    ImportExportJob(
      id: id,
      jobType: jobType,
      source: source,
      target: target,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 6, 1),
      updatedAt: updatedAt ?? DateTime(2026, 6, 1),
    );

void main() {
  group('ImportExportJobRepository contract', () {
    late FakeImportExportJobRepository repo;

    setUp(() => repo = FakeImportExportJobRepository());

    group('add and getById', () {
      test('getById returns null when no job exists', () async {
        expect(await repo.getById('unknown'), isNull);
      });

      test('getById returns job after add', () async {
        await repo.add(makeJob(id: 'j-1'));
        final result = await repo.getById('j-1');
        expect(result, isNotNull);
        expect(result!.id, 'j-1');
      });

      test('getById returns null for different id', () async {
        await repo.add(makeJob(id: 'j-1'));
        expect(await repo.getById('j-2'), isNull);
      });

      test('stored job preserves all fields', () async {
        final job = makeJob(
          id: 'j-2',
          jobType: ImportExportJobType.csvCollectionImport,
          source: 'import.csv',
          target: 'Local collection',
          status: ImportExportStatus.running,
        );
        await repo.add(job);
        final stored = await repo.getById('j-2');
        expect(stored!.jobType, ImportExportJobType.csvCollectionImport);
        expect(stored.source, 'import.csv');
        expect(stored.target, 'Local collection');
        expect(stored.status, ImportExportStatus.running);
      });
    });

    group('update', () {
      test('update replaces job with matching id', () async {
        await repo.add(makeJob(id: 'j-1', status: ImportExportStatus.idle));
        final updated =
            makeJob(id: 'j-1', status: ImportExportStatus.running);
        await repo.update(updated);
        final stored = await repo.getById('j-1');
        expect(stored!.status, ImportExportStatus.running);
      });

      test('update job status to completed', () async {
        final job = makeJob(id: 'j-3', status: ImportExportStatus.running);
        await repo.add(job);
        await repo.update(
          job.copyWith(status: ImportExportStatus.completed),
        );
        final stored = await repo.getById('j-3');
        expect(stored!.status, ImportExportStatus.completed);
      });

      test('update job with safe error message', () async {
        final job = makeJob(id: 'j-4', status: ImportExportStatus.running);
        await repo.add(job);
        await repo.update(
          job.copyWith(
            status: ImportExportStatus.failed,
            safeErrorMessage: 'Could not read source file.',
          ),
        );
        final stored = await repo.getById('j-4');
        expect(stored!.status, ImportExportStatus.failed);
        expect(stored.safeErrorMessage, 'Could not read source file.');
      });
    });

    group('getRecent', () {
      test('returns empty list when no jobs exist', () async {
        expect(await repo.getRecent(), isEmpty);
      });

      test('returns jobs ordered by createdAt descending', () async {
        await repo.add(makeJob(id: 'j-1', createdAt: DateTime(2026, 6, 1)));
        await repo.add(makeJob(id: 'j-2', createdAt: DateTime(2026, 6, 3)));
        await repo.add(makeJob(id: 'j-3', createdAt: DateTime(2026, 6, 2)));
        final recent = await repo.getRecent();
        expect(recent.map((j) => j.id).toList(), ['j-2', 'j-3', 'j-1']);
      });

      test('respects limit parameter', () async {
        for (var i = 1; i <= 5; i++) {
          await repo.add(
              makeJob(id: 'j-$i', createdAt: DateTime(2026, 6, i)));
        }
        final recent = await repo.getRecent(limit: 3);
        expect(recent, hasLength(3));
        expect(recent.first.id, 'j-5');
      });

      test('returns all jobs when count is below limit', () async {
        await repo.add(makeJob(id: 'j-1'));
        await repo.add(makeJob(id: 'j-2', createdAt: DateTime(2026, 6, 2)));
        final recent = await repo.getRecent(limit: 10);
        expect(recent, hasLength(2));
      });
    });

    group('remove', () {
      test('remove deletes the job', () async {
        await repo.add(makeJob(id: 'j-1'));
        await repo.remove('j-1');
        expect(await repo.getById('j-1'), isNull);
      });

      test('remove does not affect other jobs', () async {
        await repo.add(makeJob(id: 'j-1'));
        await repo.add(makeJob(id: 'j-2', createdAt: DateTime(2026, 6, 2)));
        await repo.remove('j-1');
        expect(await repo.getById('j-2'), isNotNull);
      });

      test('remove on missing id is a no-op', () async {
        await repo.add(makeJob(id: 'j-1'));
        await repo.remove('unknown');
        expect(await repo.getById('j-1'), isNotNull);
      });
    });

    group('security', () {
      test('source and target fields do not contain tokens or secrets', () async {
        await repo.add(makeJob(id: 'j-sec', source: 'Local collection', target: 'export.csv'));
        final stored = await repo.getById('j-sec');
        expect(stored!.source.toLowerCase(), isNot(contains('token')));
        expect(stored.source.toLowerCase(), isNot(contains('secret')));
        expect(stored.target.toLowerCase(), isNot(contains('token')));
        expect(stored.target.toLowerCase(), isNot(contains('secret')));
      });

      test('safe error message does not contain token or secret', () async {
        final job = makeJob(id: 'j-err').copyWith(
          status: ImportExportStatus.failed,
          safeErrorMessage: 'Network error.',
        );
        await repo.add(job);
        final stored = await repo.getById('j-err');
        expect(stored!.safeErrorMessage!.toLowerCase(), isNot(contains('token')));
        expect(stored.safeErrorMessage!.toLowerCase(), isNot(contains('secret')));
      });
    });
  });
}

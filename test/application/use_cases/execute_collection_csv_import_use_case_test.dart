import 'package:cratewise/application/use_cases/execute_collection_csv_import_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/csv_collection_import_preview.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  final List<CollectionItem> added = [];
  final Set<int> existingReleaseIds;

  _FakeCollectionRepository({Set<int>? existingReleaseIds})
    : existingReleaseIds = existingReleaseIds ?? {};

  @override
  Future<void> add(CollectionItem item) async => added.add(item);

  @override
  Future<bool> containsRelease(int id) async => existingReleaseIds.contains(id);

  @override
  Future<List<CollectionItem>> getAll() async => [];

  @override
  Future<CollectionItem?> getById(String id) async => null;

  @override
  Future<void> update(CollectionItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _ThrowingCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<void> add(CollectionItem item) async =>
      throw Exception('DB write failed');

  @override
  Future<bool> containsRelease(int id) async => false;

  @override
  Future<List<CollectionItem>> getAll() async => [];

  @override
  Future<CollectionItem?> getById(String id) async => null;

  @override
  Future<void> update(CollectionItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _FakeJobRepository implements ImportExportJobRepository {
  final List<ImportExportJob> jobs = [];

  @override
  Future<void> add(ImportExportJob job) async => jobs.add(job);

  @override
  Future<void> update(ImportExportJob job) async {
    final i = jobs.indexWhere((j) => j.id == job.id);
    if (i >= 0) jobs[i] = job;
  }

  @override
  Future<ImportExportJob?> getById(String id) async =>
      jobs.where((j) => j.id == id).firstOrNull;

  @override
  Future<List<ImportExportJob>> getRecent({
    int limit = 20,
    int offset = 0,
  }) async => jobs;
  @override
  Future<int> count() async => 0;

  @override
  Future<void> remove(String id) async => jobs.removeWhere((j) => j.id == id);
}

class _FakeRowResultRepository implements ImportExportRowResultRepository {
  final Map<String, List<ImportExportRowResult>> results = {};

  @override
  Future<void> addResult(String jobId, ImportExportRowResult result) async =>
      results.putIfAbsent(jobId, () => []).add(result);

  @override
  Future<List<ImportExportRowResult>> getResults(String jobId) async =>
      results[jobId] ?? [];

  @override
  Future<void> removeAllForJob(String jobId) async => results.remove(jobId);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CsvCollectionImportRow _makeValidRow({
  int rowIndex = 0,
  int releaseId = 100,
  String artist = 'Test Artist',
  String title = 'Test Album',
}) => CsvCollectionImportRow(
  rowIndex: rowIndex,
  artist: artist,
  title: title,
  discogsReleaseId: releaseId,
  mediaCondition: RecordCondition.nearMint,
  sleeveCondition: RecordCondition.veryGoodPlus,
  tags: const [],
);

CsvCollectionImportPreview _makePreview({
  List<CsvCollectionImportRow>? validRows,
  List<SkippedRow>? skippedRows,
  List<FailedRow>? failedRows,
}) => CsvCollectionImportPreview(
  validRows: validRows ?? [],
  skippedRows: skippedRows ?? [],
  failedRows: failedRows ?? [],
);

({
  ExecuteCollectionCsvImportUseCase useCase,
  _FakeCollectionRepository collectionRepo,
  _FakeJobRepository jobRepo,
  _FakeRowResultRepository rowResultRepo,
})
_makeUseCase({
  CollectionRepository? collectionRepository,
  ImportExportJobRepository? jobRepository,
  ImportExportRowResultRepository? rowResultRepository,
  String Function()? idGenerator,
}) {
  final collectionRepo = _FakeCollectionRepository();
  final jobRepo = _FakeJobRepository();
  final rowResultRepo = _FakeRowResultRepository();
  return (
    useCase: ExecuteCollectionCsvImportUseCase(
      collectionRepository: collectionRepository ?? collectionRepo,
      jobRepository: jobRepository ?? jobRepo,
      rowResultRepository: rowResultRepository ?? rowResultRepo,
      idGenerator: idGenerator,
    ),
    collectionRepo: collectionRepo,
    jobRepo: jobRepo,
    rowResultRepo: rowResultRepo,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExecuteCollectionCsvImportUseCase', () {
    group('empty preview', () {
      test(
        'returns ExecuteCollectionCsvImportCompleted for empty preview',
        () async {
          final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
              _makeUseCase();
          final result = await useCase.execute(_makePreview());
          expect(result, isA<ExecuteCollectionCsvImportCompleted>());
        },
      );

      test('imported is 0 for empty preview', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(_makePreview())
                as ExecuteCollectionCsvImportCompleted;
        expect(result.imported, 0);
      });

      test('skipped is 0 for empty preview', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(_makePreview())
                as ExecuteCollectionCsvImportCompleted;
        expect(result.skipped, 0);
      });

      test('failed is 0 for empty preview', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(_makePreview())
                as ExecuteCollectionCsvImportCompleted;
        expect(result.failed, 0);
      });
    });

    group('valid rows — new items', () {
      test('saves valid row to collection', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(_makePreview(validRows: [_makeValidRow()]));
        expect(collectionRepo.added.length, 1);
      });

      test('saved item has correct artist', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(validRows: [_makeValidRow(artist: 'Miles Davis')]),
        );
        expect(collectionRepo.added.first.artist, 'Miles Davis');
      });

      test('saved item has correct title', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(validRows: [_makeValidRow(title: 'Kind of Blue')]),
        );
        expect(collectionRepo.added.first.title, 'Kind of Blue');
      });

      test('saved item has correct discogsReleaseId', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(validRows: [_makeValidRow(releaseId: 99)]),
        );
        expect(collectionRepo.added.first.discogsReleaseId, 99);
      });

      test('saved item preserves mediaCondition', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(
            validRows: [
              CsvCollectionImportRow(
                rowIndex: 0,
                artist: 'A',
                title: 'T',
                discogsReleaseId: 1,
                mediaCondition: RecordCondition.mint,
                sleeveCondition: RecordCondition.veryGood,
                tags: const [],
              ),
            ],
          ),
        );
        expect(collectionRepo.added.first.mediaCondition, RecordCondition.mint);
        expect(
          collectionRepo.added.first.sleeveCondition,
          RecordCondition.veryGood,
        );
      });

      test('saved item preserves tags', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(
            validRows: [
              CsvCollectionImportRow(
                rowIndex: 0,
                artist: 'A',
                title: 'T',
                discogsReleaseId: 1,
                mediaCondition: RecordCondition.notSet,
                sleeveCondition: RecordCondition.notSet,
                tags: const ['jazz', 'vinyl'],
              ),
            ],
          ),
        );
        expect(collectionRepo.added.first.tags, ['jazz', 'vinyl']);
      });

      test('imported count matches number of new rows', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    validRows: [
                      _makeValidRow(rowIndex: 0, releaseId: 1),
                      _makeValidRow(rowIndex: 1, releaseId: 2),
                      _makeValidRow(rowIndex: 2, releaseId: 3),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        expect(result.imported, 3);
      });

      test('records ValidRow for each imported item', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    validRows: [
                      _makeValidRow(rowIndex: 0, releaseId: 1),
                      _makeValidRow(rowIndex: 1, releaseId: 2),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<ValidRow>().length, 2);
      });

      test('ValidRow description contains artist and title', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    validRows: [
                      _makeValidRow(
                        artist: 'Massive Attack',
                        title: 'Blue Lines',
                      ),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        final valid = rows.whereType<ValidRow>().first;
        expect(valid.description, contains('Massive Attack'));
        expect(valid.description, contains('Blue Lines'));
      });
    });

    group('valid rows — DB duplicates', () {
      test('skips row already in collection', () async {
        final collectionRepo = _FakeCollectionRepository(
          existingReleaseIds: {42},
        );
        final (:useCase, collectionRepo: _, :jobRepo, :rowResultRepo) =
            _makeUseCase(collectionRepository: collectionRepo);
        await useCase.execute(
          _makePreview(validRows: [_makeValidRow(releaseId: 42)]),
        );
        expect(collectionRepo.added, isEmpty);
      });

      test('DB-duplicate row is counted as skipped', () async {
        final collectionRepo = _FakeCollectionRepository(
          existingReleaseIds: {42},
        );
        final (:useCase, collectionRepo: _, :jobRepo, :rowResultRepo) =
            _makeUseCase(collectionRepository: collectionRepo);
        final result =
            await useCase.execute(
                  _makePreview(validRows: [_makeValidRow(releaseId: 42)]),
                )
                as ExecuteCollectionCsvImportCompleted;
        expect(result.skipped, 1);
        expect(result.imported, 0);
      });

      test('records SkippedRow for DB-duplicate', () async {
        final collectionRepo = _FakeCollectionRepository(
          existingReleaseIds: {42},
        );
        final (:useCase, collectionRepo: _, :jobRepo, :rowResultRepo) =
            _makeUseCase(collectionRepository: collectionRepo);
        final result =
            await useCase.execute(
                  _makePreview(validRows: [_makeValidRow(releaseId: 42)]),
                )
                as ExecuteCollectionCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<SkippedRow>().length, 1);
      });

      test('SkippedRow reason is Already in collection', () async {
        final collectionRepo = _FakeCollectionRepository(
          existingReleaseIds: {42},
        );
        final (:useCase, collectionRepo: _, :jobRepo, :rowResultRepo) =
            _makeUseCase(collectionRepository: collectionRepo);
        final result =
            await useCase.execute(
                  _makePreview(validRows: [_makeValidRow(releaseId: 42)]),
                )
                as ExecuteCollectionCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(
          rows.whereType<SkippedRow>().first.reason,
          'Already in collection',
        );
      });
    });

    group('preview skipped rows', () {
      test('preview skipped rows contribute to skipped count', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    skippedRows: [
                      const SkippedRow(
                        rowIndex: 2,
                        reason: 'Duplicate release ID in file',
                      ),
                      const SkippedRow(
                        rowIndex: 3,
                        reason: 'Duplicate release ID in file',
                      ),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        expect(result.skipped, 2);
      });

      test('preview skipped rows are recorded in row results', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    skippedRows: [
                      const SkippedRow(
                        rowIndex: 2,
                        reason: 'Duplicate release ID in file',
                      ),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<SkippedRow>().length, 1);
      });
    });

    group('preview failed rows', () {
      test('preview failed rows contribute to failed count', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    failedRows: [
                      const FailedRow(
                        rowIndex: 0,
                        safeErrorMessage: 'Missing artist',
                      ),
                      const FailedRow(
                        rowIndex: 1,
                        safeErrorMessage: 'Missing title',
                      ),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        expect(result.failed, 2);
      });

      test('preview failed rows are recorded in row results', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    failedRows: [
                      const FailedRow(
                        rowIndex: 0,
                        safeErrorMessage: 'Missing artist',
                      ),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<FailedRow>().length, 1);
      });
    });

    group('mixed preview', () {
      test('correct counts for mixed valid/skipped/failed preview', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    validRows: [
                      _makeValidRow(rowIndex: 0, releaseId: 1),
                      _makeValidRow(rowIndex: 1, releaseId: 2),
                    ],
                    skippedRows: [
                      const SkippedRow(
                        rowIndex: 2,
                        reason: 'Duplicate release ID in file',
                      ),
                    ],
                    failedRows: [
                      const FailedRow(
                        rowIndex: 3,
                        safeErrorMessage: 'Missing artist',
                      ),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        expect(result.imported, 2);
        expect(result.skipped, 1);
        expect(result.failed, 1);
      });
    });

    group('save failure', () {
      test('save failure produces FailedRow', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase(collectionRepository: _ThrowingCollectionRepository());
        final result =
            await useCase.execute(_makePreview(validRows: [_makeValidRow()]))
                as ExecuteCollectionCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<FailedRow>().length, 1);
      });

      test('save failure counts toward failed', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase(collectionRepository: _ThrowingCollectionRepository());
        final result =
            await useCase.execute(_makePreview(validRows: [_makeValidRow()]))
                as ExecuteCollectionCsvImportCompleted;
        expect(result.failed, 1);
        expect(result.imported, 0);
      });

      test('import continues after a row save failure', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase(collectionRepository: _ThrowingCollectionRepository());
        final result =
            await useCase.execute(
                  _makePreview(
                    validRows: [
                      _makeValidRow(rowIndex: 0, releaseId: 1),
                      _makeValidRow(rowIndex: 1, releaseId: 2),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<FailedRow>().length, 2);
      });
    });

    group('job record', () {
      test('job type is csvCollectionImport', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(_makePreview(validRows: [_makeValidRow()]))
                as ExecuteCollectionCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.jobType, ImportExportJobType.csvCollectionImport);
      });

      test('job source is CSV file', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(_makePreview())
                as ExecuteCollectionCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.source, 'CSV file');
      });

      test('job target is Local collection', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(_makePreview())
                as ExecuteCollectionCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.target, 'Local collection');
      });

      test('updates job with completed status when all succeed', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(_makePreview(validRows: [_makeValidRow()]))
                as ExecuteCollectionCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.status, ImportExportStatus.completed);
      });

      test('updates job with completedWithErrors when some fail', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase(collectionRepository: _ThrowingCollectionRepository());
        final result =
            await useCase.execute(_makePreview(validRows: [_makeValidRow()]))
                as ExecuteCollectionCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.status, ImportExportStatus.completedWithErrors);
      });

      test('job has correct totalItems', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    validRows: [_makeValidRow(rowIndex: 0, releaseId: 1)],
                    skippedRows: [
                      const SkippedRow(
                        rowIndex: 1,
                        reason: 'Duplicate release ID in file',
                      ),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.totalItems, 2);
      });

      test('job has correct validItems', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(
                  _makePreview(
                    validRows: [
                      _makeValidRow(rowIndex: 0, releaseId: 1),
                      _makeValidRow(rowIndex: 1, releaseId: 2),
                    ],
                  ),
                )
                as ExecuteCollectionCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.validItems, 2);
      });

      test('result jobId is non-empty', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result =
            await useCase.execute(_makePreview(validRows: [_makeValidRow()]))
                as ExecuteCollectionCsvImportCompleted;
        expect(result.jobId, isNotEmpty);
      });
    });
  });
}

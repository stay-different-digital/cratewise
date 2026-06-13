import 'package:cratewise/application/use_cases/execute_collection_import_use_case.dart';
import 'package:cratewise/domain/models/collection_import_preview.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  final List<CollectionItem> added = [];

  @override
  Future<void> add(CollectionItem item) async => added.add(item);

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

class _ThrowingCollectionRepository implements CollectionRepository {
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

class _SpyCollectionRepository implements CollectionRepository {
  _SpyCollectionRepository({required this.existing});

  final List<CollectionItem> existing;
  final List<CollectionItem> updated = [];

  @override
  Future<List<CollectionItem>> getAll() async => existing;

  @override
  Future<void> add(CollectionItem item) async {}

  @override
  Future<bool> containsRelease(int id) async =>
      existing.any((e) => e.discogsReleaseId == id);

  @override
  Future<CollectionItem?> getById(String id) async => null;

  @override
  Future<void> update(CollectionItem item) async => updated.add(item);

  @override
  Future<void> remove(String id) async {}
}

CollectionItem _makeCollectionItem(int releaseId, SyncStatus status) {
  final now = DateTime(2026, 1, 1);
  return CollectionItem(
    id: 'id-$releaseId',
    discogsReleaseId: releaseId,
    artist: 'Artist',
    title: 'Title',
    mediaCondition: RecordCondition.notSet,
    sleeveCondition: RecordCondition.notSet,
    tags: const [],
    syncStatus: status,
    createdAt: now,
    updatedAt: now,
  );
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

CollectionImportPreview makePreview({
  int newCount = 0,
  int duplicateCount = 0,
  int invalidCount = 0,
}) {
  final rows = <CollectionImportRow>[
    for (int i = 0; i < newCount; i++)
      NewCollectionRow(
        releaseId: 100 + i,
        title: 'Album $i',
        artist: 'Artist $i',
        year: 2000 + i,
      ),
    for (int i = 0; i < duplicateCount; i++)
      DuplicateCollectionRow(
        releaseId: 200 + i,
        title: 'Dupe $i',
        artist: 'Artist',
      ),
    for (int i = 0; i < invalidCount; i++)
      InvalidCollectionRow(
        releaseId: 0,
        title: '',
        artist: 'Artist',
        reason: 'Missing title',
      ),
  ];
  return CollectionImportPreview(rows: rows);
}

({
  ExecuteCollectionImportUseCase useCase,
  _FakeCollectionRepository collectionRepo,
  _FakeJobRepository jobRepo,
  _FakeRowResultRepository rowResultRepo,
})
makeUseCase({
  CollectionRepository? collectionRepository,
  ImportExportJobRepository? jobRepository,
  ImportExportRowResultRepository? rowResultRepository,
}) {
  final collectionRepo = _FakeCollectionRepository();
  final jobRepo = _FakeJobRepository();
  final rowResultRepo = _FakeRowResultRepository();
  return (
    useCase: ExecuteCollectionImportUseCase(
      collectionRepository: collectionRepository ?? collectionRepo,
      jobRepository: jobRepository ?? jobRepo,
      rowResultRepository: rowResultRepository ?? rowResultRepo,
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
  group('ExecuteCollectionImportUseCase', () {
    group('instance id capture (US-72)', () {
      test('saves the Discogs instance id on imported items', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final preview = CollectionImportPreview(
          rows: const [
            NewCollectionRow(
              releaseId: 100,
              title: 'Album',
              artist: 'Artist',
              instanceId: 5551234,
            ),
          ],
        );

        await useCase.execute(preview);

        expect(collectionRepo.added.single.discogsInstanceId, 5551234);
      });

      test('skips a conflict row instead of re-importing it', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final preview = CollectionImportPreview(
          rows: const [
            ConflictCollectionRow(
              releaseId: 100,
              title: 'Album',
              artist: 'Artist',
            ),
          ],
        );

        final result = await useCase.execute(preview) as ExecuteImportCompleted;

        expect(collectionRepo.added, isEmpty);
        expect(result.imported, 0);
        expect(result.skipped, 1);
      });
    });

    group('empty preview', () {
      test('returns ExecuteImportCompleted for empty preview', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result = await useCase.execute(makePreview());
        expect(result, isA<ExecuteImportCompleted>());
      });

      test('imported is 0 for empty preview', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview()) as ExecuteImportCompleted;
        expect(result.imported, 0);
      });

      test('skipped is 0 for empty preview', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview()) as ExecuteImportCompleted;
        expect(result.skipped, 0);
      });

      test('failed is 0 for empty preview', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview()) as ExecuteImportCompleted;
        expect(result.failed, 0);
      });
    });

    group('new items', () {
      test('saves new rows to collection', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(makePreview(newCount: 2));
        expect(collectionRepo.added.length, 2);
      });

      test('saved item has correct artist', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(
          CollectionImportPreview(
            rows: [
              const NewCollectionRow(
                releaseId: 1,
                title: 'My Album',
                artist: 'My Artist',
              ),
            ],
          ),
        );
        expect(collectionRepo.added.first.artist, 'My Artist');
      });

      test('saved item has correct title', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(
          CollectionImportPreview(
            rows: [
              const NewCollectionRow(
                releaseId: 1,
                title: 'My Album',
                artist: 'My Artist',
              ),
            ],
          ),
        );
        expect(collectionRepo.added.first.title, 'My Album');
      });

      test('saved item has correct discogsReleaseId', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(
          CollectionImportPreview(
            rows: [
              const NewCollectionRow(releaseId: 42, title: 'T', artist: 'A'),
            ],
          ),
        );
        expect(collectionRepo.added.first.discogsReleaseId, 42);
      });

      test('imported item has syncStatus synced', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(
          CollectionImportPreview(
            rows: [
              const NewCollectionRow(releaseId: 42, title: 'T', artist: 'A'),
            ],
          ),
        );
        expect(collectionRepo.added.first.syncStatus, SyncStatus.synced);
      });

      test('imported count matches new rows', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 3))
                as ExecuteImportCompleted;
        expect(result.imported, 3);
      });

      test('records ValidRow per imported item', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 2))
                as ExecuteImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<ValidRow>().length, 2);
      });

      test('ValidRow description contains artist and title', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(
                  CollectionImportPreview(
                    rows: [
                      const NewCollectionRow(
                        releaseId: 1,
                        title: 'Blue Lines',
                        artist: 'Massive Attack',
                      ),
                    ],
                  ),
                )
                as ExecuteImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        final valid = rows.whereType<ValidRow>().first;
        expect(valid.description, contains('Massive Attack'));
        expect(valid.description, contains('Blue Lines'));
      });
    });

    group('skip rules', () {
      test('duplicate row produces SkippedRow', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(duplicateCount: 1))
                as ExecuteImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<SkippedRow>().length, 1);
      });

      test(
        'duplicate row without existing local item produces SkippedRow',
        () async {
          final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
              makeUseCase();
          final result =
              await useCase.execute(makePreview(duplicateCount: 1))
                  as ExecuteImportCompleted;
          final rows = await rowResultRepo.getResults(result.jobId);
          final skipped = rows.whereType<SkippedRow>().first;
          expect(skipped.reason, 'Already linked to Discogs');
        },
      );

      test('invalid row produces SkippedRow', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(invalidCount: 1))
                as ExecuteImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<SkippedRow>().length, 1);
      });

      test('skipped count = duplicates + invalids', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(
                  makePreview(duplicateCount: 2, invalidCount: 3),
                )
                as ExecuteImportCompleted;
        expect(result.skipped, 5);
      });

      test('duplicate rows are not added to collection', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(makePreview(duplicateCount: 2));
        expect(collectionRepo.added, isEmpty);
      });

      test(
        'mixed preview produces correct imported and skipped counts',
        () async {
          final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
              makeUseCase();
          final result =
              await useCase.execute(
                    makePreview(
                      newCount: 3,
                      duplicateCount: 2,
                      invalidCount: 1,
                    ),
                  )
                  as ExecuteImportCompleted;
          expect(result.imported, 3);
          expect(result.skipped, 3);
          expect(result.failed, 0);
        },
      );
    });

    group('failed items', () {
      test('collection save failure produces FailedRow', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase(collectionRepository: _ThrowingCollectionRepository());
        final result =
            await useCase.execute(makePreview(newCount: 1))
                as ExecuteImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<FailedRow>().length, 1);
      });

      test('import continues after a failed row', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase(collectionRepository: _ThrowingCollectionRepository());
        final result =
            await useCase.execute(makePreview(newCount: 3))
                as ExecuteImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<FailedRow>().length, 3);
      });

      test('failed count is correct', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase(collectionRepository: _ThrowingCollectionRepository());
        final result =
            await useCase.execute(makePreview(newCount: 2))
                as ExecuteImportCompleted;
        expect(result.failed, 2);
      });
    });

    group('job record', () {
      test('creates job with running status initially', () async {
        ImportExportStatus? statusAtAdd;
        final capturingJobRepo = _CapturingJobRepository(
          onAdd: (job) => statusAtAdd = job.status,
        );
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase(jobRepository: capturingJobRepo);
        await useCase.execute(makePreview(newCount: 1));
        expect(statusAtAdd, ImportExportStatus.running);
      });

      test('updates job with completed status when all succeed', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 2))
                as ExecuteImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.status, ImportExportStatus.completed);
      });

      test('updates job with completedWithErrors when some fail', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase(collectionRepository: _ThrowingCollectionRepository());
        final result =
            await useCase.execute(makePreview(newCount: 1))
                as ExecuteImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.status, ImportExportStatus.completedWithErrors);
      });

      test('job has correct totalItems', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 2, duplicateCount: 1))
                as ExecuteImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.totalItems, 3);
      });

      test('job has correct validItems', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 4))
                as ExecuteImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.validItems, 4);
      });

      test('job has correct skippedItems', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(
                  makePreview(duplicateCount: 2, invalidCount: 1),
                )
                as ExecuteImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.skippedItems, 3);
      });

      test('result jobId is non-empty', () async {
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 1))
                as ExecuteImportCompleted;
        expect(result.jobId, isNotEmpty);
      });
    });

    group('duplicate linking', () {
      test(
        'links localOnly item to Discogs when duplicate row matches',
        () async {
          final existing = _makeCollectionItem(200, SyncStatus.localOnly);
          final spy = _SpyCollectionRepository(existing: [existing]);
          final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
              makeUseCase(collectionRepository: spy);
          final preview = CollectionImportPreview(
            rows: [
              const DuplicateCollectionRow(
                releaseId: 200,
                title: 'Kind Of Blue',
                artist: 'Miles Davis',
              ),
            ],
          );
          final result =
              await useCase.execute(preview) as ExecuteImportCompleted;
          expect(spy.updated, hasLength(1));
          expect(spy.updated.first.syncStatus, SyncStatus.synced);
          expect(result.linked, 1);
        },
      );

      test('linked count is 0 when duplicate already synced', () async {
        final existing = _makeCollectionItem(200, SyncStatus.synced);
        final spy = _SpyCollectionRepository(existing: [existing]);
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase(collectionRepository: spy);
        final result =
            await useCase.execute(makePreview(duplicateCount: 1))
                as ExecuteImportCompleted;
        expect(spy.updated, isEmpty);
        expect(result.linked, 0);
        expect(result.skipped, 1);
      });

      test('records ValidRow for linked item', () async {
        final existing = _makeCollectionItem(200, SyncStatus.localOnly);
        final spy = _SpyCollectionRepository(existing: [existing]);
        final (:useCase, :collectionRepo, :jobRepo, :rowResultRepo) =
            makeUseCase(collectionRepository: spy);
        final preview = CollectionImportPreview(
          rows: [
            const DuplicateCollectionRow(
              releaseId: 200,
              title: 'Kind Of Blue',
              artist: 'Miles Davis',
            ),
          ],
        );
        final result = await useCase.execute(preview) as ExecuteImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        final valid = rows.whereType<ValidRow>().first;
        expect(valid.description, contains('Miles Davis'));
        expect(valid.description, contains('Kind Of Blue'));
      });

      test('linked items count towards job validItems', () async {
        final existing = _makeCollectionItem(200, SyncStatus.localOnly);
        final spy = _SpyCollectionRepository(existing: [existing]);
        final jobRepo = _FakeJobRepository();
        final rowResultRepo = _FakeRowResultRepository();
        final useCase = ExecuteCollectionImportUseCase(
          collectionRepository: spy,
          jobRepository: jobRepo,
          rowResultRepository: rowResultRepo,
          idGenerator: () => 'test-id',
        );
        final preview = CollectionImportPreview(
          rows: [
            const NewCollectionRow(releaseId: 100, title: 'T', artist: 'A'),
            const DuplicateCollectionRow(
              releaseId: 200,
              title: 'Kind Of Blue',
              artist: 'Miles Davis',
            ),
          ],
        );
        final result = await useCase.execute(preview) as ExecuteImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(result.imported, 1);
        expect(result.linked, 1);
        expect(job?.validItems, 2);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: capturing job repo to observe status at add-time
// ---------------------------------------------------------------------------

class _CapturingJobRepository extends _FakeJobRepository {
  _CapturingJobRepository({required this.onAdd});

  final void Function(ImportExportJob job) onAdd;

  @override
  Future<void> add(ImportExportJob job) async {
    onAdd(job);
    await super.add(job);
  }
}

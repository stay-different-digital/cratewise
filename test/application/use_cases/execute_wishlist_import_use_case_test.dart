import 'package:cratewise/application/use_cases/execute_wishlist_import_use_case.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_import_preview.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  final List<WishlistItem> added = [];

  @override
  Future<void> add(WishlistItem item) async => added.add(item);

  @override
  Future<bool> containsRelease(int id) async => false;

  @override
  Future<List<WishlistItem>> getAll() async => [];

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _SpyWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _SpyWishlistRepository({required this.existing});

  final List<WishlistItem> existing;
  final List<WishlistItem> updated = [];

  @override
  Future<List<WishlistItem>> getAll() async => existing;

  @override
  Future<void> add(WishlistItem item) async {}

  @override
  Future<bool> containsRelease(int id) async =>
      existing.any((e) => e.discogsReleaseId == id);

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<void> update(WishlistItem item) async => updated.add(item);

  @override
  Future<void> remove(String id) async {}
}

WishlistItem _makeWishlistItem(int releaseId, SyncStatus status) {
  final now = DateTime(2026, 1, 1);
  return WishlistItem(
    id: 'id-$releaseId',
    discogsReleaseId: releaseId,
    artist: 'Artist',
    title: 'Title',
    priority: WishlistPriority.medium,
    syncStatus: status,
    createdAt: now,
    updatedAt: now,
  );
}

class _ThrowingWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<void> add(WishlistItem item) async =>
      throw Exception('DB write failed');

  @override
  Future<bool> containsRelease(int id) async => false;

  @override
  Future<List<WishlistItem>> getAll() async => [];

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<void> update(WishlistItem item) async {}

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

WishlistImportPreview makePreview({
  int newCount = 0,
  int duplicateCount = 0,
  int invalidCount = 0,
  int conflictCount = 0,
}) {
  final rows = <WishlistImportRow>[
    for (int i = 0; i < newCount; i++)
      NewWishlistRow(
        releaseId: 100 + i,
        title: 'Album $i',
        artist: 'Artist $i',
        year: 2000 + i,
      ),
    for (int i = 0; i < duplicateCount; i++)
      DuplicateWishlistRow(
        releaseId: 200 + i,
        title: 'Dupe $i',
        artist: 'Artist',
      ),
    for (int i = 0; i < invalidCount; i++)
      InvalidWishlistRow(
        releaseId: 0,
        title: '',
        artist: 'Artist',
        reason: 'Missing title',
      ),
    for (int i = 0; i < conflictCount; i++)
      ConflictWishlistRow(
        releaseId: 300 + i,
        title: 'Pending $i',
        artist: 'Artist',
      ),
  ];
  return WishlistImportPreview(rows: rows);
}

({
  ExecuteWishlistImportUseCase useCase,
  _FakeWishlistRepository wishlistRepo,
  _FakeJobRepository jobRepo,
  _FakeRowResultRepository rowResultRepo,
})
makeUseCase({
  WishlistRepository? wishlistRepository,
  ImportExportJobRepository? jobRepository,
  ImportExportRowResultRepository? rowResultRepository,
}) {
  final wishlistRepo = _FakeWishlistRepository();
  final jobRepo = _FakeJobRepository();
  final rowResultRepo = _FakeRowResultRepository();
  return (
    useCase: ExecuteWishlistImportUseCase(
      wishlistRepository: wishlistRepository ?? wishlistRepo,
      jobRepository: jobRepository ?? jobRepo,
      rowResultRepository: rowResultRepository ?? rowResultRepo,
    ),
    wishlistRepo: wishlistRepo,
    jobRepo: jobRepo,
    rowResultRepo: rowResultRepo,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExecuteWishlistImportUseCase', () {
    group('empty preview', () {
      test(
        'returns ExecuteWishlistImportCompleted for empty preview',
        () async {
          final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
              makeUseCase();
          final result = await useCase.execute(makePreview());
          expect(result, isA<ExecuteWishlistImportCompleted>());
        },
      );

      test('imported is 0 for empty preview', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview())
                as ExecuteWishlistImportCompleted;
        expect(result.imported, 0);
      });

      test('skipped is 0 for empty preview', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview())
                as ExecuteWishlistImportCompleted;
        expect(result.skipped, 0);
      });

      test('failed is 0 for empty preview', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview())
                as ExecuteWishlistImportCompleted;
        expect(result.failed, 0);
      });
    });

    group('new items', () {
      test('saves new rows to wishlist', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(makePreview(newCount: 2));
        expect(wishlistRepo.added.length, 2);
      });

      test('saved item has correct artist', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(
          WishlistImportPreview(
            rows: [
              const NewWishlistRow(
                releaseId: 1,
                title: 'My Album',
                artist: 'My Artist',
              ),
            ],
          ),
        );
        expect(wishlistRepo.added.first.artist, 'My Artist');
      });

      test('saved item has correct title', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(
          WishlistImportPreview(
            rows: [
              const NewWishlistRow(
                releaseId: 1,
                title: 'My Album',
                artist: 'My Artist',
              ),
            ],
          ),
        );
        expect(wishlistRepo.added.first.title, 'My Album');
      });

      test('saved item has correct discogsReleaseId', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(
          WishlistImportPreview(
            rows: [
              const NewWishlistRow(releaseId: 42, title: 'T', artist: 'A'),
            ],
          ),
        );
        expect(wishlistRepo.added.first.discogsReleaseId, 42);
      });

      test('imported item has syncStatus synced', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(
          WishlistImportPreview(
            rows: [
              const NewWishlistRow(releaseId: 42, title: 'T', artist: 'A'),
            ],
          ),
        );
        expect(wishlistRepo.added.first.syncStatus, SyncStatus.synced);
      });

      test('saved item has medium priority by default', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(makePreview(newCount: 1));
        expect(wishlistRepo.added.first.priority, WishlistPriority.medium);
      });

      test('imported count matches new rows', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 3))
                as ExecuteWishlistImportCompleted;
        expect(result.imported, 3);
      });

      test('records ValidRow per imported item', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 2))
                as ExecuteWishlistImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<ValidRow>().length, 2);
      });

      test('ValidRow description contains artist and title', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(
                  WishlistImportPreview(
                    rows: [
                      const NewWishlistRow(
                        releaseId: 1,
                        title: 'Blue Lines',
                        artist: 'Massive Attack',
                      ),
                    ],
                  ),
                )
                as ExecuteWishlistImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        final valid = rows.whereType<ValidRow>().first;
        expect(valid.description, contains('Massive Attack'));
        expect(valid.description, contains('Blue Lines'));
      });
    });

    group('skip rules', () {
      test('duplicate row produces SkippedRow', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(duplicateCount: 1))
                as ExecuteWishlistImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<SkippedRow>().length, 1);
      });

      test(
        'duplicate row without existing local item produces SkippedRow',
        () async {
          final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
              makeUseCase();
          final result =
              await useCase.execute(makePreview(duplicateCount: 1))
                  as ExecuteWishlistImportCompleted;
          final rows = await rowResultRepo.getResults(result.jobId);
          final skipped = rows.whereType<SkippedRow>().first;
          expect(skipped.reason, 'Already linked to Discogs');
        },
      );

      test('invalid row produces SkippedRow', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(invalidCount: 1))
                as ExecuteWishlistImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<SkippedRow>().length, 1);
      });

      test('conflict row is skipped instead of re-imported (US-79)', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(conflictCount: 1))
                as ExecuteWishlistImportCompleted;
        expect(wishlistRepo.added, isEmpty);
        expect(result.imported, 0);
        expect(result.skipped, 1);
      });

      test('conflict row reason is the kept-off-Discogs message', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(conflictCount: 1))
                as ExecuteWishlistImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        final skipped = rows.whereType<SkippedRow>().first;
        expect(skipped.reason, 'Deleted locally — kept off Discogs');
      });

      test('skipped count = duplicates + invalids', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(
                  makePreview(duplicateCount: 2, invalidCount: 3),
                )
                as ExecuteWishlistImportCompleted;
        expect(result.skipped, 5);
      });

      test('duplicate rows are not added to wishlist', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        await useCase.execute(makePreview(duplicateCount: 2));
        expect(wishlistRepo.added, isEmpty);
      });

      test(
        'mixed preview produces correct imported and skipped counts',
        () async {
          final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
              makeUseCase();
          final result =
              await useCase.execute(
                    makePreview(
                      newCount: 3,
                      duplicateCount: 2,
                      invalidCount: 1,
                    ),
                  )
                  as ExecuteWishlistImportCompleted;
          expect(result.imported, 3);
          expect(result.skipped, 3);
          expect(result.failed, 0);
        },
      );
    });

    group('failed items', () {
      test('wishlist save failure produces FailedRow', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) = makeUseCase(
          wishlistRepository: _ThrowingWishlistRepository(),
        );
        final result =
            await useCase.execute(makePreview(newCount: 1))
                as ExecuteWishlistImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<FailedRow>().length, 1);
      });

      test('import continues after a failed row', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) = makeUseCase(
          wishlistRepository: _ThrowingWishlistRepository(),
        );
        final result =
            await useCase.execute(makePreview(newCount: 3))
                as ExecuteWishlistImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<FailedRow>().length, 3);
      });

      test('failed count is correct', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) = makeUseCase(
          wishlistRepository: _ThrowingWishlistRepository(),
        );
        final result =
            await useCase.execute(makePreview(newCount: 2))
                as ExecuteWishlistImportCompleted;
        expect(result.failed, 2);
      });
    });

    group('job record', () {
      test('creates job with running status initially', () async {
        ImportExportStatus? statusAtAdd;
        final capturingJobRepo = _CapturingJobRepository(
          onAdd: (job) => statusAtAdd = job.status,
        );
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) = makeUseCase(
          jobRepository: capturingJobRepo,
        );
        await useCase.execute(makePreview(newCount: 1));
        expect(statusAtAdd, ImportExportStatus.running);
      });

      test('updates job with completed status when all succeed', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 2))
                as ExecuteWishlistImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.status, ImportExportStatus.completed);
      });

      test('updates job with completedWithErrors when some fail', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) = makeUseCase(
          wishlistRepository: _ThrowingWishlistRepository(),
        );
        final result =
            await useCase.execute(makePreview(newCount: 1))
                as ExecuteWishlistImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.status, ImportExportStatus.completedWithErrors);
      });

      test('job has correct totalItems', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 2, duplicateCount: 1))
                as ExecuteWishlistImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.totalItems, 3);
      });

      test('job has correct validItems', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 4))
                as ExecuteWishlistImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.validItems, 4);
      });

      test('job has correct skippedItems', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(
                  makePreview(duplicateCount: 2, invalidCount: 1),
                )
                as ExecuteWishlistImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.skippedItems, 3);
      });

      test('result jobId is non-empty', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            makeUseCase();
        final result =
            await useCase.execute(makePreview(newCount: 1))
                as ExecuteWishlistImportCompleted;
        expect(result.jobId, isNotEmpty);
      });
    });

    group('duplicate linking', () {
      test(
        'links localOnly item to Discogs when duplicate row matches',
        () async {
          final existing = _makeWishlistItem(200, SyncStatus.localOnly);
          final spy = _SpyWishlistRepository(existing: [existing]);
          final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
              makeUseCase(wishlistRepository: spy);
          final preview = WishlistImportPreview(
            rows: [
              const DuplicateWishlistRow(
                releaseId: 200,
                title: 'Kind Of Blue',
                artist: 'Miles Davis',
              ),
            ],
          );
          final result =
              await useCase.execute(preview) as ExecuteWishlistImportCompleted;
          expect(spy.updated, hasLength(1));
          expect(spy.updated.first.syncStatus, SyncStatus.synced);
          expect(result.linked, 1);
        },
      );

      test('linked count is 0 when duplicate already synced', () async {
        final existing = _makeWishlistItem(200, SyncStatus.synced);
        final spy = _SpyWishlistRepository(existing: [existing]);
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) = makeUseCase(
          wishlistRepository: spy,
        );
        final result =
            await useCase.execute(makePreview(duplicateCount: 1))
                as ExecuteWishlistImportCompleted;
        expect(spy.updated, isEmpty);
        expect(result.linked, 0);
        expect(result.skipped, 1);
      });

      test('records ValidRow for linked item', () async {
        final existing = _makeWishlistItem(200, SyncStatus.localOnly);
        final spy = _SpyWishlistRepository(existing: [existing]);
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) = makeUseCase(
          wishlistRepository: spy,
        );
        final preview = WishlistImportPreview(
          rows: [
            const DuplicateWishlistRow(
              releaseId: 200,
              title: 'Kind Of Blue',
              artist: 'Miles Davis',
            ),
          ],
        );
        final result =
            await useCase.execute(preview) as ExecuteWishlistImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        final valid = rows.whereType<ValidRow>().first;
        expect(valid.description, contains('Miles Davis'));
        expect(valid.description, contains('Kind Of Blue'));
      });

      test('linked items count towards job validItems', () async {
        final existing = _makeWishlistItem(200, SyncStatus.localOnly);
        final spy = _SpyWishlistRepository(existing: [existing]);
        final jobRepo = _FakeJobRepository();
        final rowResultRepo = _FakeRowResultRepository();
        final useCase = ExecuteWishlistImportUseCase(
          wishlistRepository: spy,
          jobRepository: jobRepo,
          rowResultRepository: rowResultRepo,
          idGenerator: () => 'test-id',
        );
        final preview = WishlistImportPreview(
          rows: [
            const NewWishlistRow(releaseId: 100, title: 'T', artist: 'A'),
            const DuplicateWishlistRow(
              releaseId: 200,
              title: 'Kind Of Blue',
              artist: 'Miles Davis',
            ),
          ],
        );
        final result =
            await useCase.execute(preview) as ExecuteWishlistImportCompleted;
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

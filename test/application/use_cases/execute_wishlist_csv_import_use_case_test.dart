import 'package:cratewise/application/use_cases/execute_wishlist_csv_import_use_case.dart';
import 'package:cratewise/domain/models/csv_wishlist_import_preview.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  final List<WishlistItem> added = [];
  final Set<int> existingReleaseIds;

  _FakeWishlistRepository({Set<int>? existingReleaseIds})
      : existingReleaseIds = existingReleaseIds ?? {};

  @override
  Future<void> add(WishlistItem item) async => added.add(item);

  @override
  Future<bool> containsRelease(int id) async =>
      existingReleaseIds.contains(id);

  @override
  Future<List<WishlistItem>> getAll() async => [];

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _ThrowingWishlistRepository implements WishlistRepository {
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
  Future<List<ImportExportJob>> getRecent({int limit = 20}) async => jobs;

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

CsvWishlistImportRow _makeValidRow({
  int rowIndex = 0,
  int releaseId = 100,
  String artist = 'Test Artist',
  String title = 'Test Album',
  WishlistPriority priority = WishlistPriority.medium,
}) =>
    CsvWishlistImportRow(
      rowIndex: rowIndex,
      artist: artist,
      title: title,
      discogsReleaseId: releaseId,
      priority: priority,
    );

CsvWishlistImportPreview _makePreview({
  List<CsvWishlistImportRow>? validRows,
  List<SkippedRow>? skippedRows,
  List<FailedRow>? failedRows,
}) =>
    CsvWishlistImportPreview(
      validRows: validRows ?? [],
      skippedRows: skippedRows ?? [],
      failedRows: failedRows ?? [],
    );

({
  ExecuteWishlistCsvImportUseCase useCase,
  _FakeWishlistRepository wishlistRepo,
  _FakeJobRepository jobRepo,
  _FakeRowResultRepository rowResultRepo,
}) _makeUseCase({
  WishlistRepository? wishlistRepository,
  ImportExportJobRepository? jobRepository,
  ImportExportRowResultRepository? rowResultRepository,
}) {
  final wishlistRepo = _FakeWishlistRepository();
  final jobRepo = _FakeJobRepository();
  final rowResultRepo = _FakeRowResultRepository();
  return (
    useCase: ExecuteWishlistCsvImportUseCase(
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
  group('ExecuteWishlistCsvImportUseCase', () {
    group('empty preview', () {
      test('returns ExecuteWishlistCsvImportCompleted for empty preview',
          () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(_makePreview());
        expect(result, isA<ExecuteWishlistCsvImportCompleted>());
      });

      test('imported is 0 for empty preview', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(_makePreview())
            as ExecuteWishlistCsvImportCompleted;
        expect(result.imported, 0);
      });

      test('skipped is 0 for empty preview', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(_makePreview())
            as ExecuteWishlistCsvImportCompleted;
        expect(result.skipped, 0);
      });

      test('failed is 0 for empty preview', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(_makePreview())
            as ExecuteWishlistCsvImportCompleted;
        expect(result.failed, 0);
      });
    });

    group('valid rows — new items', () {
      test('saves valid row to wishlist', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(_makePreview(validRows: [_makeValidRow()]));
        expect(wishlistRepo.added.length, 1);
      });

      test('saved item has correct artist', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(
            validRows: [_makeValidRow(artist: 'Boards of Canada')],
          ),
        );
        expect(wishlistRepo.added.first.artist, 'Boards of Canada');
      });

      test('saved item has correct title', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(
            validRows: [_makeValidRow(title: 'Music Has the Right to Children')],
          ),
        );
        expect(wishlistRepo.added.first.title,
            'Music Has the Right to Children');
      });

      test('saved item has correct discogsReleaseId', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(validRows: [_makeValidRow(releaseId: 77)]),
        );
        expect(wishlistRepo.added.first.discogsReleaseId, 77);
      });

      test('saved item preserves priority', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(
            validRows: [
              _makeValidRow(priority: WishlistPriority.mustHave),
            ],
          ),
        );
        expect(wishlistRepo.added.first.priority, WishlistPriority.mustHave);
      });

      test('saved item preserves targetPrice', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        await useCase.execute(
          _makePreview(
            validRows: [
              CsvWishlistImportRow(
                rowIndex: 0,
                artist: 'A',
                title: 'T',
                discogsReleaseId: 1,
                priority: WishlistPriority.medium,
                targetPrice: 19.99,
              ),
            ],
          ),
        );
        expect(wishlistRepo.added.first.targetPrice, 19.99);
      });

      test('imported count matches number of new rows', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(
          _makePreview(
            validRows: [
              _makeValidRow(rowIndex: 0, releaseId: 1),
              _makeValidRow(rowIndex: 1, releaseId: 2),
            ],
          ),
        ) as ExecuteWishlistCsvImportCompleted;
        expect(result.imported, 2);
      });
    });

    group('valid rows — DB duplicates', () {
      test('skips row already in wishlist', () async {
        final wishlistRepo =
            _FakeWishlistRepository(existingReleaseIds: {55});
        final (:useCase, wishlistRepo: _, :jobRepo, :rowResultRepo) =
            _makeUseCase(wishlistRepository: wishlistRepo);
        await useCase.execute(
          _makePreview(validRows: [_makeValidRow(releaseId: 55)]),
        );
        expect(wishlistRepo.added, isEmpty);
      });

      test('DB-duplicate row is counted as skipped', () async {
        final wishlistRepo =
            _FakeWishlistRepository(existingReleaseIds: {55});
        final (:useCase, wishlistRepo: _, :jobRepo, :rowResultRepo) =
            _makeUseCase(wishlistRepository: wishlistRepo);
        final result = await useCase.execute(
          _makePreview(validRows: [_makeValidRow(releaseId: 55)]),
        ) as ExecuteWishlistCsvImportCompleted;
        expect(result.skipped, 1);
        expect(result.imported, 0);
      });

      test('SkippedRow reason is Already in wishlist', () async {
        final wishlistRepo =
            _FakeWishlistRepository(existingReleaseIds: {55});
        final (:useCase, wishlistRepo: _, :jobRepo, :rowResultRepo) =
            _makeUseCase(wishlistRepository: wishlistRepo);
        final result = await useCase.execute(
          _makePreview(validRows: [_makeValidRow(releaseId: 55)]),
        ) as ExecuteWishlistCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<SkippedRow>().first.reason, 'Already in wishlist');
      });
    });

    group('preview skipped rows', () {
      test('preview skipped rows contribute to skipped count', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(
          _makePreview(
            skippedRows: [
              const SkippedRow(rowIndex: 1, reason: 'Duplicate release ID in file'),
              const SkippedRow(rowIndex: 2, reason: 'Duplicate release ID in file'),
            ],
          ),
        ) as ExecuteWishlistCsvImportCompleted;
        expect(result.skipped, 2);
      });
    });

    group('preview failed rows', () {
      test('preview failed rows contribute to failed count', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(
          _makePreview(
            failedRows: [
              const FailedRow(rowIndex: 0, safeErrorMessage: 'Missing artist'),
            ],
          ),
        ) as ExecuteWishlistCsvImportCompleted;
        expect(result.failed, 1);
      });
    });

    group('save failure', () {
      test('save failure produces FailedRow', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase(
          wishlistRepository: _ThrowingWishlistRepository(),
        );
        final result = await useCase.execute(
          _makePreview(validRows: [_makeValidRow()]),
        ) as ExecuteWishlistCsvImportCompleted;
        final rows = await rowResultRepo.getResults(result.jobId);
        expect(rows.whereType<FailedRow>().length, 1);
      });

      test('save failure counts toward failed', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase(
          wishlistRepository: _ThrowingWishlistRepository(),
        );
        final result = await useCase.execute(
          _makePreview(validRows: [_makeValidRow()]),
        ) as ExecuteWishlistCsvImportCompleted;
        expect(result.failed, 1);
        expect(result.imported, 0);
      });
    });

    group('job record', () {
      test('job type is csvWishlistImport', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(
          _makePreview(validRows: [_makeValidRow()]),
        ) as ExecuteWishlistCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.jobType, ImportExportJobType.csvWishlistImport);
      });

      test('job source is CSV file', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(_makePreview())
            as ExecuteWishlistCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.source, 'CSV file');
      });

      test('job target is Local wishlist', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(_makePreview())
            as ExecuteWishlistCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.target, 'Local wishlist');
      });

      test('updates job with completed status when all succeed', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(
          _makePreview(validRows: [_makeValidRow()]),
        ) as ExecuteWishlistCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.status, ImportExportStatus.completed);
      });

      test('updates job with completedWithErrors when some fail', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase(
          wishlistRepository: _ThrowingWishlistRepository(),
        );
        final result = await useCase.execute(
          _makePreview(validRows: [_makeValidRow()]),
        ) as ExecuteWishlistCsvImportCompleted;
        final job = await jobRepo.getById(result.jobId);
        expect(job?.status, ImportExportStatus.completedWithErrors);
      });

      test('result jobId is non-empty', () async {
        final (:useCase, :wishlistRepo, :jobRepo, :rowResultRepo) =
            _makeUseCase();
        final result = await useCase.execute(
          _makePreview(validRows: [_makeValidRow()]),
        ) as ExecuteWishlistCsvImportCompleted;
        expect(result.jobId, isNotEmpty);
      });
    });
  });
}

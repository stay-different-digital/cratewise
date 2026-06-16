import 'package:cratewise/application/use_cases/execute_collection_import_use_case.dart';
import 'package:cratewise/application/use_cases/execute_wishlist_import_use_case.dart';
import 'package:cratewise/domain/models/collection_import_preview.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/wishlist_import_preview.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/transaction_runner.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Transaction spy
// ---------------------------------------------------------------------------

/// Records that exactly one transaction wrapped the import, and flags any
/// repository write that happened outside it (repos check [active]).
class _TransactionSpy implements TransactionRunner {
  int runCallCount = 0;
  bool active = false;
  int writesOutsideTransaction = 0;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    runCallCount++;
    active = true;
    try {
      return await action();
    } finally {
      active = false;
    }
  }

  void noteWrite() {
    if (!active) writesOutsideTransaction++;
  }
}

/// A runner that fails the transaction (simulating a commit/interrupt
/// failure): the action never runs, so nothing is persisted.
class _FailingTransactionRunner implements TransactionRunner {
  @override
  Future<T> run<T>(Future<T> Function() action) async =>
      throw Exception('transaction failed');
}

// ---------------------------------------------------------------------------
// Collection fakes
// ---------------------------------------------------------------------------

class _SpyCollectionRepo implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _SpyCollectionRepo(this.spy);
  final _TransactionSpy spy;
  final List<CollectionItem> added = [];

  @override
  Future<void> add(CollectionItem item) async {
    spy.noteWrite();
    added.add(item);
  }

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

class _SpyWishlistRepo implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _SpyWishlistRepo(this.spy);
  final _TransactionSpy spy;
  final List<WishlistItem> added = [];

  @override
  Future<void> add(WishlistItem item) async {
    spy.noteWrite();
    added.add(item);
  }

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

class _FakeJobRepo implements ImportExportJobRepository {
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
  Future<int> count() async => jobs.length;
  @override
  Future<void> remove(String id) async => jobs.removeWhere((j) => j.id == id);
}

class _FakeRowResultRepo implements ImportExportRowResultRepository {
  final List<ImportExportRowResult> results = [];

  @override
  Future<void> addResult(String jobId, ImportExportRowResult result) async =>
      results.add(result);
  @override
  Future<List<ImportExportRowResult>> getResults(String jobId) async => results;
  @override
  Future<void> removeAllForJob(String jobId) async => results.clear();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionImportPreview _collectionPreview(int n) => CollectionImportPreview(
  rows: [
    for (var i = 0; i < n; i++)
      NewCollectionRow(
        releaseId: 100 + i,
        title: 'Album $i',
        artist: 'Artist $i',
      ),
  ],
);

WishlistImportPreview _wishlistPreview(int n) => WishlistImportPreview(
  rows: [
    for (var i = 0; i < n; i++)
      NewWishlistRow(
        releaseId: 100 + i,
        title: 'Album $i',
        artist: 'Artist $i',
      ),
  ],
);

int _counter = 0;
String _seqId() => 'id-${_counter++}';

void main() {
  setUp(() => _counter = 0);

  group('Collection import — transaction batching (US-73)', () {
    test('wraps all writes in a single transaction', () async {
      final spy = _TransactionSpy();
      final repo = _SpyCollectionRepo(spy);
      final useCase = ExecuteCollectionImportUseCase(
        collectionRepository: repo,
        jobRepository: _FakeJobRepo(),
        rowResultRepository: _FakeRowResultRepo(),
        transactionRunner: spy,
        idGenerator: _seqId,
      );

      await useCase.execute(_collectionPreview(2800));

      expect(spy.runCallCount, 1);
      expect(spy.writesOutsideTransaction, 0);
      expect(repo.added.length, 2800);
    });

    test('reports per-item progress for every row', () async {
      final useCase = ExecuteCollectionImportUseCase(
        collectionRepository: _SpyCollectionRepo(_TransactionSpy()),
        jobRepository: _FakeJobRepo(),
        rowResultRepository: _FakeRowResultRepo(),
        idGenerator: _seqId,
      );

      final progress = <(int, int)>[];
      await useCase.execute(
        _collectionPreview(3),
        onProgress: (current, total, _) => progress.add((current, total)),
      );

      expect(progress, [(1, 3), (2, 3), (3, 3)]);
    });

    test('a failed transaction persists nothing and reports failure', () async {
      final repo = _SpyCollectionRepo(_TransactionSpy());
      final jobRepo = _FakeJobRepo();
      final useCase = ExecuteCollectionImportUseCase(
        collectionRepository: repo,
        jobRepository: jobRepo,
        rowResultRepository: _FakeRowResultRepo(),
        transactionRunner: _FailingTransactionRunner(),
        idGenerator: _seqId,
      );

      final result = await useCase.execute(_collectionPreview(10));

      expect(result, isA<ExecuteImportFailed>());
      expect(repo.added, isEmpty);
      expect(jobRepo.jobs.single.status.name, 'failed');
    });
  });

  group('Wishlist import — transaction batching (US-73)', () {
    test('wraps all writes in a single transaction', () async {
      final spy = _TransactionSpy();
      final repo = _SpyWishlistRepo(spy);
      final useCase = ExecuteWishlistImportUseCase(
        wishlistRepository: repo,
        jobRepository: _FakeJobRepo(),
        rowResultRepository: _FakeRowResultRepo(),
        transactionRunner: spy,
        idGenerator: _seqId,
      );

      await useCase.execute(_wishlistPreview(2800));

      expect(spy.runCallCount, 1);
      expect(spy.writesOutsideTransaction, 0);
      expect(repo.added.length, 2800);
    });

    test('reports per-item progress for every row', () async {
      final useCase = ExecuteWishlistImportUseCase(
        wishlistRepository: _SpyWishlistRepo(_TransactionSpy()),
        jobRepository: _FakeJobRepo(),
        rowResultRepository: _FakeRowResultRepo(),
        idGenerator: _seqId,
      );

      final progress = <(int, int)>[];
      await useCase.execute(
        _wishlistPreview(3),
        onProgress: (current, total, _) => progress.add((current, total)),
      );

      expect(progress, [(1, 3), (2, 3), (3, 3)]);
    });

    test('a failed transaction persists nothing and reports failure', () async {
      final repo = _SpyWishlistRepo(_TransactionSpy());
      final jobRepo = _FakeJobRepo();
      final useCase = ExecuteWishlistImportUseCase(
        wishlistRepository: repo,
        jobRepository: jobRepo,
        rowResultRepository: _FakeRowResultRepo(),
        transactionRunner: _FailingTransactionRunner(),
        idGenerator: _seqId,
      );

      final result = await useCase.execute(_wishlistPreview(10));

      expect(result, isA<ExecuteWishlistImportFailed>());
      expect(repo.added, isEmpty);
      expect(jobRepo.jobs.single.status.name, 'failed');
    });
  });
}

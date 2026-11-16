import 'package:cratewise/application/services/discogs_auto_sync_service.dart';
import 'package:cratewise/application/use_cases/run_discogs_auto_sync_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Auto-sync with a scripted outcome per release id; records what was sent.
class _ScriptedSync extends DiscogsAutoSyncService {
  bool enabled = true;
  final outcome = <int, SyncStatus?>{};
  final sent = <int>[];

  // A key set to null means "nothing was sent" (auto-sync turned off).
  SyncStatus? _outcomeFor(int id) =>
      outcome.containsKey(id) ? outcome[id] : SyncStatus.synced;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<SyncStatus?> pushCollectionItem(
    CollectionItem item,
    CollectionRepository repository,
  ) async {
    sent.add(item.discogsReleaseId);
    return _outcomeFor(item.discogsReleaseId);
  }

  @override
  Future<SyncStatus?> pushWishlistItem(
    WishlistItem item,
    WishlistRepository repository,
  ) async {
    sent.add(item.discogsReleaseId);
    return _outcomeFor(item.discogsReleaseId);
  }
}

class _Collection implements CollectionRepository {
  _Collection(this.items);
  final List<CollectionItem> items;
  @override
  Future<List<CollectionItem>> getAll() async => items;
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> deleteAll() async {}
}

class _Wishlist implements WishlistRepository {
  _Wishlist(this.items);
  final List<WishlistItem> items;
  @override
  Future<List<WishlistItem>> getAll() async => items;
  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> deleteAll() async {}
}

class _Jobs implements ImportExportJobRepository {
  final jobs = <String, ImportExportJob>{};
  @override
  Future<void> add(ImportExportJob job) async => jobs[job.id] = job;
  @override
  Future<void> update(ImportExportJob job) async => jobs[job.id] = job;
  @override
  Future<ImportExportJob?> getById(String id) async => jobs[id];
  @override
  Future<List<ImportExportJob>> getRecent({
    int limit = 20,
    int offset = 0,
  }) async =>
      (jobs.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .take(limit)
          .toList();
  @override
  Future<int> count() async => jobs.length;
  @override
  Future<void> remove(String id) async => jobs.remove(id);
}

class _Rows implements ImportExportRowResultRepository {
  final rows = <String, List<ImportExportRowResult>>{};
  @override
  Future<void> addResult(String jobId, ImportExportRowResult result) async =>
      (rows[jobId] ??= []).add(result);
  @override
  Future<List<ImportExportRowResult>> getResults(String jobId) async =>
      rows[jobId] ?? [];
  @override
  Future<void> removeAllForJob(String jobId) async => rows.remove(jobId);
}

CollectionItem _c(int releaseId, SyncStatus status) => CollectionItem(
  id: 'c$releaseId',
  discogsReleaseId: releaseId,
  artist: 'Artist $releaseId',
  title: 'Title',
  mediaCondition: RecordCondition.veryGood,
  sleeveCondition: RecordCondition.veryGood,
  tags: const [],
  syncStatus: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

WishlistItem _w(int releaseId, SyncStatus status) => WishlistItem(
  id: 'w$releaseId',
  discogsReleaseId: releaseId,
  artist: 'Artist $releaseId',
  title: 'Title',
  priority: WishlistPriority.medium,
  syncStatus: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _ScriptedSync sync;
  late _Jobs jobs;
  late _Rows rows;
  late DateTime now;

  RunDiscogsAutoSyncUseCase useCase({
    List<CollectionItem> collection = const [],
    List<WishlistItem> wishlist = const [],
  }) => RunDiscogsAutoSyncUseCase(
    autoSync: sync,
    collection: _Collection(collection),
    wishlist: _Wishlist(wishlist),
    jobs: jobs,
    rowResults: rows,
    clock: () => now,
  );

  setUp(() {
    sync = _ScriptedSync();
    jobs = _Jobs();
    rows = _Rows();
    now = DateTime(2026, 11, 16, 12);
  });

  test('sends only items that are not on Discogs yet', () async {
    final result = await useCase(
      collection: [
        _c(1, SyncStatus.localOnly),
        _c(2, SyncStatus.synced),
        _c(3, SyncStatus.failed),
        _c(4, SyncStatus.pending),
      ],
      wishlist: [_w(5, SyncStatus.offline), _w(6, SyncStatus.synced)],
    ).run();

    expect(sync.sent, [1, 3, 5]);
    expect(result!.sent, 3);
  });

  test('one failure does not stop the rest; history lists each item', () async {
    sync.outcome[1] = SyncStatus.failed;
    sync.outcome[2] = SyncStatus.offline;
    final result = await useCase(
      collection: [
        _c(1, SyncStatus.localOnly),
        _c(2, SyncStatus.localOnly),
        _c(3, SyncStatus.localOnly),
      ],
    ).run();

    expect(sync.sent, [1, 2, 3]);
    expect((result!.sent, result.failed), (1, 2));
    final job = jobs.jobs.values.single;
    expect(job.jobType, ImportExportJobType.autoSyncWithDiscogs);
    expect(job.status, ImportExportStatus.completedWithErrors);
    expect((job.validItems, job.failedItems), (1, 2));
    final results = rows.rows[job.id]!;
    expect(results.whereType<FailedRow>(), hasLength(2));
    expect(
      results.whereType<FailedRow>().first.safeErrorMessage,
      contains('Artist 1'),
    );
  });

  test('off → nothing sent, no history', () async {
    sync.enabled = false;
    final result = await useCase(
      collection: [_c(1, SyncStatus.localOnly)],
    ).run();
    expect(result, isNull);
    expect(sync.sent, isEmpty);
    expect(jobs.jobs, isEmpty);
  });

  test('at most once per 15 minutes; force bypasses the limit', () async {
    final uc = useCase(collection: [_c(1, SyncStatus.localOnly)]);
    expect(await uc.run(), isNotNull);

    now = now.add(const Duration(minutes: 14));
    expect(await uc.run(), isNull);
    expect(await uc.run(force: true), isNotNull);

    now = now.add(const Duration(minutes: 15));
    expect(await uc.run(), isNotNull);
    expect(sync.sent, [1, 1, 1]);
  });

  test('does not start while a manual import or export runs', () async {
    await jobs.add(
      ImportExportJob(
        id: 'manual',
        jobType: ImportExportJobType.importCollectionFromDiscogs,
        source: 'Discogs',
        target: 'Local collection',
        status: ImportExportStatus.running,
        createdAt: now,
        updatedAt: now.subtract(const Duration(minutes: 2)),
      ),
    );
    final uc = useCase(collection: [_c(1, SyncStatus.localOnly)]);
    expect(await uc.run(), isNull);
    expect(sync.sent, isEmpty);
  });

  test(
    'a manual job stuck as running for 30+ minutes no longer blocks',
    () async {
      await jobs.add(
        ImportExportJob(
          id: 'stale',
          jobType: ImportExportJobType.exportCollectionToDiscogs,
          source: 'Local collection',
          target: 'Discogs',
          status: ImportExportStatus.running,
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
      );
      expect(
        await useCase(collection: [_c(1, SyncStatus.localOnly)]).run(),
        isNotNull,
      );
    },
  );

  test('stops when auto-sync switches itself off mid-run', () async {
    sync.outcome[1] = null; // e.g. token rejected on the first item
    await useCase(
      collection: [_c(1, SyncStatus.localOnly), _c(2, SyncStatus.localOnly)],
      wishlist: [_w(3, SyncStatus.localOnly)],
    ).run();

    expect(sync.sent, [1]);
    expect(jobs.jobs.values.single.status, ImportExportStatus.failed);
  });

  test('nothing to send → no history entry', () async {
    final result = await useCase(collection: [_c(1, SyncStatus.synced)]).run();
    expect((result!.sent, result.failed), (0, 0));
    expect(jobs.jobs, isEmpty);
  });

  test(
    'countUnsent counts collection and wishlist items not on Discogs',
    () async {
      final count = await RunDiscogsAutoSyncUseCase.countUnsent(
        _Collection([_c(1, SyncStatus.localOnly), _c(2, SyncStatus.synced)]),
        _Wishlist([_w(3, SyncStatus.failed)]),
      );
      expect(count, 2);
    },
  );
}

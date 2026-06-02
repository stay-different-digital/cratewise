import 'package:cratewise/application/use_cases/build_collection_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/check_collection_export_capability_use_case.dart';
import 'package:cratewise/domain/models/collection_export_preview.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  _FakeCollectionRepository(this._items);

  final List<CollectionItem> _items;

  @override
  Future<List<CollectionItem>> getAll() async => _items;

  @override
  Future<CollectionItem?> getById(String id) async => null;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;

  @override
  Future<void> add(CollectionItem item) async {}

  @override
  Future<void> update(CollectionItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _ThrowingCollectionRepository implements CollectionRepository {
  @override
  Future<List<CollectionItem>> getAll() async =>
      throw Exception('DB error');

  @override
  Future<CollectionItem?> getById(String id) async => null;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;

  @override
  Future<void> add(CollectionItem item) async {}

  @override
  Future<void> update(CollectionItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

/// Always returns [CollectionExportNotSupported].
class _NotSupportedCapabilityUseCase
    extends CheckCollectionExportCapabilityUseCase {
  const _NotSupportedCapabilityUseCase();

  @override
  CheckCollectionExportCapabilityResult execute() =>
      const CollectionExportNotSupported('Not supported right now.');
}

/// Always returns [CollectionExportSupported].
class _SupportedCapabilityUseCase
    extends CheckCollectionExportCapabilityUseCase {
  const _SupportedCapabilityUseCase();

  @override
  CheckCollectionExportCapabilityResult execute() =>
      const CollectionExportSupported();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem makeItem({
  String id = 'item-1',
  int releaseId = 12345,
  String artist = 'Artist',
  String title = 'Album',
  int? year = 2000,
  SyncStatus syncStatus = SyncStatus.localOnly,
}) {
  final now = DateTime(2024);
  return CollectionItem(
    id: id,
    discogsReleaseId: releaseId,
    artist: artist,
    title: title,
    year: year,
    mediaCondition: RecordCondition.notSet,
    sleeveCondition: RecordCondition.notSet,
    tags: const [],
    createdAt: now,
    updatedAt: now,
    syncStatus: syncStatus,
  );
}

BuildCollectionExportPreviewUseCase makeUseCase({
  List<CollectionItem> items = const [],
  CheckCollectionExportCapabilityUseCase? capabilityUseCase,
  CollectionRepository? repository,
}) {
  return BuildCollectionExportPreviewUseCase(
    repository: repository ?? _FakeCollectionRepository(items),
    capabilityUseCase:
        capabilityUseCase ?? const _SupportedCapabilityUseCase(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BuildCollectionExportPreviewUseCase', () {
    group('capability not supported', () {
      test('returns CollectionExportPreviewNotSupported', () async {
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        final result = await uc.execute();
        expect(result, isA<CollectionExportPreviewNotSupported>());
      });

      test('not supported result forwards the capability reason', () async {
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        final result =
            await uc.execute() as CollectionExportPreviewNotSupported;
        expect(result.reason, 'Not supported right now.');
      });

      test('does not call repository when not supported', () async {
        var repositoryCalled = false;
        final repo = _FakeCollectionRepository([]);
        // Wrap to detect calls
        final uc = BuildCollectionExportPreviewUseCase(
          repository: _SpyCollectionRepository(
            repo,
            onGetAll: () => repositoryCalled = true,
          ),
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        await uc.execute();
        expect(repositoryCalled, isFalse);
      });
    });

    group('capability supported — empty collection', () {
      test('returns CollectionExportPreviewReady', () async {
        final result = await makeUseCase().execute();
        expect(result, isA<CollectionExportPreviewReady>());
      });

      test('preview has zero rows', () async {
        final result =
            await makeUseCase().execute() as CollectionExportPreviewReady;
        expect(result.preview.totalCount, 0);
      });

      test('all counts are zero', () async {
        final result =
            await makeUseCase().execute() as CollectionExportPreviewReady;
        expect(result.preview.eligibleCount, 0);
        expect(result.preview.alreadySyncedCount, 0);
        expect(result.preview.invalidCount, 0);
      });
    });

    group('eligible rows', () {
      test('item with valid releaseId and localOnly status is eligible',
          () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 1, syncStatus: SyncStatus.localOnly)],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.rows.first, isA<EligibleExportRow>());
      });

      test('item with valid releaseId and pending status is eligible',
          () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 1, syncStatus: SyncStatus.pending)],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.rows.first, isA<EligibleExportRow>());
      });

      test('item with valid releaseId and failed status is eligible', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 1, syncStatus: SyncStatus.failed)],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.rows.first, isA<EligibleExportRow>());
      });

      test('eligible row carries correct artist', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 1, artist: 'Talk Talk')],
        ).execute() as CollectionExportPreviewReady;
        final row = result.preview.rows.first as EligibleExportRow;
        expect(row.artist, 'Talk Talk');
      });

      test('eligible row carries correct title', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 1, title: 'Spirit of Eden')],
        ).execute() as CollectionExportPreviewReady;
        final row = result.preview.rows.first as EligibleExportRow;
        expect(row.title, 'Spirit of Eden');
      });

      test('eligible row carries correct releaseId', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 42)],
        ).execute() as CollectionExportPreviewReady;
        final row = result.preview.rows.first as EligibleExportRow;
        expect(row.releaseId, 42);
      });

      test('eligible row carries correct itemId', () async {
        final result = await makeUseCase(
          items: [makeItem(id: 'abc-123', releaseId: 1)],
        ).execute() as CollectionExportPreviewReady;
        final row = result.preview.rows.first as EligibleExportRow;
        expect(row.itemId, 'abc-123');
      });

      test('eligibleCount matches number of eligible items', () async {
        final result = await makeUseCase(
          items: [
            makeItem(id: 'a', releaseId: 1),
            makeItem(id: 'b', releaseId: 2),
            makeItem(id: 'c', releaseId: 3),
          ],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.eligibleCount, 3);
      });
    });

    group('already synced rows', () {
      test('item with synced status produces AlreadySyncedExportRow', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 1, syncStatus: SyncStatus.synced)],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.rows.first, isA<AlreadySyncedExportRow>());
      });

      test('alreadySyncedCount is correct', () async {
        final result = await makeUseCase(
          items: [
            makeItem(id: 'a', releaseId: 1, syncStatus: SyncStatus.synced),
            makeItem(id: 'b', releaseId: 2, syncStatus: SyncStatus.synced),
          ],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.alreadySyncedCount, 2);
      });

      test('already synced row carries correct releaseId', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 99, syncStatus: SyncStatus.synced)],
        ).execute() as CollectionExportPreviewReady;
        final row = result.preview.rows.first as AlreadySyncedExportRow;
        expect(row.releaseId, 99);
      });
    });

    group('invalid rows', () {
      test('item with releaseId 0 produces InvalidExportRow', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 0)],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.rows.first, isA<InvalidExportRow>());
      });

      test('item with negative releaseId produces InvalidExportRow', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: -1)],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.rows.first, isA<InvalidExportRow>());
      });

      test('invalid row has non-empty reason', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 0)],
        ).execute() as CollectionExportPreviewReady;
        final row = result.preview.rows.first as InvalidExportRow;
        expect(row.reason, isNotEmpty);
      });

      test('invalid row reason does not contain token or secret', () async {
        final result = await makeUseCase(
          items: [makeItem(releaseId: 0)],
        ).execute() as CollectionExportPreviewReady;
        final row = result.preview.rows.first as InvalidExportRow;
        expect(row.reason.toLowerCase(), isNot(contains('token')));
        expect(row.reason.toLowerCase(), isNot(contains('secret')));
      });

      test('invalidCount is correct', () async {
        final result = await makeUseCase(
          items: [
            makeItem(id: 'a', releaseId: 0),
            makeItem(id: 'b', releaseId: 0),
          ],
        ).execute() as CollectionExportPreviewReady;
        expect(result.preview.invalidCount, 2);
      });
    });

    group('mixed collection', () {
      test('mixed items produce correct counts', () async {
        final result = await makeUseCase(
          items: [
            makeItem(id: 'a', releaseId: 1, syncStatus: SyncStatus.localOnly),
            makeItem(id: 'b', releaseId: 2, syncStatus: SyncStatus.localOnly),
            makeItem(id: 'c', releaseId: 3, syncStatus: SyncStatus.synced),
            makeItem(id: 'd', releaseId: 0),
          ],
        ).execute() as CollectionExportPreviewReady;
        final p = result.preview;
        expect(p.totalCount, 4);
        expect(p.eligibleCount, 2);
        expect(p.alreadySyncedCount, 1);
        expect(p.invalidCount, 1);
      });
    });

    group('repository error', () {
      test('returns CollectionExportPreviewError on repository exception',
          () async {
        final uc = BuildCollectionExportPreviewUseCase(
          repository: _ThrowingCollectionRepository(),
          capabilityUseCase: const _SupportedCapabilityUseCase(),
        );
        final result = await uc.execute();
        expect(result, isA<CollectionExportPreviewError>());
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Spy helper
// ---------------------------------------------------------------------------

class _SpyCollectionRepository implements CollectionRepository {
  _SpyCollectionRepository(this._delegate, {required this.onGetAll});

  final CollectionRepository _delegate;
  final void Function() onGetAll;

  @override
  Future<List<CollectionItem>> getAll() async {
    onGetAll();
    return _delegate.getAll();
  }

  @override
  Future<CollectionItem?> getById(String id) => _delegate.getById(id);

  @override
  Future<bool> containsRelease(int id) => _delegate.containsRelease(id);

  @override
  Future<void> add(CollectionItem item) => _delegate.add(item);

  @override
  Future<void> update(CollectionItem item) => _delegate.update(item);

  @override
  Future<void> remove(String id) => _delegate.remove(id);
}

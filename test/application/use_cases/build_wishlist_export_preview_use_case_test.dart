import 'package:cratewise/application/use_cases/build_wishlist_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/check_wishlist_export_capability_use_case.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_export_preview.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeWishlistRepository(this._items);

  final List<WishlistItem> _items;

  @override
  Future<List<WishlistItem>> getAll() async => _items;

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;

  @override
  Future<void> add(WishlistItem item) async {}

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _ThrowingWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<WishlistItem>> getAll() async => throw Exception('DB error');

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;

  @override
  Future<void> add(WishlistItem item) async {}

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

/// Always returns [WishlistExportNotSupported].
class _NotSupportedCapabilityUseCase
    extends CheckWishlistExportCapabilityUseCase {
  const _NotSupportedCapabilityUseCase();

  @override
  CheckWishlistExportCapabilityResult execute() =>
      const WishlistExportNotSupported('Not supported right now.');
}

/// Always returns [WishlistExportSupported].
class _SupportedCapabilityUseCase extends CheckWishlistExportCapabilityUseCase {
  const _SupportedCapabilityUseCase();

  @override
  CheckWishlistExportCapabilityResult execute() =>
      const WishlistExportSupported();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WishlistItem makeItem({
  String id = 'item-1',
  int releaseId = 12345,
  String artist = 'Artist',
  String title = 'Album',
  int? year = 2000,
  SyncStatus syncStatus = SyncStatus.localOnly,
}) {
  final now = DateTime(2024);
  return WishlistItem(
    id: id,
    discogsReleaseId: releaseId,
    artist: artist,
    title: title,
    year: year,
    priority: WishlistPriority.medium,
    createdAt: now,
    updatedAt: now,
    syncStatus: syncStatus,
  );
}

BuildWishlistExportPreviewUseCase makeUseCase({
  List<WishlistItem> items = const [],
  CheckWishlistExportCapabilityUseCase? capabilityUseCase,
  WishlistRepository? repository,
}) {
  return BuildWishlistExportPreviewUseCase(
    repository: repository ?? _FakeWishlistRepository(items),
    capabilityUseCase: capabilityUseCase ?? const _SupportedCapabilityUseCase(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BuildWishlistExportPreviewUseCase', () {
    group('capability not supported', () {
      test('returns WishlistExportPreviewNotSupported', () async {
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        final result = await uc.execute();
        expect(result, isA<WishlistExportPreviewNotSupported>());
      });

      test('not supported result forwards the capability reason', () async {
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        final result = await uc.execute() as WishlistExportPreviewNotSupported;
        expect(result.reason, 'Not supported right now.');
      });

      test('does not call repository when not supported', () async {
        var repositoryCalled = false;
        final uc = BuildWishlistExportPreviewUseCase(
          repository: _SpyWishlistRepository(
            _FakeWishlistRepository([]),
            onGetAll: () => repositoryCalled = true,
          ),
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        await uc.execute();
        expect(repositoryCalled, isFalse);
      });
    });

    group('capability supported — empty wishlist', () {
      test('returns WishlistExportPreviewReady', () async {
        final result = await makeUseCase().execute();
        expect(result, isA<WishlistExportPreviewReady>());
      });

      test('preview has zero rows', () async {
        final result =
            await makeUseCase().execute() as WishlistExportPreviewReady;
        expect(result.preview.totalCount, 0);
      });

      test('all counts are zero', () async {
        final result =
            await makeUseCase().execute() as WishlistExportPreviewReady;
        expect(result.preview.eligibleCount, 0);
        expect(result.preview.alreadySyncedCount, 0);
        expect(result.preview.invalidCount, 0);
      });
    });

    group('eligible rows', () {
      test(
        'item with valid releaseId and localOnly status is eligible',
        () async {
          final result =
              await makeUseCase(
                    items: [
                      makeItem(releaseId: 1, syncStatus: SyncStatus.localOnly),
                    ],
                  ).execute()
                  as WishlistExportPreviewReady;
          expect(result.preview.rows.first, isA<EligibleWishlistExportRow>());
        },
      );

      test(
        'item with valid releaseId and pending status is eligible',
        () async {
          final result =
              await makeUseCase(
                    items: [
                      makeItem(releaseId: 1, syncStatus: SyncStatus.pending),
                    ],
                  ).execute()
                  as WishlistExportPreviewReady;
          expect(result.preview.rows.first, isA<EligibleWishlistExportRow>());
        },
      );

      test('item with valid releaseId and failed status is eligible', () async {
        final result =
            await makeUseCase(
                  items: [
                    makeItem(releaseId: 1, syncStatus: SyncStatus.failed),
                  ],
                ).execute()
                as WishlistExportPreviewReady;
        expect(result.preview.rows.first, isA<EligibleWishlistExportRow>());
      });

      test('eligible row carries correct artist', () async {
        final result =
            await makeUseCase(
                  items: [makeItem(releaseId: 1, artist: 'Talk Talk')],
                ).execute()
                as WishlistExportPreviewReady;
        final row = result.preview.rows.first as EligibleWishlistExportRow;
        expect(row.artist, 'Talk Talk');
      });

      test('eligible row carries correct title', () async {
        final result =
            await makeUseCase(
                  items: [makeItem(releaseId: 1, title: 'Spirit of Eden')],
                ).execute()
                as WishlistExportPreviewReady;
        final row = result.preview.rows.first as EligibleWishlistExportRow;
        expect(row.title, 'Spirit of Eden');
      });

      test('eligible row carries correct releaseId', () async {
        final result =
            await makeUseCase(items: [makeItem(releaseId: 42)]).execute()
                as WishlistExportPreviewReady;
        final row = result.preview.rows.first as EligibleWishlistExportRow;
        expect(row.releaseId, 42);
      });

      test('eligible row carries correct itemId', () async {
        final result =
            await makeUseCase(
                  items: [makeItem(id: 'abc-123', releaseId: 1)],
                ).execute()
                as WishlistExportPreviewReady;
        final row = result.preview.rows.first as EligibleWishlistExportRow;
        expect(row.itemId, 'abc-123');
      });

      test('eligibleCount matches number of eligible items', () async {
        final result =
            await makeUseCase(
                  items: [
                    makeItem(id: 'a', releaseId: 1),
                    makeItem(id: 'b', releaseId: 2),
                    makeItem(id: 'c', releaseId: 3),
                  ],
                ).execute()
                as WishlistExportPreviewReady;
        expect(result.preview.eligibleCount, 3);
      });
    });

    group('already synced rows', () {
      test(
        'item with synced status produces AlreadySyncedWishlistExportRow',
        () async {
          final result =
              await makeUseCase(
                    items: [
                      makeItem(releaseId: 1, syncStatus: SyncStatus.synced),
                    ],
                  ).execute()
                  as WishlistExportPreviewReady;
          expect(
            result.preview.rows.first,
            isA<AlreadySyncedWishlistExportRow>(),
          );
        },
      );

      test('alreadySyncedCount is correct', () async {
        final result =
            await makeUseCase(
                  items: [
                    makeItem(
                      id: 'a',
                      releaseId: 1,
                      syncStatus: SyncStatus.synced,
                    ),
                    makeItem(
                      id: 'b',
                      releaseId: 2,
                      syncStatus: SyncStatus.synced,
                    ),
                  ],
                ).execute()
                as WishlistExportPreviewReady;
        expect(result.preview.alreadySyncedCount, 2);
      });

      test('already synced row carries correct releaseId', () async {
        final result =
            await makeUseCase(
                  items: [
                    makeItem(releaseId: 99, syncStatus: SyncStatus.synced),
                  ],
                ).execute()
                as WishlistExportPreviewReady;
        final row = result.preview.rows.first as AlreadySyncedWishlistExportRow;
        expect(row.releaseId, 99);
      });
    });

    group('invalid rows', () {
      test('item with releaseId 0 produces InvalidWishlistExportRow', () async {
        final result =
            await makeUseCase(items: [makeItem(releaseId: 0)]).execute()
                as WishlistExportPreviewReady;
        expect(result.preview.rows.first, isA<InvalidWishlistExportRow>());
      });

      test(
        'item with negative releaseId produces InvalidWishlistExportRow',
        () async {
          final result =
              await makeUseCase(items: [makeItem(releaseId: -1)]).execute()
                  as WishlistExportPreviewReady;
          expect(result.preview.rows.first, isA<InvalidWishlistExportRow>());
        },
      );

      test('invalid row has non-empty reason', () async {
        final result =
            await makeUseCase(items: [makeItem(releaseId: 0)]).execute()
                as WishlistExportPreviewReady;
        final row = result.preview.rows.first as InvalidWishlistExportRow;
        expect(row.reason, isNotEmpty);
      });

      test('invalid row reason does not contain token or secret', () async {
        final result =
            await makeUseCase(items: [makeItem(releaseId: 0)]).execute()
                as WishlistExportPreviewReady;
        final row = result.preview.rows.first as InvalidWishlistExportRow;
        expect(row.reason.toLowerCase(), isNot(contains('token')));
        expect(row.reason.toLowerCase(), isNot(contains('secret')));
      });

      test('invalidCount is correct', () async {
        final result =
            await makeUseCase(
                  items: [
                    makeItem(id: 'a', releaseId: 0),
                    makeItem(id: 'b', releaseId: 0),
                  ],
                ).execute()
                as WishlistExportPreviewReady;
        expect(result.preview.invalidCount, 2);
      });
    });

    group('mixed wishlist', () {
      test('mixed items produce correct counts', () async {
        final result =
            await makeUseCase(
                  items: [
                    makeItem(
                      id: 'a',
                      releaseId: 1,
                      syncStatus: SyncStatus.localOnly,
                    ),
                    makeItem(
                      id: 'b',
                      releaseId: 2,
                      syncStatus: SyncStatus.localOnly,
                    ),
                    makeItem(
                      id: 'c',
                      releaseId: 3,
                      syncStatus: SyncStatus.synced,
                    ),
                    makeItem(id: 'd', releaseId: 0),
                  ],
                ).execute()
                as WishlistExportPreviewReady;
        final p = result.preview;
        expect(p.totalCount, 4);
        expect(p.eligibleCount, 2);
        expect(p.alreadySyncedCount, 1);
        expect(p.invalidCount, 1);
      });
    });

    group('repository error', () {
      test(
        'returns WishlistExportPreviewError on repository exception',
        () async {
          final uc = BuildWishlistExportPreviewUseCase(
            repository: _ThrowingWishlistRepository(),
            capabilityUseCase: const _SupportedCapabilityUseCase(),
          );
          final result = await uc.execute();
          expect(result, isA<WishlistExportPreviewError>());
        },
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Spy helper
// ---------------------------------------------------------------------------

class _SpyWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _SpyWishlistRepository(this._delegate, {required this.onGetAll});

  final WishlistRepository _delegate;
  final void Function() onGetAll;

  @override
  Future<List<WishlistItem>> getAll() async {
    onGetAll();
    return _delegate.getAll();
  }

  @override
  Future<WishlistItem?> getById(String id) => _delegate.getById(id);

  @override
  Future<bool> containsRelease(int id) => _delegate.containsRelease(id);

  @override
  Future<void> add(WishlistItem item) => _delegate.add(item);

  @override
  Future<void> update(WishlistItem item) => _delegate.update(item);

  @override
  Future<void> remove(String id) => _delegate.remove(id);
}

import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/pending_discogs_deletion.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/pending_discogs_deletion_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/collection_detail_screen.dart';
import 'package:cratewise/presentation/screens/wishlist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeCollectionRepository(this.item);
  final CollectionItem item;
  bool removed = false;

  @override
  Future<CollectionItem?> getById(String id) async => item;
  @override
  Future<void> remove(String id) async => removed = true;
  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
}

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeWishlistRepository(this.item);
  final WishlistItem item;
  bool removed = false;

  @override
  Future<WishlistItem?> getById(String id) async => item;
  @override
  Future<void> remove(String id) async => removed = true;
  @override
  Future<List<WishlistItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
}

class _SpyDeletionRepository implements PendingDiscogsDeletionRepository {
  @override
  Future<void> deleteAllByType(DeletionEntityType entityType) async {}
  final List<PendingDiscogsDeletion> added = [];

  @override
  Future<void> add(PendingDiscogsDeletion deletion) async =>
      added.add(deletion);
  @override
  Future<List<PendingDiscogsDeletion>> getByType(
    DeletionEntityType type,
  ) async => [];
  @override
  Future<bool> containsRelease(int id, DeletionEntityType type) async => false;
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> removeByRelease(int id, DeletionEntityType type) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _collectionItem({int? discogsInstanceId}) => CollectionItem(
  id: 'c-1',
  discogsReleaseId: 193467,
  artist: 'Test Artist',
  title: 'Test Album',
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: const [],
  syncStatus: SyncStatus.synced,
  discogsInstanceId: discogsInstanceId,
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

WishlistItem _wishlistItem({SyncStatus syncStatus = SyncStatus.synced}) =>
    WishlistItem(
      id: 'w-1',
      discogsReleaseId: 193467,
      artist: 'Test Artist',
      title: 'Test Album',
      priority: WishlistPriority.medium,
      syncStatus: syncStatus,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _openRemoveDialog(WidgetTester tester, String menuLabel) async {
  await tester.tap(find.byKey(const Key('detail-overflow-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(menuLabel).last);
  await tester.pumpAndSettle();
}

Future<void> _openCollectionRemove(WidgetTester tester) =>
    _openRemoveDialog(tester, 'Remove from Cratewise');

Future<void> _openWishlistRemove(WidgetTester tester) =>
    _openRemoveDialog(tester, 'Remove from wishlist');

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionDetailScreen — delete propagation (US-72)', () {
    testWidgets('records a tombstone when "also remove from Discogs" is '
        'checked', (tester) async {
      final deletions = _SpyDeletionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(
            itemId: 'c-1',
            repository: _FakeCollectionRepository(
              _collectionItem(discogsInstanceId: 9001),
            ),
            deletionRepository: deletions,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openCollectionRemove(tester);

      await tester.tap(
        find.byKey(const Key('also-remove-from-discogs-checkbox')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();

      expect(deletions.added, hasLength(1));
      final t = deletions.added.single;
      expect(t.entityType, DeletionEntityType.collection);
      expect(t.discogsReleaseId, 193467);
      expect(t.discogsInstanceId, 9001);
    });

    testWidgets('records no tombstone when the box is left unchecked', (
      tester,
    ) async {
      final deletions = _SpyDeletionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(
            itemId: 'c-1',
            repository: _FakeCollectionRepository(
              _collectionItem(discogsInstanceId: 9001),
            ),
            deletionRepository: deletions,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openCollectionRemove(tester);

      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();

      expect(deletions.added, isEmpty);
    });

    testWidgets('shows no Discogs option for an item without an instance id', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(
            itemId: 'c-1',
            repository: _FakeCollectionRepository(_collectionItem()),
            deletionRepository: _SpyDeletionRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openCollectionRemove(tester);

      expect(
        find.byKey(const Key('also-remove-from-discogs-checkbox')),
        findsNothing,
      );
      expect(
        find.textContaining('Your Discogs collection is not affected'),
        findsOneWidget,
      );
    });
  });

  group('WishlistDetailScreen — delete propagation (US-72)', () {
    testWidgets('records a tombstone (no instance id) for a synced want', (
      tester,
    ) async {
      final deletions = _SpyDeletionRepository();
      await tester.pumpWidget(
        _wrap(
          WishlistDetailScreen(
            itemId: 'w-1',
            repository: _FakeWishlistRepository(_wishlistItem()),
            deletionRepository: deletions,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openWishlistRemove(tester);

      await tester.tap(
        find.byKey(const Key('also-remove-from-discogs-checkbox')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-remove-button')));
      await tester.pumpAndSettle();

      expect(deletions.added, hasLength(1));
      final t = deletions.added.single;
      expect(t.entityType, DeletionEntityType.wishlist);
      expect(t.discogsReleaseId, 193467);
      expect(t.discogsInstanceId, isNull);
    });

    testWidgets('shows no Discogs option for a local-only want', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          WishlistDetailScreen(
            itemId: 'w-1',
            repository: _FakeWishlistRepository(
              _wishlistItem(syncStatus: SyncStatus.localOnly),
            ),
            deletionRepository: _SpyDeletionRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openWishlistRemove(tester);

      expect(
        find.byKey(const Key('also-remove-from-discogs-checkbox')),
        findsNothing,
      );
      expect(
        find.textContaining('Your Discogs account is not affected'),
        findsOneWidget,
      );
    });
  });
}

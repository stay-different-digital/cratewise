import 'dart:convert';

import 'package:cratewise/application/use_cases/retry_add_wishlist_item_use_case.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _SpyWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  final List<WishlistItem> _items = [];
  bool throwOnAdd = false;

  @override
  Future<List<WishlistItem>> getAll() async => List.of(_items);

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      _items.any((i) => i.discogsReleaseId == discogsReleaseId);

  @override
  Future<void> add(WishlistItem item) async {
    if (throwOnAdd) throw Exception('storage error');
    _items.add(item);
  }

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _SpyRetryRepository implements RetryActionRepository {
  final List<RetryAction> _actions;
  final List<String> removed = [];
  final List<RetryAction> updated = [];

  _SpyRetryRepository([List<RetryAction>? actions])
    : _actions = List.of(actions ?? []);

  @override
  Future<void> add(RetryAction action) async => _actions.add(action);

  @override
  Future<List<RetryAction>> getAll() async => List.of(_actions);

  @override
  Future<RetryAction?> getById(String id) async =>
      _actions.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<RetryAction>> getPending() async =>
      _actions.where((a) => a.status == RetryActionStatus.pending).toList();

  @override
  Future<void> update(RetryAction action) async => updated.add(action);

  @override
  Future<void> remove(String id) async => removed.add(id);

  @override
  Future<void> deleteFailedBefore(DateTime cutoff) async {}

  @override
  Future<void> deleteAll() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WishlistItem _makeWishlistItem({
  String id = 'item-1',
  int discogsReleaseId = 249504,
  String artist = 'Miles Davis',
  String title = 'Kind Of Blue',
}) {
  final now = DateTime(2026, 6, 1, 10, 0);
  return WishlistItem(
    id: id,
    discogsReleaseId: discogsReleaseId,
    artist: artist,
    title: title,
    priority: WishlistPriority.medium,
    syncStatus: SyncStatus.localOnly,
    createdAt: now,
    updatedAt: now,
  );
}

RetryAction _makeAction({
  String id = 'action-1',
  String? payload,
  int attemptCount = 0,
  RetryActionStatus status = RetryActionStatus.pending,
}) {
  return RetryAction(
    id: id,
    actionType: RetryActionType.addWishlistItem,
    entityType: RetryActionEntityType.wishlistItem,
    entityId: '249504',
    safeErrorMessage: "Could not save 'Kind Of Blue' to wishlist.",
    payload: payload,
    createdAt: DateTime(2026, 6, 1, 10, 0),
    attemptCount: attemptCount,
    status: status,
  );
}

String _encodeItem(WishlistItem item) => jsonEncode(item.toJson());

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RetryAddWishlistItemUseCase', () {
    late _SpyWishlistRepository wishlistRepo;
    late _SpyRetryRepository retryRepo;
    late RetryAddWishlistItemUseCase useCase;

    setUp(() {
      wishlistRepo = _SpyWishlistRepository();
      retryRepo = _SpyRetryRepository();
      useCase = RetryAddWishlistItemUseCase(
        retryRepo: retryRepo,
        wishlistRepo: wishlistRepo,
      );
    });

    group('success path', () {
      test('returns Success when item is added', () async {
        final item = _makeWishlistItem();
        final action = _makeAction(payload: _encodeItem(item));
        final result = await useCase.execute(action);
        expect(result, isA<RetryAddWishlistItemSuccess>());
      });

      test('item is persisted to wishlist', () async {
        final item = _makeWishlistItem();
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(await wishlistRepo.getAll(), hasLength(1));
      });

      test('action is removed from retry queue on success', () async {
        final item = _makeWishlistItem();
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(retryRepo.removed, contains('action-1'));
      });
    });

    group('already exists path', () {
      test(
        'returns AlreadyExists when release is already in wishlist',
        () async {
          final item = _makeWishlistItem();
          wishlistRepo._items.add(item);
          final action = _makeAction(payload: _encodeItem(item));
          final result = await useCase.execute(action);
          expect(result, isA<RetryAddWishlistItemAlreadyExists>());
        },
      );

      test('action is removed from retry queue when already exists', () async {
        final item = _makeWishlistItem();
        wishlistRepo._items.add(item);
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(retryRepo.removed, contains('action-1'));
      });
    });

    group('invalid payload path', () {
      test('returns InvalidPayload when payload is null', () async {
        final action = _makeAction(payload: null);
        final result = await useCase.execute(action);
        expect(result, isA<RetryAddWishlistItemInvalidPayload>());
      });

      test('returns InvalidPayload when payload is malformed JSON', () async {
        final action = _makeAction(payload: 'not-json');
        final result = await useCase.execute(action);
        expect(result, isA<RetryAddWishlistItemInvalidPayload>());
      });

      test('increments attempt count when payload is null', () async {
        final action = _makeAction(payload: null, attemptCount: 1);
        await useCase.execute(action);
        expect(retryRepo.updated.first.attemptCount, 2);
      });

      test('sets status to failed when payload is invalid', () async {
        final action = _makeAction(payload: 'bad');
        await useCase.execute(action);
        expect(retryRepo.updated.first.status, RetryActionStatus.failed);
      });
    });

    group('storage error path', () {
      setUp(() => wishlistRepo.throwOnAdd = true);

      test('returns StorageError when add still throws', () async {
        final item = _makeWishlistItem();
        final action = _makeAction(payload: _encodeItem(item));
        final result = await useCase.execute(action);
        expect(result, isA<RetryAddWishlistItemStorageError>());
      });

      test('increments attempt count when add still throws', () async {
        final item = _makeWishlistItem();
        final action = _makeAction(payload: _encodeItem(item), attemptCount: 2);
        await useCase.execute(action);
        expect(retryRepo.updated.first.attemptCount, 3);
      });

      test('sets status to failed when add still throws', () async {
        final item = _makeWishlistItem();
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(retryRepo.updated.first.status, RetryActionStatus.failed);
      });

      test('action is NOT removed on storage error', () async {
        final item = _makeWishlistItem();
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(retryRepo.removed, isEmpty);
      });
    });
  });
}

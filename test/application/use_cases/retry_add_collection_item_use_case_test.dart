import 'dart:convert';

import 'package:cratewise/application/use_cases/retry_add_collection_item_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _SpyCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  final List<CollectionItem> _items = [];
  bool throwOnAdd = false;

  @override
  Future<List<CollectionItem>> getAll() async => List.of(_items);

  @override
  Future<CollectionItem?> getById(String id) async => null;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      _items.any((i) => i.discogsReleaseId == discogsReleaseId);

  @override
  Future<void> add(CollectionItem item) async {
    if (throwOnAdd) throw Exception('storage error');
    _items.add(item);
  }

  @override
  Future<void> update(CollectionItem item) async {}

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

CollectionItem _makeCollectionItem({
  String id = 'item-1',
  int discogsReleaseId = 249504,
  String artist = 'Miles Davis',
  String title = 'Kind Of Blue',
}) {
  final now = DateTime(2026, 6, 1, 10, 0);
  return CollectionItem(
    id: id,
    discogsReleaseId: discogsReleaseId,
    artist: artist,
    title: title,
    mediaCondition: RecordCondition.veryGood,
    sleeveCondition: RecordCondition.veryGood,
    tags: const [],
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
    actionType: RetryActionType.addCollectionItem,
    entityType: RetryActionEntityType.collectionItem,
    entityId: '249504',
    safeErrorMessage: "Could not save 'Kind Of Blue' to collection.",
    payload: payload,
    createdAt: DateTime(2026, 6, 1, 10, 0),
    attemptCount: attemptCount,
    status: status,
  );
}

String _encodeItem(CollectionItem item) => jsonEncode(item.toJson());

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RetryAddCollectionItemUseCase', () {
    late _SpyCollectionRepository collectionRepo;
    late _SpyRetryRepository retryRepo;
    late RetryAddCollectionItemUseCase useCase;

    setUp(() {
      collectionRepo = _SpyCollectionRepository();
      retryRepo = _SpyRetryRepository();
      useCase = RetryAddCollectionItemUseCase(
        retryRepo: retryRepo,
        collectionRepo: collectionRepo,
      );
    });

    group('success path', () {
      test('returns Success when item is added', () async {
        final item = _makeCollectionItem();
        final action = _makeAction(payload: _encodeItem(item));
        final result = await useCase.execute(action);
        expect(result, isA<RetryAddCollectionItemSuccess>());
      });

      test('item is persisted to collection', () async {
        final item = _makeCollectionItem();
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(await collectionRepo.getAll(), hasLength(1));
      });

      test('action is removed from retry queue on success', () async {
        final item = _makeCollectionItem();
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(retryRepo.removed, contains('action-1'));
      });
    });

    group('already exists path', () {
      test(
        'returns AlreadyExists when release is already in collection',
        () async {
          final item = _makeCollectionItem();
          collectionRepo._items.add(item);
          final action = _makeAction(payload: _encodeItem(item));
          final result = await useCase.execute(action);
          expect(result, isA<RetryAddCollectionItemAlreadyExists>());
        },
      );

      test('action is removed from retry queue when already exists', () async {
        final item = _makeCollectionItem();
        collectionRepo._items.add(item);
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(retryRepo.removed, contains('action-1'));
      });
    });

    group('invalid payload path', () {
      test('returns InvalidPayload when payload is null', () async {
        final action = _makeAction(payload: null);
        final result = await useCase.execute(action);
        expect(result, isA<RetryAddCollectionItemInvalidPayload>());
      });

      test('returns InvalidPayload when payload is malformed JSON', () async {
        final action = _makeAction(payload: 'not-json');
        final result = await useCase.execute(action);
        expect(result, isA<RetryAddCollectionItemInvalidPayload>());
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
      setUp(() => collectionRepo.throwOnAdd = true);

      test('returns StorageError when add still throws', () async {
        final item = _makeCollectionItem();
        final action = _makeAction(payload: _encodeItem(item));
        final result = await useCase.execute(action);
        expect(result, isA<RetryAddCollectionItemStorageError>());
      });

      test('increments attempt count when add still throws', () async {
        final item = _makeCollectionItem();
        final action = _makeAction(payload: _encodeItem(item), attemptCount: 2);
        await useCase.execute(action);
        expect(retryRepo.updated.first.attemptCount, 3);
      });

      test('sets status to failed when add still throws', () async {
        final item = _makeCollectionItem();
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(retryRepo.updated.first.status, RetryActionStatus.failed);
      });

      test('action is NOT removed on storage error', () async {
        final item = _makeCollectionItem();
        final action = _makeAction(payload: _encodeItem(item));
        await useCase.execute(action);
        expect(retryRepo.removed, isEmpty);
      });
    });
  });
}

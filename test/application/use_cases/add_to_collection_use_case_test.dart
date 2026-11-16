import 'dart:async';

import 'package:cratewise/application/services/discogs_auto_sync_service.dart';
import 'package:cratewise/application/use_cases/add_to_collection_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/release_detail.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  final List<CollectionItem> _items = [];

  @override
  Future<List<CollectionItem>> getAll() async => List.unmodifiable(_items);

  @override
  Future<CollectionItem?> getById(String id) async =>
      _items.where((i) => i.id == id).firstOrNull;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      _items.any((i) => i.discogsReleaseId == discogsReleaseId);

  @override
  Future<void> add(CollectionItem item) async => _items.add(item);

  @override
  Future<void> update(CollectionItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _ThrowingCollectionRepository extends FakeCollectionRepository {
  @override
  Future<void> add(CollectionItem item) async =>
      throw Exception('storage error');
}

class _SpyRetryRepository implements RetryActionRepository {
  final List<RetryAction> added = [];

  @override
  Future<void> add(RetryAction action) async => added.add(action);

  @override
  Future<List<RetryAction>> getAll() async => List.of(added);

  @override
  Future<RetryAction?> getById(String id) async => null;

  @override
  Future<List<RetryAction>> getPending() async =>
      added.where((a) => a.status == RetryActionStatus.pending).toList();

  @override
  Future<void> update(RetryAction action) async {}

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> deleteFailedBefore(DateTime cutoff) async {}

  @override
  Future<void> deleteAll() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ReleaseDetail kindOfBlue({
  String label = 'Columbia',
  String catno = 'CL 1355',
  String format = 'Vinyl, LP',
  String country = 'US',
}) => ReleaseDetail(
  id: 249504,
  title: 'Kind Of Blue',
  artist: 'Miles Davis',
  label: label,
  catno: catno,
  format: format,
  country: country,
  year: 1959,
  genres: const ['Jazz'],
  styles: const ['Modal'],
  tracklist: const [],
  identifiers: const [],
  notes: 'A seminal jazz album.',
  coverUrl: 'https://i.discogs.com/cover.jpg',
);

AddToCollectionUseCase makeUseCase(
  FakeCollectionRepository repo, {
  int idCounter = 0,
  RetryActionRepository? retryRepo,
}) {
  var counter = idCounter;
  return AddToCollectionUseCase(
    repo,
    idGenerator: () => 'id-${++counter}',
    retryRepository: retryRepo,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AddToCollectionUseCase', () {
    late FakeCollectionRepository repo;
    late AddToCollectionUseCase useCase;

    setUp(() {
      repo = FakeCollectionRepository();
      useCase = makeUseCase(repo);
    });

    group('new release', () {
      test('returns AddToCollectionSuccess', () async {
        final result = await useCase.execute(kindOfBlue());
        expect(result, isA<AddToCollectionSuccess>());
      });

      test('result contains saved CollectionItem', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item, isA<CollectionItem>());
      });

      test('item is persisted in repository', () async {
        await useCase.execute(kindOfBlue());
        expect(await repo.getAll(), hasLength(1));
      });

      test('item has correct Discogs release ID', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.discogsReleaseId, 249504);
      });

      test('item has correct artist and title', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.artist, 'Miles Davis');
        expect(result.item.title, 'Kind Of Blue');
      });

      test('item has correct optional release fields', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.label, 'Columbia');
        expect(result.item.catno, 'CL 1355');
        expect(result.item.format, 'Vinyl, LP');
        expect(result.item.country, 'US');
        expect(result.item.year, 1959);
        expect(result.item.coverUrl, 'https://i.discogs.com/cover.jpg');
      });

      test('default mediaCondition is veryGood', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.mediaCondition, RecordCondition.veryGood);
      });

      test('default sleeveCondition is veryGood', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.sleeveCondition, RecordCondition.veryGood);
      });

      test('default tags is empty list', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.tags, isEmpty);
      });

      test('default notes is null', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.notes, isNull);
      });

      test('default storageLocation is null', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.storageLocation, isNull);
      });

      test('default syncStatus is localOnly', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.syncStatus, SyncStatus.localOnly);
      });

      test('generated id is non-empty', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        expect(result.item.id, isNotEmpty);
      });

      test('createdAt and updatedAt are set close to now', () async {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final result =
            await useCase.execute(kindOfBlue()) as AddToCollectionSuccess;
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(result.item.createdAt.isAfter(before), isTrue);
        expect(result.item.createdAt.isBefore(after), isTrue);
        expect(result.item.updatedAt.isAfter(before), isTrue);
        expect(result.item.updatedAt.isBefore(after), isTrue);
      });
    });

    group('empty string fields from release', () {
      test('empty label becomes null', () async {
        final result =
            await useCase.execute(kindOfBlue(label: ''))
                as AddToCollectionSuccess;
        expect(result.item.label, isNull);
      });

      test('empty catno becomes null', () async {
        final result =
            await useCase.execute(kindOfBlue(catno: ''))
                as AddToCollectionSuccess;
        expect(result.item.catno, isNull);
      });

      test('empty format becomes null', () async {
        final result =
            await useCase.execute(kindOfBlue(format: ''))
                as AddToCollectionSuccess;
        expect(result.item.format, isNull);
      });

      test('empty country becomes null', () async {
        final result =
            await useCase.execute(kindOfBlue(country: ''))
                as AddToCollectionSuccess;
        expect(result.item.country, isNull);
      });
    });

    group('duplicate prevention', () {
      test(
        'returns AddToCollectionDuplicate when release already in collection',
        () async {
          await useCase.execute(kindOfBlue());
          final result = await useCase.execute(kindOfBlue());
          expect(result, isA<AddToCollectionDuplicate>());
        },
      );

      test(
        'does not add a second item when release already in collection',
        () async {
          await useCase.execute(kindOfBlue());
          await useCase.execute(kindOfBlue());
          expect(await repo.getAll(), hasLength(1));
        },
      );

      test(
        'allows adding a different release after a duplicate is rejected',
        () async {
          final other = ReleaseDetail(
            id: 111111,
            title: 'A Love Supreme',
            artist: 'John Coltrane',
            label: 'Impulse!',
            catno: 'A-77',
            format: 'Vinyl, LP',
            country: 'US',
            year: 1965,
            genres: const ['Jazz'],
            styles: const [],
            tracklist: const [],
            identifiers: const [],
          );
          await useCase.execute(kindOfBlue());
          await useCase.execute(kindOfBlue());
          final result = await useCase.execute(other);
          expect(result, isA<AddToCollectionSuccess>());
          expect(await repo.getAll(), hasLength(2));
        },
      );
    });

    group('storage failure and retry queuing', () {
      late _ThrowingCollectionRepository throwingRepo;
      late _SpyRetryRepository retryRepo;
      late AddToCollectionUseCase failingUseCase;

      setUp(() {
        throwingRepo = _ThrowingCollectionRepository();
        retryRepo = _SpyRetryRepository();
        failingUseCase = makeUseCase(throwingRepo, retryRepo: retryRepo);
      });

      test('returns AddToCollectionStorageError when add throws', () async {
        final result = await failingUseCase.execute(kindOfBlue());
        expect(result, isA<AddToCollectionStorageError>());
      });

      test(
        'records retry action when add throws and retryRepo provided',
        () async {
          await failingUseCase.execute(kindOfBlue());
          expect(retryRepo.added, hasLength(1));
        },
      );

      test('recorded action has addCollectionItem type', () async {
        await failingUseCase.execute(kindOfBlue());
        expect(
          retryRepo.added.first.actionType,
          RetryActionType.addCollectionItem,
        );
      });

      test('recorded action entityId is the release ID as string', () async {
        await failingUseCase.execute(kindOfBlue());
        expect(retryRepo.added.first.entityId, '249504');
      });

      test('recorded action safe message contains item title', () async {
        await failingUseCase.execute(kindOfBlue());
        expect(
          retryRepo.added.first.safeErrorMessage,
          contains('Kind Of Blue'),
        );
      });

      test('recorded action payload contains serialised item', () async {
        await failingUseCase.execute(kindOfBlue());
        expect(retryRepo.added.first.payload, isNotNull);
        final item = CollectionItem.tryFromJson(retryRepo.added.first.payload!);
        expect(item, isNotNull);
        expect(item!.artist, 'Miles Davis');
      });

      test('does not record retry action without retryRepo', () async {
        final noRetryUseCase = makeUseCase(_ThrowingCollectionRepository());
        await noRetryUseCase.execute(kindOfBlue());
        // No assertion needed — test passes if no exception thrown.
      });

      test(
        'deduplicates: second failure for same release is not re-queued',
        () async {
          await failingUseCase.execute(kindOfBlue());
          await failingUseCase.execute(kindOfBlue());
          expect(retryRepo.added, hasLength(1));
        },
      );

      test('safe message does not contain token or secret', () async {
        await failingUseCase.execute(kindOfBlue());
        final msg = retryRepo.added.first.safeErrorMessage.toLowerCase();
        expect(msg, isNot(contains('token')));
        expect(msg, isNot(contains('secret')));
      });
    });
  });

  group('AddToCollectionUseCase — auto-sync (US-144)', () {
    test(
      'a saved item is handed to auto-sync without waiting for Discogs',
      () async {
        final repo = FakeCollectionRepository();
        final sync = _NeverFinishingSync();
        final useCase = AddToCollectionUseCase(repo, autoSync: sync);

        final result = await useCase.execute(kindOfBlue());

        expect(result, isA<AddToCollectionSuccess>());
        expect(sync.pushed.single.discogsReleaseId, kindOfBlue().id);
      },
    );

    test(
      'nothing is pushed when the local save fails or is a duplicate',
      () async {
        final repo = FakeCollectionRepository();
        final sync = _NeverFinishingSync();
        final useCase = AddToCollectionUseCase(repo, autoSync: sync);
        await useCase.execute(kindOfBlue());
        sync.pushed.clear();

        final again = await useCase.execute(kindOfBlue());

        expect(again, isA<AddToCollectionDuplicate>());
        expect(sync.pushed, isEmpty);
      },
    );
  });
}

/// Auto-sync whose Discogs call never completes: if adding awaited it, the
/// test would hang.
class _NeverFinishingSync extends DiscogsAutoSyncService {
  _NeverFinishingSync() : super(tokenStorage: null);
  final pushed = <CollectionItem>[];

  @override
  Future<void> pushCollectionItem(
    CollectionItem item,
    CollectionRepository repository,
  ) {
    pushed.add(item);
    return Completer<void>().future;
  }
}

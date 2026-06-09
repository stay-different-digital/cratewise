import 'package:cratewise/application/use_cases/add_to_wishlist_use_case.dart';
import 'package:cratewise/domain/models/release_detail.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class FakeWishlistRepository implements WishlistRepository {
  final List<WishlistItem> _items = [];

  @override
  Future<List<WishlistItem>> getAll() async => List.unmodifiable(_items);

  @override
  Future<WishlistItem?> getById(String id) async =>
      _items.where((i) => i.id == id).firstOrNull;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      _items.any((i) => i.discogsReleaseId == discogsReleaseId);

  @override
  Future<void> add(WishlistItem item) async => _items.add(item);

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

class _ThrowingWishlistRepository extends FakeWishlistRepository {
  @override
  Future<void> add(WishlistItem item) async => throw Exception('storage error');
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

AddToWishlistUseCase makeUseCase(
  FakeWishlistRepository repo, {
  int idCounter = 0,
  RetryActionRepository? retryRepo,
}) {
  var counter = idCounter;
  return AddToWishlistUseCase(
    repo,
    idGenerator: () => 'id-${++counter}',
    retryRepository: retryRepo,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AddToWishlistUseCase', () {
    late FakeWishlistRepository repo;
    late AddToWishlistUseCase useCase;

    setUp(() {
      repo = FakeWishlistRepository();
      useCase = makeUseCase(repo);
    });

    group('new release', () {
      test('returns AddToWishlistSuccess', () async {
        final result = await useCase.execute(kindOfBlue());
        expect(result, isA<AddToWishlistSuccess>());
      });

      test('result contains saved WishlistItem', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item, isA<WishlistItem>());
      });

      test('item is persisted in repository', () async {
        await useCase.execute(kindOfBlue());
        expect(await repo.getAll(), hasLength(1));
      });

      test('item has correct Discogs release ID', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item.discogsReleaseId, 249504);
      });

      test('item has correct artist and title', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item.artist, 'Miles Davis');
        expect(result.item.title, 'Kind Of Blue');
      });

      test('item has correct optional release fields', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item.label, 'Columbia');
        expect(result.item.catno, 'CL 1355');
        expect(result.item.format, 'Vinyl, LP');
        expect(result.item.country, 'US');
        expect(result.item.year, 1959);
        expect(result.item.coverUrl, 'https://i.discogs.com/cover.jpg');
      });

      test('default priority is medium', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item.priority, WishlistPriority.medium);
      });

      test('default targetPrice is null', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item.targetPrice, isNull);
      });

      test('default notes is null', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item.notes, isNull);
      });

      test('default syncStatus is localOnly', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item.syncStatus, SyncStatus.localOnly);
      });

      test('generated id is non-empty', () async {
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
        expect(result.item.id, isNotEmpty);
      });

      test('createdAt and updatedAt are set close to now', () async {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final result =
            await useCase.execute(kindOfBlue()) as AddToWishlistSuccess;
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
                as AddToWishlistSuccess;
        expect(result.item.label, isNull);
      });

      test('empty catno becomes null', () async {
        final result =
            await useCase.execute(kindOfBlue(catno: ''))
                as AddToWishlistSuccess;
        expect(result.item.catno, isNull);
      });

      test('empty format becomes null', () async {
        final result =
            await useCase.execute(kindOfBlue(format: ''))
                as AddToWishlistSuccess;
        expect(result.item.format, isNull);
      });

      test('empty country becomes null', () async {
        final result =
            await useCase.execute(kindOfBlue(country: ''))
                as AddToWishlistSuccess;
        expect(result.item.country, isNull);
      });
    });

    group('duplicate prevention', () {
      test(
        'returns AddToWishlistDuplicate when release already in wishlist',
        () async {
          await useCase.execute(kindOfBlue());
          final result = await useCase.execute(kindOfBlue());
          expect(result, isA<AddToWishlistDuplicate>());
        },
      );

      test(
        'does not add a second item when release already in wishlist',
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
          expect(result, isA<AddToWishlistSuccess>());
          expect(await repo.getAll(), hasLength(2));
        },
      );
    });

    group('storage failure and retry queuing', () {
      late _ThrowingWishlistRepository throwingRepo;
      late _SpyRetryRepository retryRepo;
      late AddToWishlistUseCase failingUseCase;

      setUp(() {
        throwingRepo = _ThrowingWishlistRepository();
        retryRepo = _SpyRetryRepository();
        failingUseCase = makeUseCase(throwingRepo, retryRepo: retryRepo);
      });

      test('returns AddToWishlistStorageError when add throws', () async {
        final result = await failingUseCase.execute(kindOfBlue());
        expect(result, isA<AddToWishlistStorageError>());
      });

      test(
        'records retry action when add throws and retryRepo provided',
        () async {
          await failingUseCase.execute(kindOfBlue());
          expect(retryRepo.added, hasLength(1));
        },
      );

      test('recorded action has addWishlistItem type', () async {
        await failingUseCase.execute(kindOfBlue());
        expect(
          retryRepo.added.first.actionType,
          RetryActionType.addWishlistItem,
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
        final item = WishlistItem.tryFromJson(retryRepo.added.first.payload!);
        expect(item, isNotNull);
        expect(item!.artist, 'Miles Davis');
      });

      test('does not record retry action without retryRepo', () async {
        final noRetryUseCase = makeUseCase(_ThrowingWishlistRepository());
        await noRetryUseCase.execute(kindOfBlue());
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
}

import 'package:cratewise/domain/models/pending_discogs_deletion.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/local_pending_discogs_deletion_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

PendingDiscogsDeletion _makeDeletion({
  String id = 'd-1',
  DeletionEntityType entityType = DeletionEntityType.collection,
  int discogsReleaseId = 100,
  int? discogsInstanceId = 9001,
  String artist = 'Artist',
  String title = 'Title',
  DateTime? createdAt,
}) => PendingDiscogsDeletion(
  id: id,
  entityType: entityType,
  discogsReleaseId: discogsReleaseId,
  discogsInstanceId: discogsInstanceId,
  artist: artist,
  title: title,
  createdAt: createdAt ?? DateTime(2026, 6, 1),
);

void main() {
  late AppDatabase db;
  late LocalPendingDiscogsDeletionRepository repo;

  setUp(() {
    db = _openTestDb();
    repo = LocalPendingDiscogsDeletionRepository(db);
  });

  tearDown(() => db.close());

  test('add then getByType round-trips all fields', () async {
    await repo.add(_makeDeletion());

    final result = await repo.getByType(DeletionEntityType.collection);

    expect(result, hasLength(1));
    final d = result.single;
    expect(d.id, 'd-1');
    expect(d.entityType, DeletionEntityType.collection);
    expect(d.discogsReleaseId, 100);
    expect(d.discogsInstanceId, 9001);
    expect(d.artist, 'Artist');
    expect(d.title, 'Title');
  });

  test('getByType filters by entity type', () async {
    await repo.add(_makeDeletion(id: 'c-1'));
    await repo.add(
      _makeDeletion(
        id: 'w-1',
        entityType: DeletionEntityType.wishlist,
        discogsInstanceId: null,
      ),
    );

    final collection = await repo.getByType(DeletionEntityType.collection);
    final wishlist = await repo.getByType(DeletionEntityType.wishlist);

    expect(collection.map((d) => d.id), ['c-1']);
    expect(wishlist.map((d) => d.id), ['w-1']);
    expect(wishlist.single.discogsInstanceId, isNull);
  });

  test('getByType orders oldest first', () async {
    await repo.add(_makeDeletion(id: 'new', createdAt: DateTime(2026, 6, 5)));
    await repo.add(_makeDeletion(id: 'old', createdAt: DateTime(2026, 6, 1)));

    final result = await repo.getByType(DeletionEntityType.collection);

    expect(result.map((d) => d.id), ['old', 'new']);
  });

  test(
    'containsRelease is true only for a matching release and type',
    () async {
      await repo.add(_makeDeletion(discogsReleaseId: 100));

      expect(
        await repo.containsRelease(100, DeletionEntityType.collection),
        isTrue,
      );
      expect(
        await repo.containsRelease(100, DeletionEntityType.wishlist),
        isFalse,
      );
      expect(
        await repo.containsRelease(999, DeletionEntityType.collection),
        isFalse,
      );
    },
  );

  test('remove deletes by id', () async {
    await repo.add(_makeDeletion(id: 'd-1'));
    await repo.remove('d-1');

    expect(await repo.getByType(DeletionEntityType.collection), isEmpty);
  });

  test('removeByRelease clears a matching pending deletion', () async {
    await repo.add(_makeDeletion(discogsReleaseId: 100));

    await repo.removeByRelease(100, DeletionEntityType.collection);

    expect(
      await repo.containsRelease(100, DeletionEntityType.collection),
      isFalse,
    );
  });

  test('add replaces an existing tombstone with the same id', () async {
    await repo.add(_makeDeletion(id: 'd-1', title: 'First'));
    await repo.add(_makeDeletion(id: 'd-1', title: 'Second'));

    final result = await repo.getByType(DeletionEntityType.collection);
    expect(result, hasLength(1));
    expect(result.single.title, 'Second');
  });
}

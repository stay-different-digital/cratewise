import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/local_collection_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

CollectionItem makeItem({
  String id = 'test-1',
  int discogsReleaseId = 249504,
  String artist = 'Miles Davis',
  String title = 'Kind Of Blue',
}) =>
    CollectionItem(
      id: id,
      discogsReleaseId: discogsReleaseId,
      artist: artist,
      title: title,
      mediaCondition: RecordCondition.veryGoodPlus,
      sleeveCondition: RecordCondition.veryGood,
      tags: const ['jazz'],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('LocalCollectionRepository', () {
    late AppDatabase db;
    late LocalCollectionRepository repo;

    setUp(() {
      db = openTestDb();
      repo = LocalCollectionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('add and getAll', () {
      test('returns empty list when collection is empty', () async {
        expect(await repo.getAll(), isEmpty);
      });

      test('returns item after adding', () async {
        await repo.add(makeItem());
        final all = await repo.getAll();
        expect(all, hasLength(1));
        expect(all.first.title, 'Kind Of Blue');
      });

      test('returns multiple items in descending created order', () async {
        await repo.add(makeItem(
          id: 'a',
          discogsReleaseId: 1,
          title: 'First',
        ));
        await repo.add(makeItem(
          id: 'b',
          discogsReleaseId: 2,
          title: 'Second',
        ));
        final all = await repo.getAll();
        expect(all, hasLength(2));
      });
    });

    group('getById', () {
      test('returns item with matching id', () async {
        await repo.add(makeItem(id: 'abc'));
        final item = await repo.getById('abc');
        expect(item, isNotNull);
        expect(item!.id, 'abc');
      });

      test('returns null for unknown id', () async {
        expect(await repo.getById('no-such-id'), isNull);
      });
    });

    group('containsRelease', () {
      test('returns false when collection is empty', () async {
        expect(await repo.containsRelease(249504), isFalse);
      });

      test('returns true when release is in collection', () async {
        await repo.add(makeItem(discogsReleaseId: 249504));
        expect(await repo.containsRelease(249504), isTrue);
      });

      test('returns false when a different release is in collection', () async {
        await repo.add(makeItem(discogsReleaseId: 111111));
        expect(await repo.containsRelease(249504), isFalse);
      });
    });

    group('update', () {
      test('modifies notes on existing item', () async {
        await repo.add(makeItem(id: 'upd'));
        final original = await repo.getById('upd');
        final updated = original!.copyWith(
          notes: 'Updated note',
          updatedAt: DateTime(2026, 6, 1),
        );
        await repo.update(updated);
        final fetched = await repo.getById('upd');
        expect(fetched!.notes, 'Updated note');
      });

      test('does not alter other fields when updating one field', () async {
        await repo.add(makeItem(id: 'partial'));
        final original = await repo.getById('partial');
        await repo.update(original!.copyWith(notes: 'Changed'));
        final fetched = await repo.getById('partial');
        expect(fetched!.artist, original.artist);
        expect(fetched.mediaCondition, original.mediaCondition);
      });
    });

    group('remove', () {
      test('deletes item so getById returns null', () async {
        await repo.add(makeItem(id: 'del'));
        await repo.remove('del');
        expect(await repo.getById('del'), isNull);
      });

      test('does not affect other items', () async {
        await repo.add(makeItem(id: 'keep', discogsReleaseId: 1));
        await repo.add(makeItem(id: 'del', discogsReleaseId: 2));
        await repo.remove('del');
        expect(await repo.getAll(), hasLength(1));
        expect((await repo.getAll()).first.id, 'keep');
      });
    });

    group('field round-trip', () {
      test('preserves all optional fields through add and getById', () async {
        final item = CollectionItem(
          id: 'full',
          discogsReleaseId: 1,
          artist: 'Artist',
          title: 'Title',
          mediaCondition: RecordCondition.mint,
          sleeveCondition: RecordCondition.nearMint,
          tags: const ['tag1', 'tag2'],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
          label: 'Label',
          catno: 'CAT-001',
          format: 'Vinyl, LP',
          country: 'US',
          year: 2020,
          coverUrl: 'https://example.com/cover.jpg',
          notes: 'Some notes.',
          storageLocation: 'Shelf B',
        );
        await repo.add(item);
        final fetched = await repo.getById('full');
        expect(fetched!.label, 'Label');
        expect(fetched.catno, 'CAT-001');
        expect(fetched.format, 'Vinyl, LP');
        expect(fetched.country, 'US');
        expect(fetched.year, 2020);
        expect(fetched.coverUrl, 'https://example.com/cover.jpg');
        expect(fetched.notes, 'Some notes.');
        expect(fetched.storageLocation, 'Shelf B');
        expect(fetched.tags, ['tag1', 'tag2']);
        expect(fetched.mediaCondition, RecordCondition.mint);
        expect(fetched.sleeveCondition, RecordCondition.nearMint);
      });

      test('preserves null optional fields', () async {
        await repo.add(makeItem(id: 'nulls'));
        final fetched = await repo.getById('nulls');
        expect(fetched!.label, isNull);
        expect(fetched.catno, isNull);
        expect(fetched.format, isNull);
        expect(fetched.country, isNull);
        expect(fetched.year, isNull);
        expect(fetched.coverUrl, isNull);
        expect(fetched.notes, isNull);
        expect(fetched.storageLocation, isNull);
      });
    });
  });
}

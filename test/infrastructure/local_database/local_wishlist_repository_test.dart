import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/local_wishlist_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

WishlistItem makeItem({
  String id = 'wish-1',
  int discogsReleaseId = 249504,
  String artist = 'Miles Davis',
  String title = 'Kind Of Blue',
  WishlistPriority priority = WishlistPriority.medium,
}) =>
    WishlistItem(
      id: id,
      discogsReleaseId: discogsReleaseId,
      artist: artist,
      title: title,
      priority: priority,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('LocalWishlistRepository', () {
    late AppDatabase db;
    late LocalWishlistRepository repo;

    setUp(() {
      db = openTestDb();
      repo = LocalWishlistRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('add and getAll', () {
      test('returns empty list when wishlist is empty', () async {
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
      test('returns false when wishlist is empty', () async {
        expect(await repo.containsRelease(249504), isFalse);
      });

      test('returns true when release is in wishlist', () async {
        await repo.add(makeItem(discogsReleaseId: 249504));
        expect(await repo.containsRelease(249504), isTrue);
      });

      test('returns false when a different release is in wishlist', () async {
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
        expect(fetched.priority, original.priority);
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
        final item = WishlistItem(
          id: 'full',
          discogsReleaseId: 1,
          artist: 'Artist',
          title: 'Title',
          priority: WishlistPriority.mustHave,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
          label: 'Label',
          catno: 'CAT-001',
          format: 'Vinyl, LP',
          country: 'US',
          year: 2020,
          coverUrl: 'https://example.com/cover.jpg',
          targetPrice: 42.50,
          notes: 'Original pressing only.',
        );
        await repo.add(item);
        final fetched = await repo.getById('full');
        expect(fetched!.label, 'Label');
        expect(fetched.catno, 'CAT-001');
        expect(fetched.format, 'Vinyl, LP');
        expect(fetched.country, 'US');
        expect(fetched.year, 2020);
        expect(fetched.coverUrl, 'https://example.com/cover.jpg');
        expect(fetched.targetPrice, 42.50);
        expect(fetched.priority, WishlistPriority.mustHave);
        expect(fetched.notes, 'Original pressing only.');
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
        expect(fetched.targetPrice, isNull);
        expect(fetched.notes, isNull);
      });
    });
  });
}

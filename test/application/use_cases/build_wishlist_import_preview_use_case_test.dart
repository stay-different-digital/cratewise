import 'package:cratewise/application/use_cases/build_wishlist_import_preview_use_case.dart';
import 'package:cratewise/domain/models/wishlist_import_preview.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_wantlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeWishlistRepository implements WishlistRepository {
  FakeWishlistRepository({Set<int>? existingReleaseIds})
    : _ids = existingReleaseIds ?? {};

  final Set<int> _ids;
  int containsReleaseCallCount = 0;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async {
    containsReleaseCallCount++;
    return _ids.contains(discogsReleaseId);
  }

  @override
  Future<List<WishlistItem>> getAll() async => [];
  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DiscogsWantlistItemDto makeItem({
  int releaseId = 3003339,
  String title = 'The Bride Stripped Bare',
  String artist = 'Bryan Ferry',
  int? year = 1978,
  String? thumbUrl = 'https://i.discogs.com/bride_150.jpg',
  String? notes,
}) => DiscogsWantlistItemDto(
  releaseId: releaseId,
  dateAdded: '2023-04-10T09:15:00-07:00',
  rating: 3,
  title: title,
  artist: artist,
  label: 'Polydor',
  catno: '2302 069',
  format: 'Vinyl, LP, Album',
  genres: const ['Rock'],
  year: year,
  thumbUrl: thumbUrl,
  notes: notes,
);

BuildWishlistImportPreviewUseCase makeUseCase(FakeWishlistRepository repo) =>
    BuildWishlistImportPreviewUseCase(repo);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BuildWishlistImportPreviewUseCase', () {
    group('empty input', () {
      test('returns WishlistImportPreview for empty list', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(repo).execute([]);
        expect(preview, isA<WishlistImportPreview>());
      });

      test('totalCount is 0 for empty list', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(repo).execute([]);
        expect(preview.totalCount, 0);
      });

      test('all counts are 0 for empty list', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(repo).execute([]);
        expect(preview.newCount, 0);
        expect(preview.duplicateCount, 0);
        expect(preview.invalidCount, 0);
      });
    });

    group('new items', () {
      test('classifies item not in local wishlist as NewWishlistRow', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(repo).execute([makeItem()]);
        expect(preview.rows.first, isA<NewWishlistRow>());
      });

      test('newCount is 1 for single new item', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(repo).execute([makeItem()]);
        expect(preview.newCount, 1);
      });

      test('classifies multiple new items correctly', () async {
        final repo = FakeWishlistRepository();
        final items = [
          makeItem(releaseId: 1, title: 'Album A'),
          makeItem(releaseId: 2, title: 'Album B'),
          makeItem(releaseId: 3, title: 'Album C'),
        ];
        final preview = await makeUseCase(repo).execute(items);
        expect(preview.newCount, 3);
        expect(preview.rows.every((r) => r is NewWishlistRow), isTrue);
      });
    });

    group('duplicate items', () {
      test(
        'classifies item already in wishlist as DuplicateWishlistRow',
        () async {
          final repo = FakeWishlistRepository(existingReleaseIds: {3003339});
          final preview = await makeUseCase(repo).execute([makeItem()]);
          expect(preview.rows.first, isA<DuplicateWishlistRow>());
        },
      );

      test('duplicateCount is 1 for single duplicate', () async {
        final repo = FakeWishlistRepository(existingReleaseIds: {3003339});
        final preview = await makeUseCase(repo).execute([makeItem()]);
        expect(preview.duplicateCount, 1);
      });

      test('duplicate detection is by release ID not by title', () async {
        final repo = FakeWishlistRepository(existingReleaseIds: {3003339});
        final sameIdDifferentTitle = makeItem(
          releaseId: 3003339,
          title: 'Different Title',
        );
        final preview = await makeUseCase(repo).execute([sameIdDifferentTitle]);
        expect(preview.rows.first, isA<DuplicateWishlistRow>());
      });

      test(
        'different release ID with same title is classified as new',
        () async {
          final repo = FakeWishlistRepository(existingReleaseIds: {3003339});
          final differentId = makeItem(
            releaseId: 999999,
            title: 'The Bride Stripped Bare',
          );
          final preview = await makeUseCase(repo).execute([differentId]);
          expect(preview.rows.first, isA<NewWishlistRow>());
        },
      );
    });

    group('invalid items', () {
      test('classifies item with releaseId 0 as InvalidWishlistRow', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(
          repo,
        ).execute([makeItem(releaseId: 0)]);
        expect(preview.rows.first, isA<InvalidWishlistRow>());
      });

      test('reason for zero releaseId mentions release ID', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(
          repo,
        ).execute([makeItem(releaseId: 0)]);
        final row = preview.rows.first as InvalidWishlistRow;
        expect(row.reason.toLowerCase(), contains('release id'));
      });

      test('classifies item with empty title as InvalidWishlistRow', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(repo).execute([makeItem(title: '')]);
        expect(preview.rows.first, isA<InvalidWishlistRow>());
      });

      test('classifies item with whitespace-only title as invalid', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(
          repo,
        ).execute([makeItem(title: '   ')]);
        expect(preview.rows.first, isA<InvalidWishlistRow>());
      });

      test('reason for empty title mentions title', () async {
        final repo = FakeWishlistRepository();
        final preview = await makeUseCase(repo).execute([makeItem(title: '')]);
        final row = preview.rows.first as InvalidWishlistRow;
        expect(row.reason.toLowerCase(), contains('title'));
      });

      test('invalidCount counts correctly', () async {
        final repo = FakeWishlistRepository();
        final items = [makeItem(releaseId: 0), makeItem(title: '')];
        final preview = await makeUseCase(repo).execute(items);
        expect(preview.invalidCount, 2);
      });

      test(
        'item with missing artist but valid title is classified as new',
        () async {
          final repo = FakeWishlistRepository();
          final noArtist = makeItem(artist: '');
          final preview = await makeUseCase(repo).execute([noArtist]);
          expect(preview.rows.first, isA<NewWishlistRow>());
        },
      );
    });

    group('mixed input', () {
      test('correctly classifies mix of new, duplicate, and invalid', () async {
        final repo = FakeWishlistRepository(existingReleaseIds: {3003339});
        final items = [
          makeItem(
            releaseId: 3003339,
            title: 'The Bride Stripped Bare',
          ), // duplicate
          makeItem(releaseId: 111111, title: 'Avalon'), // new
          makeItem(releaseId: 0), // invalid
          makeItem(title: ''), // invalid
        ];
        final preview = await makeUseCase(repo).execute(items);
        expect(preview.totalCount, 4);
        expect(preview.duplicateCount, 1);
        expect(preview.newCount, 1);
        expect(preview.invalidCount, 2);
      });

      test('preserves order of rows matching order of input', () async {
        final repo = FakeWishlistRepository(existingReleaseIds: {3003339});
        final items = [
          makeItem(releaseId: 111111, title: 'New Album'),
          makeItem(releaseId: 3003339, title: 'Existing Album'),
          makeItem(releaseId: 0),
        ];
        final preview = await makeUseCase(repo).execute(items);
        expect(preview.rows[0], isA<NewWishlistRow>());
        expect(preview.rows[1], isA<DuplicateWishlistRow>());
        expect(preview.rows[2], isA<InvalidWishlistRow>());
      });
    });

    group('field preservation', () {
      test('new row carries correct fields from DTO', () async {
        final repo = FakeWishlistRepository();
        final item = makeItem(
          releaseId: 3003339,
          title: 'The Bride Stripped Bare',
          artist: 'Bryan Ferry',
          year: 1978,
          thumbUrl: 'https://i.discogs.com/bride_150.jpg',
        );
        final preview = await makeUseCase(repo).execute([item]);
        final row = preview.rows.first as NewWishlistRow;
        expect(row.releaseId, 3003339);
        expect(row.title, 'The Bride Stripped Bare');
        expect(row.artist, 'Bryan Ferry');
        expect(row.year, 1978);
        expect(row.thumbUrl, 'https://i.discogs.com/bride_150.jpg');
      });

      test('duplicate row carries correct releaseId and title', () async {
        final repo = FakeWishlistRepository(existingReleaseIds: {3003339});
        final preview = await makeUseCase(repo).execute([makeItem()]);
        final row = preview.rows.first as DuplicateWishlistRow;
        expect(row.releaseId, 3003339);
        expect(row.title, 'The Bride Stripped Bare');
        expect(row.artist, 'Bryan Ferry');
      });

      test(
        'invalid row carries releaseId 0 when releaseId is missing',
        () async {
          final repo = FakeWishlistRepository();
          final preview = await makeUseCase(
            repo,
          ).execute([makeItem(releaseId: 0)]);
          final row = preview.rows.first as InvalidWishlistRow;
          expect(row.releaseId, 0);
        },
      );

      test('rows carry null thumbUrl when DTO has no thumb', () async {
        final repo = FakeWishlistRepository();
        final item = makeItem(thumbUrl: null);
        final preview = await makeUseCase(repo).execute([item]);
        expect(preview.rows.first.thumbUrl, isNull);
      });

      test('rows carry null year when DTO has no year', () async {
        final repo = FakeWishlistRepository();
        final item = makeItem(year: null);
        final preview = await makeUseCase(repo).execute([item]);
        expect(preview.rows.first.year, isNull);
      });
    });

    group('no wishlist mutations', () {
      test('does not mutate local wishlist', () async {
        final repo = FakeWishlistRepository();
        await makeUseCase(repo).execute([
          makeItem(releaseId: 1),
          makeItem(releaseId: 2),
          makeItem(releaseId: 3),
        ]);
        expect(await repo.getAll(), isEmpty);
      });

      test(
        'does not call containsRelease for item with zero releaseId',
        () async {
          final repo = FakeWishlistRepository();
          await makeUseCase(repo).execute([makeItem(releaseId: 0)]);
          expect(repo.containsReleaseCallCount, 0);
        },
      );

      test('does not call containsRelease for item with empty title', () async {
        final repo = FakeWishlistRepository();
        await makeUseCase(repo).execute([makeItem(title: '')]);
        expect(repo.containsReleaseCallCount, 0);
      });
    });

    group('security', () {
      test('invalid row reason does not contain token or secret', () async {
        final repo = FakeWishlistRepository();
        final items = [makeItem(releaseId: 0), makeItem(title: '')];
        final preview = await makeUseCase(repo).execute(items);
        for (final row in preview.rows) {
          if (row is InvalidWishlistRow) {
            expect(row.reason.toLowerCase(), isNot(contains('token')));
            expect(row.reason.toLowerCase(), isNot(contains('secret')));
          }
        }
      });
    });
  });
}

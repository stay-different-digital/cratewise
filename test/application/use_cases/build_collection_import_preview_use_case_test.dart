import 'package:cratewise/application/use_cases/build_collection_import_preview_use_case.dart';
import 'package:cratewise/domain/models/collection_import_preview.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/pending_discogs_deletion.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/pending_discogs_deletion_repository.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_collection_item.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  FakeCollectionRepository({Set<int>? existingReleaseIds})
    : _ids = existingReleaseIds ?? {};

  final Set<int> _ids;
  int containsReleaseCallCount = 0;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async {
    containsReleaseCallCount++;
    return _ids.contains(discogsReleaseId);
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DiscogsCollectionItemDto makeItem({
  int releaseId = 249504,
  int instanceId = 99999,
  String title = 'Kind Of Blue',
  String artist = 'Miles Davis',
  int? year = 1959,
  String? thumbUrl = 'https://i.discogs.com/cover_150.jpg',
}) => DiscogsCollectionItemDto(
  releaseId: releaseId,
  instanceId: instanceId,
  dateAdded: '2023-01-15T10:30:00-08:00',
  rating: 4,
  folderId: 1,
  title: title,
  artist: artist,
  label: 'Columbia',
  catno: 'CL 1355',
  format: 'Vinyl, LP',
  genres: const ['Jazz'],
  year: year,
  thumbUrl: thumbUrl,
);

class _FakeDeletionRepository implements PendingDiscogsDeletionRepository {
  @override
  Future<void> deleteAllByType(DeletionEntityType entityType) async {}
  _FakeDeletionRepository({Set<int>? pendingReleaseIds})
    : _ids = pendingReleaseIds ?? {};
  final Set<int> _ids;

  @override
  Future<bool> containsRelease(int id, DeletionEntityType type) async =>
      type == DeletionEntityType.collection && _ids.contains(id);
  @override
  Future<void> add(PendingDiscogsDeletion deletion) async {}
  @override
  Future<List<PendingDiscogsDeletion>> getByType(
    DeletionEntityType type,
  ) async => [];
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> removeByRelease(int id, DeletionEntityType type) async {}
}

BuildCollectionImportPreviewUseCase makeUseCase(
  FakeCollectionRepository repo, {
  PendingDiscogsDeletionRepository? deletionRepository,
}) => BuildCollectionImportPreviewUseCase(
  repo,
  deletionRepository: deletionRepository,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BuildCollectionImportPreviewUseCase', () {
    group('empty input', () {
      test('returns CollectionImportPreview for empty list', () async {
        final repo = FakeCollectionRepository();
        final useCase = makeUseCase(repo);
        final preview = await useCase.execute([]);
        expect(preview, isA<CollectionImportPreview>());
      });

      test('totalCount is 0 for empty list', () async {
        final repo = FakeCollectionRepository();
        final preview = await makeUseCase(repo).execute([]);
        expect(preview.totalCount, 0);
      });

      test('all counts are 0 for empty list', () async {
        final repo = FakeCollectionRepository();
        final preview = await makeUseCase(repo).execute([]);
        expect(preview.newCount, 0);
        expect(preview.duplicateCount, 0);
        expect(preview.invalidCount, 0);
      });
    });

    group('new items', () {
      test(
        'classifies item not in local collection as NewCollectionRow',
        () async {
          final repo = FakeCollectionRepository();
          final preview = await makeUseCase(repo).execute([makeItem()]);
          expect(preview.rows.first, isA<NewCollectionRow>());
        },
      );

      test('newCount is 1 for single new item', () async {
        final repo = FakeCollectionRepository();
        final preview = await makeUseCase(repo).execute([makeItem()]);
        expect(preview.newCount, 1);
      });

      test('carries the Discogs instance id onto the row (US-72)', () async {
        final repo = FakeCollectionRepository();
        final preview = await makeUseCase(
          repo,
        ).execute([makeItem(instanceId: 5551234)]);
        expect((preview.rows.first as NewCollectionRow).instanceId, 5551234);
      });
    });

    group('pending-deletion conflicts (US-72)', () {
      test(
        'classifies a release with a pending deletion as a conflict',
        () async {
          final repo = FakeCollectionRepository();
          final preview = await makeUseCase(
            repo,
            deletionRepository: _FakeDeletionRepository(
              pendingReleaseIds: {249504},
            ),
          ).execute([makeItem(releaseId: 249504)]);

          expect(preview.rows.first, isA<ConflictCollectionRow>());
          expect(preview.conflictCount, 1);
          expect(preview.newCount, 0);
        },
      );

      test('a conflict takes precedence over a local duplicate', () async {
        final repo = FakeCollectionRepository(existingReleaseIds: {249504});
        final preview = await makeUseCase(
          repo,
          deletionRepository: _FakeDeletionRepository(
            pendingReleaseIds: {249504},
          ),
        ).execute([makeItem(releaseId: 249504)]);

        expect(preview.rows.first, isA<ConflictCollectionRow>());
        expect(preview.duplicateCount, 0);
      });

      test('no conflict when the release has no pending deletion', () async {
        final repo = FakeCollectionRepository();
        final preview = await makeUseCase(
          repo,
          deletionRepository: _FakeDeletionRepository(),
        ).execute([makeItem(releaseId: 249504)]);

        expect(preview.conflictCount, 0);
        expect(preview.rows.first, isA<NewCollectionRow>());
      });

      test('classifies multiple new items correctly', () async {
        final repo = FakeCollectionRepository();
        final items = [
          makeItem(releaseId: 1, title: 'Album A'),
          makeItem(releaseId: 2, title: 'Album B'),
          makeItem(releaseId: 3, title: 'Album C'),
        ];
        final preview = await makeUseCase(repo).execute(items);
        expect(preview.newCount, 3);
        expect(preview.rows.every((r) => r is NewCollectionRow), isTrue);
      });
    });

    group('duplicate items', () {
      test(
        'classifies item already in collection as DuplicateCollectionRow',
        () async {
          final repo = FakeCollectionRepository(existingReleaseIds: {249504});
          final preview = await makeUseCase(repo).execute([makeItem()]);
          expect(preview.rows.first, isA<DuplicateCollectionRow>());
        },
      );

      test('duplicateCount is 1 for single duplicate', () async {
        final repo = FakeCollectionRepository(existingReleaseIds: {249504});
        final preview = await makeUseCase(repo).execute([makeItem()]);
        expect(preview.duplicateCount, 1);
      });

      test('duplicate detection is by release ID not by title', () async {
        final repo = FakeCollectionRepository(existingReleaseIds: {249504});
        final sameIdDifferentTitle = makeItem(
          releaseId: 249504,
          title: 'Different Title',
        );
        final preview = await makeUseCase(repo).execute([sameIdDifferentTitle]);
        expect(preview.rows.first, isA<DuplicateCollectionRow>());
      });

      test(
        'different release ID with same title is classified as new',
        () async {
          final repo = FakeCollectionRepository(existingReleaseIds: {249504});
          final differentId = makeItem(
            releaseId: 111111,
            title: 'Kind Of Blue',
          );
          final preview = await makeUseCase(repo).execute([differentId]);
          expect(preview.rows.first, isA<NewCollectionRow>());
        },
      );
    });

    group('invalid items', () {
      test(
        'classifies item with releaseId 0 as InvalidCollectionRow',
        () async {
          final repo = FakeCollectionRepository();
          final preview = await makeUseCase(
            repo,
          ).execute([makeItem(releaseId: 0)]);
          expect(preview.rows.first, isA<InvalidCollectionRow>());
        },
      );

      test('reason for zero releaseId mentions release ID', () async {
        final repo = FakeCollectionRepository();
        final preview = await makeUseCase(
          repo,
        ).execute([makeItem(releaseId: 0)]);
        final row = preview.rows.first as InvalidCollectionRow;
        expect(row.reason.toLowerCase(), contains('release id'));
      });

      test(
        'classifies item with empty title as InvalidCollectionRow',
        () async {
          final repo = FakeCollectionRepository();
          final preview = await makeUseCase(
            repo,
          ).execute([makeItem(title: '')]);
          expect(preview.rows.first, isA<InvalidCollectionRow>());
        },
      );

      test('classifies item with whitespace-only title as invalid', () async {
        final repo = FakeCollectionRepository();
        final preview = await makeUseCase(
          repo,
        ).execute([makeItem(title: '   ')]);
        expect(preview.rows.first, isA<InvalidCollectionRow>());
      });

      test('reason for empty title mentions title', () async {
        final repo = FakeCollectionRepository();
        final preview = await makeUseCase(repo).execute([makeItem(title: '')]);
        final row = preview.rows.first as InvalidCollectionRow;
        expect(row.reason.toLowerCase(), contains('title'));
      });

      test('invalidCount counts correctly', () async {
        final repo = FakeCollectionRepository();
        final items = [makeItem(releaseId: 0), makeItem(title: '')];
        final preview = await makeUseCase(repo).execute(items);
        expect(preview.invalidCount, 2);
      });

      test(
        'item with missing artist but valid title is classified as new',
        () async {
          final repo = FakeCollectionRepository();
          final noArtist = makeItem(artist: '');
          final preview = await makeUseCase(repo).execute([noArtist]);
          expect(preview.rows.first, isA<NewCollectionRow>());
        },
      );
    });

    group('mixed input', () {
      test('correctly classifies mix of new, duplicate, and invalid', () async {
        final repo = FakeCollectionRepository(existingReleaseIds: {249504});
        final items = [
          makeItem(releaseId: 249504, title: 'Kind Of Blue'), // duplicate
          makeItem(releaseId: 111111, title: 'A Love Supreme'), // new
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
        final repo = FakeCollectionRepository(existingReleaseIds: {249504});
        final items = [
          makeItem(releaseId: 111111, title: 'New Album'),
          makeItem(releaseId: 249504, title: 'Existing Album'),
          makeItem(releaseId: 0),
        ];
        final preview = await makeUseCase(repo).execute(items);
        expect(preview.rows[0], isA<NewCollectionRow>());
        expect(preview.rows[1], isA<DuplicateCollectionRow>());
        expect(preview.rows[2], isA<InvalidCollectionRow>());
      });
    });

    group('field preservation', () {
      test('new row carries correct fields from DTO', () async {
        final repo = FakeCollectionRepository();
        final item = makeItem(
          releaseId: 249504,
          title: 'Kind Of Blue',
          artist: 'Miles Davis',
          year: 1959,
          thumbUrl: 'https://i.discogs.com/cover.jpg',
        );
        final preview = await makeUseCase(repo).execute([item]);
        final row = preview.rows.first as NewCollectionRow;
        expect(row.releaseId, 249504);
        expect(row.title, 'Kind Of Blue');
        expect(row.artist, 'Miles Davis');
        expect(row.year, 1959);
        expect(row.thumbUrl, 'https://i.discogs.com/cover.jpg');
      });

      test('duplicate row carries correct releaseId', () async {
        final repo = FakeCollectionRepository(existingReleaseIds: {249504});
        final preview = await makeUseCase(repo).execute([makeItem()]);
        final row = preview.rows.first as DuplicateCollectionRow;
        expect(row.releaseId, 249504);
        expect(row.title, 'Kind Of Blue');
        expect(row.artist, 'Miles Davis');
      });

      test(
        'invalid row carries releaseId 0 when releaseId is missing',
        () async {
          final repo = FakeCollectionRepository();
          final preview = await makeUseCase(
            repo,
          ).execute([makeItem(releaseId: 0)]);
          final row = preview.rows.first as InvalidCollectionRow;
          expect(row.releaseId, 0);
        },
      );

      test('rows carry null thumbUrl when DTO has no thumb', () async {
        final repo = FakeCollectionRepository();
        final item = makeItem(thumbUrl: null);
        final preview = await makeUseCase(repo).execute([item]);
        expect(preview.rows.first.thumbUrl, isNull);
      });

      test('rows carry null year when DTO has no year', () async {
        final repo = FakeCollectionRepository();
        final item = makeItem(year: null);
        final preview = await makeUseCase(repo).execute([item]);
        expect(preview.rows.first.year, isNull);
      });
    });

    group('no collection mutations', () {
      test('does not mutate local collection', () async {
        final repo = FakeCollectionRepository();
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
          final repo = FakeCollectionRepository();
          await makeUseCase(repo).execute([makeItem(releaseId: 0)]);
          expect(repo.containsReleaseCallCount, 0);
        },
      );

      test('does not call containsRelease for item with empty title', () async {
        final repo = FakeCollectionRepository();
        await makeUseCase(repo).execute([makeItem(title: '')]);
        expect(repo.containsReleaseCallCount, 0);
      });
    });

    group('security', () {
      test('invalid row reason does not contain token or secret', () async {
        final repo = FakeCollectionRepository();
        final items = [makeItem(releaseId: 0), makeItem(title: '')];
        final preview = await makeUseCase(repo).execute(items);
        for (final row in preview.rows) {
          if (row is InvalidCollectionRow) {
            expect(row.reason.toLowerCase(), isNot(contains('token')));
            expect(row.reason.toLowerCase(), isNot(contains('secret')));
          }
        }
      });
    });
  });
}

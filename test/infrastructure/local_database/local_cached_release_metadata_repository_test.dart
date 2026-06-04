import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/release_detail.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/local_cached_release_metadata_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

CachedReleaseMetadata _makeMeta({
  int discogsReleaseId = 249504,
  String artist = 'Miles Davis',
  String title = 'Kind Of Blue',
  String? label = 'Columbia',
  String? catno = 'CL 1355',
  String? format = 'Vinyl, LP',
  String? country = 'US',
  int? year = 1959,
  List<String>? genres,
  List<String>? styles,
  List<ReleaseTrack>? tracklist,
  String? notes,
  List<ReleaseIdentifier>? identifiers,
  String? coverUrl,
  DateTime? fetchedAt,
  String cacheSource = 'discogs_api',
  SyncStatus syncStatus = SyncStatus.localOnly,
}) => CachedReleaseMetadata(
  discogsReleaseId: discogsReleaseId,
  artist: artist,
  title: title,
  label: label,
  catno: catno,
  format: format,
  country: country,
  year: year,
  genres: genres ?? ['Jazz'],
  styles: styles ?? ['Modal'],
  tracklist:
      tracklist ??
      const [
        ReleaseTrack(position: 'A1', title: 'So What', duration: '9:22'),
        ReleaseTrack(
          position: 'A2',
          title: 'Freddie Freeloader',
          duration: '9:46',
        ),
      ],
  notes: notes,
  identifiers:
      identifiers ??
      const [ReleaseIdentifier(type: 'Barcode', value: '074646440124')],
  coverUrl: coverUrl,
  fetchedAt: fetchedAt ?? DateTime(2026, 1, 1, 12),
  cacheSource: cacheSource,
  syncStatus: syncStatus,
);

void main() {
  group('LocalCachedReleaseMetadataRepository', () {
    late AppDatabase db;
    late LocalCachedReleaseMetadataRepository repo;

    setUp(() {
      db = _openTestDb();
      repo = LocalCachedReleaseMetadataRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('getByReleaseId', () {
      test('returns null when cache is empty', () async {
        expect(await repo.getByReleaseId(249504), isNull);
      });

      test('returns null for unknown release ID', () async {
        await repo.save(_makeMeta(discogsReleaseId: 1));
        expect(await repo.getByReleaseId(9999), isNull);
      });
    });

    group('save and getByReleaseId', () {
      test('saved metadata can be retrieved by release ID', () async {
        await repo.save(_makeMeta());
        final result = await repo.getByReleaseId(249504);
        expect(result, isNotNull);
        expect(result!.title, 'Kind Of Blue');
      });

      test('round-trips all scalar fields', () async {
        final meta = _makeMeta(
          artist: 'Miles Davis',
          title: 'Kind Of Blue',
          label: 'Columbia',
          catno: 'CL 1355',
          format: 'Vinyl, LP',
          country: 'US',
          year: 1959,
          coverUrl: 'https://example.com/cover.jpg',
          cacheSource: 'discogs_api',
          syncStatus: SyncStatus.synced,
        );
        await repo.save(meta);
        final result = await repo.getByReleaseId(249504);
        expect(result!.artist, 'Miles Davis');
        expect(result.label, 'Columbia');
        expect(result.catno, 'CL 1355');
        expect(result.format, 'Vinyl, LP');
        expect(result.country, 'US');
        expect(result.year, 1959);
        expect(result.coverUrl, 'https://example.com/cover.jpg');
        expect(result.cacheSource, 'discogs_api');
        expect(result.syncStatus, SyncStatus.synced);
      });

      test('round-trips genres list', () async {
        await repo.save(_makeMeta(genres: ['Jazz', 'Classical'], styles: []));
        final result = await repo.getByReleaseId(249504);
        expect(result!.genres, ['Jazz', 'Classical']);
      });

      test('round-trips styles list', () async {
        await repo.save(_makeMeta(styles: ['Modal', 'Post-Bop']));
        final result = await repo.getByReleaseId(249504);
        expect(result!.styles, ['Modal', 'Post-Bop']);
      });

      test(
        'round-trips full tracklist with position, title and duration',
        () async {
          await repo.save(
            _makeMeta(
              tracklist: const [
                ReleaseTrack(
                  position: 'A1',
                  title: 'So What',
                  duration: '9:22',
                ),
                ReleaseTrack(
                  position: 'A2',
                  title: 'Freddie Freeloader',
                  duration: '9:46',
                ),
                ReleaseTrack(
                  position: 'B1',
                  title: 'Blue in Green',
                  duration: '5:37',
                ),
              ],
            ),
          );
          final result = await repo.getByReleaseId(249504);
          expect(result!.tracklist, hasLength(3));
          expect(result.tracklist[0].position, 'A1');
          expect(result.tracklist[0].title, 'So What');
          expect(result.tracklist[0].duration, '9:22');
          expect(result.tracklist[2].position, 'B1');
          expect(result.tracklist[2].title, 'Blue in Green');
          expect(result.tracklist[2].duration, '5:37');
        },
      );

      test('round-trips full identifiers list with type and value', () async {
        await repo.save(
          _makeMeta(
            identifiers: const [
              ReleaseIdentifier(type: 'Barcode', value: '123456789'),
              ReleaseIdentifier(type: 'Matrix / Runout', value: 'CL 1355-A'),
            ],
          ),
        );
        final result = await repo.getByReleaseId(249504);
        expect(result!.identifiers, hasLength(2));
        expect(result.identifiers[0].type, 'Barcode');
        expect(result.identifiers[0].value, '123456789');
        expect(result.identifiers[1].type, 'Matrix / Runout');
        expect(result.identifiers[1].value, 'CL 1355-A');
      });

      test('empty lists round-trip as empty lists', () async {
        await repo.save(
          _makeMeta(genres: [], styles: [], tracklist: [], identifiers: []),
        );
        final result = await repo.getByReleaseId(249504);
        expect(result!.genres, isEmpty);
        expect(result.styles, isEmpty);
        expect(result.tracklist, isEmpty);
        expect(result.identifiers, isEmpty);
      });

      test('preserves fetchedAt timestamp', () async {
        final ts = DateTime(2026, 3, 15, 10, 30);
        await repo.save(_makeMeta(fetchedAt: ts));
        final result = await repo.getByReleaseId(249504);
        expect(result!.fetchedAt, ts);
      });

      test('nullable fields preserved when null', () async {
        await repo.save(
          _makeMeta(
            label: null,
            catno: null,
            format: null,
            country: null,
            year: null,
            notes: null,
            coverUrl: null,
          ),
        );
        final result = await repo.getByReleaseId(249504);
        expect(result!.label, isNull);
        expect(result.catno, isNull);
        expect(result.format, isNull);
        expect(result.country, isNull);
        expect(result.year, isNull);
        expect(result.notes, isNull);
        expect(result.coverUrl, isNull);
      });
    });

    group('save upsert', () {
      test('second save for same release ID updates the record', () async {
        await repo.save(_makeMeta(title: 'Old Title'));
        await repo.save(_makeMeta(title: 'New Title'));
        final result = await repo.getByReleaseId(249504);
        expect(result!.title, 'New Title');
      });

      test('upsert updates fetchedAt', () async {
        final first = DateTime(2026, 1, 1);
        final second = DateTime(2026, 6, 1);
        await repo.save(_makeMeta(fetchedAt: first));
        await repo.save(_makeMeta(fetchedAt: second));
        final result = await repo.getByReleaseId(249504);
        expect(result!.fetchedAt, second);
      });
    });

    group('remove', () {
      test('remove deletes the record', () async {
        await repo.save(_makeMeta());
        await repo.remove(249504);
        expect(await repo.getByReleaseId(249504), isNull);
      });

      test('removing non-existent ID does not throw', () async {
        await expectLater(repo.remove(9999), completes);
      });
    });
  });
}

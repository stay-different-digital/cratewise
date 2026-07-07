import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/collection_stats.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _item({
  String id = 'x',
  int discogsReleaseId = 1,
  String artist = 'Artist',
  String? label,
  String? format,
  int? year,
  String? coverUrl = 'https://cover.jpg',
}) => CollectionItem(
  id: id,
  discogsReleaseId: discogsReleaseId,
  artist: artist,
  title: 'Title',
  label: label,
  format: format,
  year: year,
  coverUrl: coverUrl,
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: const [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  group('CollectionStats.from (US-115)', () {
    test('empty list returns all zeros and empty distributions', () {
      final s = CollectionStats.from([]);
      expect(s.totalItems, 0);
      expect(s.uniqueArtists, 0);
      expect(s.uniqueLabels, 0);
      expect(s.missingCover, 0);
      expect(s.missingYear, 0);
      expect(s.byDecade, isEmpty);
      expect(s.byFormat, isEmpty);
    });

    test('counts total items', () {
      final s = CollectionStats.from([_item(id: '1'), _item(id: '2')]);
      expect(s.totalItems, 2);
    });

    test('counts unique artists (case-sensitive)', () {
      final s = CollectionStats.from([
        _item(id: '1', artist: 'Miles Davis'),
        _item(id: '2', artist: 'Miles Davis'),
        _item(id: '3', artist: 'John Coltrane'),
      ]);
      expect(s.uniqueArtists, 2);
    });

    test('counts unique non-null labels', () {
      final s = CollectionStats.from([
        _item(id: '1', label: 'Columbia'),
        _item(id: '2', label: 'Columbia'),
        _item(id: '3', label: 'Blue Note'),
        _item(id: '4', label: null),
      ]);
      expect(s.uniqueLabels, 2);
    });

    test('null label does not count toward uniqueLabels', () {
      final s = CollectionStats.from([_item(id: '1', label: null)]);
      expect(s.uniqueLabels, 0);
    });

    test('groups year into decade', () {
      final s = CollectionStats.from([
        _item(id: '1', year: 1986),
        _item(id: '2', year: 1981),
        _item(id: '3', year: 1990),
      ]);
      expect(s.byDecade['1980s'], 2);
      expect(s.byDecade['1990s'], 1);
    });

    test('groups null year as Unknown', () {
      final s = CollectionStats.from([
        _item(id: '1', year: null),
        _item(id: '2', year: null),
      ]);
      expect(s.byDecade['Unknown'], 2);
    });

    test('decades sorted chronologically with Unknown last', () {
      final s = CollectionStats.from([
        _item(id: '1', year: null),
        _item(id: '2', year: 1990),
        _item(id: '3', year: 1960),
        _item(id: '4', year: 1970),
      ]);
      final keys = s.byDecade.keys.toList();
      expect(keys, ['1960s', '1970s', '1990s', 'Unknown']);
    });

    test('extracts primary format from comma-separated string', () {
      final s = CollectionStats.from([
        _item(id: '1', format: 'Vinyl, LP, Album'),
        _item(id: '2', format: 'Vinyl, 7"'),
        _item(id: '3', format: 'CD'),
      ]);
      expect(s.byFormat['Vinyl'], 2);
      expect(s.byFormat['CD'], 1);
    });

    test('groups null format as Unknown', () {
      final s = CollectionStats.from([_item(id: '1', format: null)]);
      expect(s.byFormat['Unknown'], 1);
    });

    test('formats sorted by count descending', () {
      final s = CollectionStats.from([
        _item(id: '1', format: 'CD'),
        _item(id: '2', format: 'Vinyl, LP'),
        _item(id: '3', format: 'Vinyl, 7"'),
      ]);
      expect(s.byFormat.keys.first, 'Vinyl');
    });

    test('counts missing cover (null coverUrl)', () {
      final s = CollectionStats.from([
        _item(id: '1', coverUrl: null),
        _item(id: '2', coverUrl: 'https://img.jpg'),
        _item(id: '3', coverUrl: null),
      ]);
      expect(s.missingCover, 2);
    });

    test('counts missing year (null year)', () {
      final s = CollectionStats.from([
        _item(id: '1', year: null),
        _item(id: '2', year: 1985),
      ]);
      expect(s.missingYear, 1);
    });

    test('all missing: every field null where nullable', () {
      final s = CollectionStats.from([
        _item(id: '1', label: null, format: null, year: null, coverUrl: null),
      ]);
      expect(s.totalItems, 1);
      expect(s.uniqueLabels, 0);
      expect(s.byDecade['Unknown'], 1);
      expect(s.byFormat['Unknown'], 1);
      expect(s.missingCover, 1);
      expect(s.missingYear, 1);
    });

    test('byGenre and byStyle are empty when no metadata provided', () {
      final s = CollectionStats.from([_item(id: '1')]);
      expect(s.byGenre, isEmpty);
      expect(s.byStyle, isEmpty);
    });

    test('counts genres from metadata', () {
      final item = _item(id: '1', discogsReleaseId: 42);
      final meta = _meta(
        releaseId: 42,
        genres: ['Rock', 'Jazz'],
        styles: ['Blues Rock'],
      );
      final s = CollectionStats.from([item], metadata: [meta]);
      expect(s.byGenre['Rock'], 1);
      expect(s.byGenre['Jazz'], 1);
      expect(s.byStyle['Blues Rock'], 1);
    });

    test('genres sorted by count descending', () {
      final items = [
        _item(id: '1', discogsReleaseId: 1),
        _item(id: '2', discogsReleaseId: 2),
        _item(id: '3', discogsReleaseId: 3),
      ];
      final meta = [
        _meta(releaseId: 1, genres: ['Rock'], styles: []),
        _meta(releaseId: 2, genres: ['Rock'], styles: []),
        _meta(releaseId: 3, genres: ['Jazz'], styles: []),
      ];
      final s = CollectionStats.from(items, metadata: meta);
      expect(s.byGenre.keys.first, 'Rock');
    });

    test('metadata for releases not in collection is ignored', () {
      final item = _item(id: '1', discogsReleaseId: 1);
      final meta = _meta(releaseId: 999, genres: ['Rock'], styles: []);
      final s = CollectionStats.from([item], metadata: [meta]);
      expect(s.byGenre, isEmpty);
    });

    test('partial metadata: only items with cached metadata counted', () {
      final items = [
        _item(id: '1', discogsReleaseId: 1),
        _item(id: '2', discogsReleaseId: 2),
      ];
      final meta = [
        _meta(releaseId: 1, genres: ['Rock'], styles: []),
      ];
      final s = CollectionStats.from(items, metadata: meta);
      expect(s.byGenre['Rock'], 1);
      expect(s.byGenre.length, 1);
    });
  });
}

CachedReleaseMetadata _meta({
  required int releaseId,
  required List<String> genres,
  required List<String> styles,
}) => CachedReleaseMetadata(
  discogsReleaseId: releaseId,
  artist: 'Artist',
  title: 'Title',
  genres: genres,
  styles: styles,
  tracklist: const [],
  identifiers: const [],
  fetchedAt: DateTime(2024),
  cacheSource: 'discogs',
  syncStatus: SyncStatus.localOnly,
);

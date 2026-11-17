import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/collection_filter_set.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _item({
  String id = '1',
  int releaseId = 1,
  String artist = 'A',
  String title = 'T',
  String? label,
  String? format,
  int? year,
  String? storageLocation,
  List<String> tags = const [],
  SyncStatus syncStatus = SyncStatus.localOnly,
  String? coverUrl,
  RecordCondition media = RecordCondition.veryGood,
  RecordCondition sleeve = RecordCondition.veryGood,
}) => CollectionItem(
  id: id,
  discogsReleaseId: releaseId,
  artist: artist,
  title: title,
  label: label,
  format: format,
  year: year,
  coverUrl: coverUrl,
  mediaCondition: media,
  sleeveCondition: sleeve,
  tags: tags,
  storageLocation: storageLocation,
  syncStatus: syncStatus,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

CachedReleaseMetadata _meta({
  int releaseId = 1,
  List<String> genres = const [],
  List<String> styles = const [],
}) => CachedReleaseMetadata(
  discogsReleaseId: releaseId,
  artist: 'A',
  title: 'T',
  genres: genres,
  styles: styles,
  tracklist: const [],
  identifiers: const [],
  fetchedAt: DateTime(2026),
  cacheSource: 'api',
  syncStatus: SyncStatus.localOnly,
);

void main() {
  group('CollectionFilterSet', () {
    test('isEmpty true when no filters set', () {
      expect(const CollectionFilterSet().isEmpty, isTrue);
    });

    test('isEmpty false when any filter set', () {
      expect(CollectionFilterSet(formats: {'LP'}).isEmpty, isFalse);
    });

    test('apply with empty filter returns all items', () {
      final items = [_item(id: '1'), _item(id: '2')];
      final result = const CollectionFilterSet().apply(items);
      expect(result, hasLength(2));
    });

    test('filters by decade', () {
      final items = [
        _item(id: '1', year: 1984),
        _item(id: '2', year: 1995),
        _item(id: '3', year: 2003),
      ];
      final result = CollectionFilterSet(decades: {1980}).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('item without year excluded when decade filter active', () {
      final items = [_item(id: '1', year: null), _item(id: '2', year: 1985)];
      final result = CollectionFilterSet(decades: {1980}).apply(items);
      expect(result.map((i) => i.id), ['2']);
    });

    test('filters by format', () {
      final items = [
        _item(id: '1', format: 'LP'),
        _item(id: '2', format: '12"'),
      ];
      final result = CollectionFilterSet(formats: {'LP'}).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by label', () {
      final items = [
        _item(id: '1', label: 'Warp'),
        _item(id: '2', label: 'Ninja Tune'),
      ];
      final result = CollectionFilterSet(labels: {'Warp'}).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by genre using metadata', () {
      final items = [
        _item(id: '1', releaseId: 10),
        _item(id: '2', releaseId: 20),
      ];
      final metadata = [
        _meta(releaseId: 10, genres: ['Electronic']),
        _meta(releaseId: 20, genres: ['Jazz']),
      ];
      final result = CollectionFilterSet(
        genres: {'Electronic'},
      ).apply(items, metadata: metadata);
      expect(result.map((i) => i.id), ['1']);
    });

    test('genre filter excludes item with no metadata', () {
      final items = [
        _item(id: '1', releaseId: 10),
        _item(id: '2', releaseId: 20),
      ];
      final metadata = [
        _meta(releaseId: 10, genres: ['Electronic']),
      ];
      // item 2 has no metadata — excluded when genre filter active
      final result = CollectionFilterSet(
        genres: {'Electronic'},
      ).apply(items, metadata: metadata);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by style using metadata', () {
      final items = [
        _item(id: '1', releaseId: 1),
        _item(id: '2', releaseId: 2),
      ];
      final metadata = [
        _meta(releaseId: 1, styles: ['Ambient']),
        _meta(releaseId: 2, styles: ['Techno']),
      ];
      final result = CollectionFilterSet(
        styles: {'Ambient'},
      ).apply(items, metadata: metadata);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by media condition', () {
      final items = [
        _item(id: '1', media: RecordCondition.mint),
        _item(id: '2', media: RecordCondition.veryGood),
      ];
      final result = CollectionFilterSet(
        mediaConditions: {RecordCondition.mint},
      ).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by sleeve condition', () {
      final items = [
        _item(id: '1', sleeve: RecordCondition.nearMint),
        _item(id: '2', sleeve: RecordCondition.fair),
      ];
      final result = CollectionFilterSet(
        sleeveConditions: {RecordCondition.nearMint},
      ).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by tag (any match)', () {
      final items = [
        _item(id: '1', tags: ['jazz', 'vinyl']),
        _item(id: '2', tags: ['techno']),
      ];
      final result = CollectionFilterSet(tags: {'jazz'}).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by storage location', () {
      final items = [
        _item(id: '1', storageLocation: 'Shelf A'),
        _item(id: '2', storageLocation: 'Shelf B'),
      ];
      final result = CollectionFilterSet(
        storageLocation: 'Shelf A',
      ).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by sync status', () {
      final items = [
        _item(id: '1', syncStatus: SyncStatus.localOnly),
        _item(id: '2', syncStatus: SyncStatus.synced),
      ];
      final result = CollectionFilterSet(
        syncStatuses: {SyncStatus.localOnly},
      ).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by hasCover = true', () {
      final items = [
        _item(id: '1', coverUrl: 'https://cover.jpg'),
        _item(id: '2', coverUrl: null),
      ];
      final result = CollectionFilterSet(hasCover: true).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by hasCover = false', () {
      final items = [
        _item(id: '1', coverUrl: 'https://cover.jpg'),
        _item(id: '2', coverUrl: null),
      ];
      final result = CollectionFilterSet(hasCover: false).apply(items);
      expect(result.map((i) => i.id), ['2']);
    });

    test('combined filters: format AND label', () {
      final items = [
        _item(id: '1', format: 'LP', label: 'Warp'),
        _item(id: '2', format: 'LP', label: 'Ninja Tune'),
        _item(id: '3', format: '7"', label: 'Warp'),
      ];
      final result = CollectionFilterSet(
        formats: {'LP'},
        labels: {'Warp'},
      ).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('returns empty list when no items match', () {
      final items = [_item(id: '1', format: 'LP')];
      final result = CollectionFilterSet(formats: {'12"'}).apply(items);
      expect(result, isEmpty);
    });

    test('activeCount counts each active filter group as 1', () {
      final f = CollectionFilterSet(
        formats: {'LP'},
        labels: {'Warp'},
        hasCover: true,
      );
      expect(f.activeCount, 3);
    });

    test('toJson / fromJson round-trip', () {
      final original = CollectionFilterSet(
        decades: {1980, 1990},
        formats: {'LP'},
        labels: {'Warp'},
        syncStatuses: {SyncStatus.synced},
        hasCover: true,
      );
      final restored = CollectionFilterSet.fromJsonString(
        original.toJsonString(),
      );
      expect(restored.decades, original.decades);
      expect(restored.formats, original.formats);
      expect(restored.labels, original.labels);
      expect(restored.syncStatuses, original.syncStatuses);
      expect(restored.hasCover, original.hasCover);
    });
  });

  group('CollectionFilterSet — format types (US-143)', () {
    final vinyl = _item(id: 'v', format: 'Vinyl, 12", 33 ⅓ RPM');
    final file = _item(id: 'f', format: 'File, MP3, 320 kbps');
    final mixed = _item(id: 'm', format: 'Vinyl, LP, Album\nFile, MP3');
    final none = _item(id: 'n');

    test('"Vinyl" keeps every vinyl item and hides File-only items', () {
      final result = const CollectionFilterSet(
        formats: {'Vinyl'},
      ).apply([vinyl, file, mixed, none]);
      expect(result.map((i) => i.id), ['v', 'm']);
    });

    test('an item with several formats counts for each type', () {
      final result = const CollectionFilterSet(
        formats: {'File'},
      ).apply([vinyl, file, mixed]);
      expect(result.map((i) => i.id), ['f', 'm']);
    });

    test('combines with other filters', () {
      final result =
          CollectionFilterSet(
            formats: const {'Vinyl'},
            labels: const {'Warp'},
          ).apply([
            _item(id: '1', format: 'Vinyl, LP', label: 'Warp'),
            _item(id: '2', format: 'Vinyl, LP', label: 'Ninja Tune'),
            _item(id: '3', format: 'File, FLAC', label: 'Warp'),
          ]);
      expect(result.map((i) => i.id), ['1']);
    });

    test('saved sets with full format strings load as types', () {
      final old = {
        ...const CollectionFilterSet().toJson(),
        'formats': ['Vinyl, 12", 33 ⅓ RPM', 'Vinyl, LP, Album', 'CD'],
      };
      final loaded = CollectionFilterSet.fromJson(old);
      expect(loaded.formats, {'Vinyl', 'CD'});
      expect(loaded.apply([vinyl, file]).map((i) => i.id), ['v']);
    });

    test('new sets round-trip unchanged', () {
      const set = CollectionFilterSet(formats: {'Vinyl', 'File'});
      expect(CollectionFilterSet.fromJson(set.toJson()).formats, {
        'Vinyl',
        'File',
      });
    });
  });

  group('CollectionFilterSet — saved before US-165', () {
    test('a set with DJ filters loads; the DJ values are dropped', () {
      final old = {
        ...const CollectionFilterSet(formats: {'Vinyl'}).toJson(),
        'bpmMin': 120,
        'bpmMax': 130,
        'musicalKeys': ['aMinor'],
        'energyLevels': [3, 4],
        'gigCrates': ['Warmup'],
      };
      final loaded = CollectionFilterSet.fromJson(old);
      expect(loaded.formats, {'Vinyl'});
      expect(loaded.activeCount, 1);
      expect(loaded.toJson().keys, isNot(contains('bpmMin')));
    });
  });
}

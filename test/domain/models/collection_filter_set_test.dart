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
  int? bpm,
  MusicalKey? musicalKey,
  int? energyLevel,
  List<String> gigCrates = const [],
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
  bpm: bpm,
  musicalKey: musicalKey,
  energyLevel: energyLevel,
  gigCrates: gigCrates,
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

    group('DJ field filters (US-121)', () {
      test('filters by BPM range, items without BPM excluded', () {
        final items = [
          _item(id: '1', bpm: 100),
          _item(id: '2', bpm: 128),
          _item(id: '3', bpm: 140),
          _item(id: '4'),
        ];
        final result = CollectionFilterSet(
          bpmMin: 120,
          bpmMax: 130,
        ).apply(items);
        expect(result.map((i) => i.id), ['2']);
      });

      test('BPM bounds are inclusive and work independently', () {
        final items = [_item(id: '1', bpm: 120), _item(id: '2', bpm: 130)];
        expect(CollectionFilterSet(bpmMin: 120).apply(items).map((i) => i.id), [
          '1',
          '2',
        ]);
        expect(CollectionFilterSet(bpmMax: 120).apply(items).map((i) => i.id), [
          '1',
        ]);
      });

      test('filters by musical key, items without key excluded', () {
        final items = [
          _item(id: '1', musicalKey: MusicalKey.aMinor),
          _item(id: '2', musicalKey: MusicalKey.cMajor),
          _item(id: '3'),
        ];
        final result = CollectionFilterSet(
          musicalKeys: {MusicalKey.aMinor},
        ).apply(items);
        expect(result.map((i) => i.id), ['1']);
      });

      test('filters by energy level, items without energy excluded', () {
        final items = [
          _item(id: '1', energyLevel: 5),
          _item(id: '2', energyLevel: 2),
          _item(id: '3'),
        ];
        final result = CollectionFilterSet(energyLevels: {4, 5}).apply(items);
        expect(result.map((i) => i.id), ['1']);
      });

      test('filters by gig crate (any match)', () {
        final items = [
          _item(id: '1', gigCrates: ['House Night', 'Warmup']),
          _item(id: '2', gigCrates: ['Techno']),
          _item(id: '3'),
        ];
        final result = CollectionFilterSet(gigCrates: {'Warmup'}).apply(items);
        expect(result.map((i) => i.id), ['1']);
      });

      test('activeCount counts BPM range as one group', () {
        final f = CollectionFilterSet(
          bpmMin: 100,
          bpmMax: 130,
          musicalKeys: {MusicalKey.aMinor},
          energyLevels: {5},
          gigCrates: {'Warmup'},
        );
        expect(f.activeCount, 4);
        expect(f.isEmpty, isFalse);
      });

      test('DJ fields round-trip through JSON', () {
        final original = CollectionFilterSet(
          bpmMin: 100,
          bpmMax: 130,
          musicalKeys: {MusicalKey.gbMinor, MusicalKey.aMajor},
          energyLevels: {3, 4},
          gigCrates: {'Warmup'},
        );
        final restored = CollectionFilterSet.fromJsonString(
          original.toJsonString(),
        );
        expect(restored.bpmMin, 100);
        expect(restored.bpmMax, 130);
        expect(restored.musicalKeys, original.musicalKeys);
        expect(restored.energyLevels, original.energyLevels);
        expect(restored.gigCrates, original.gigCrates);
      });

      test('fromJson accepts pre-US-121 payloads without DJ keys', () {
        // Snapshot of a saved-search payload from before the DJ fields
        // existed; loading it must not throw and must default the DJ
        // filters to inactive.
        const oldPayload =
            '{"schemaVersion":1,"decades":[1990],"formats":["LP"],'
            '"labels":[],"genres":[],"styles":[],"mediaConditions":[],'
            '"sleeveConditions":[],"tags":[],"storageLocation":null,'
            '"syncStatuses":[],"hasCover":null}';
        final restored = CollectionFilterSet.fromJsonString(oldPayload);
        expect(restored.decades, {1990});
        expect(restored.bpmMin, isNull);
        expect(restored.bpmMax, isNull);
        expect(restored.musicalKeys, isEmpty);
        expect(restored.energyLevels, isEmpty);
        expect(restored.gigCrates, isEmpty);
      });
    });
  });
}

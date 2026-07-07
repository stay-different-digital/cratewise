import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/infrastructure/csv/collection_csv_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _fullItem() => CollectionItem(
  id: 'item-1',
  discogsReleaseId: 12345,
  artist: 'Miles Davis',
  title: 'Kind of Blue',
  label: 'Columbia',
  catno: 'CL 1355',
  format: 'LP',
  country: 'US',
  year: 1959,
  coverUrl: 'https://img.example.com/cover.jpg',
  mediaCondition: RecordCondition.nearMint,
  sleeveCondition: RecordCondition.veryGoodPlus,
  notes: 'First pressing',
  tags: ['jazz', 'classic'],
  storageLocation: 'Shelf A',
  syncStatus: SyncStatus.synced,
  createdAt: DateTime.utc(2024, 1, 15, 10, 0, 0),
  updatedAt: DateTime.utc(2024, 6, 1, 12, 30, 0),
  bpm: 128,
  musicalKey: MusicalKey.aMajor,
  energyLevel: 4,
  gigCrates: ['Summer Set', 'Techno Night'],
);

CollectionItem _minimalItem() => CollectionItem(
  id: 'item-2',
  discogsReleaseId: 99,
  artist: 'Unknown Artist',
  title: 'Untitled',
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime.utc(2024, 3, 10, 8, 0, 0),
  updatedAt: DateTime.utc(2024, 3, 10, 8, 0, 0),
);

void main() {
  const mapper = CollectionCsvMapper();

  group('collectionCsvHeaders', () {
    test('contains 19 headers', () {
      expect(collectionCsvHeaders.length, 19);
    });

    test('first header is Artist', () {
      expect(collectionCsvHeaders.first, 'Artist');
    });

    test('last header is Gig Crates', () {
      expect(collectionCsvHeaders.last, 'Gig Crates');
    });

    test('contains expected fields', () {
      expect(collectionCsvHeaders, contains('Discogs Release ID'));
      expect(collectionCsvHeaders, contains('Media Condition'));
      expect(collectionCsvHeaders, contains('Sleeve Condition'));
      expect(collectionCsvHeaders, contains('Tags'));
      expect(collectionCsvHeaders, contains('Storage Location'));
      expect(collectionCsvHeaders, contains('Created Date'));
      expect(collectionCsvHeaders, contains('Updated Date'));
      expect(collectionCsvHeaders, contains('BPM'));
      expect(collectionCsvHeaders, contains('Musical Key'));
      expect(collectionCsvHeaders, contains('Energy'));
      expect(collectionCsvHeaders, contains('Gig Crates'));
    });
  });

  group('CollectionCsvMapper.toRow — fully populated item', () {
    late List<String> row;

    setUpAll(() {
      row = mapper.toRow(_fullItem());
    });

    test('row length matches header count', () {
      expect(row.length, collectionCsvHeaders.length);
    });

    test('artist maps to column 0', () {
      expect(row[0], 'Miles Davis');
    });

    test('title maps to column 1', () {
      expect(row[1], 'Kind of Blue');
    });

    test('label maps to column 2', () {
      expect(row[2], 'Columbia');
    });

    test('catno maps to column 3', () {
      expect(row[3], 'CL 1355');
    });

    test('format maps to column 4', () {
      expect(row[4], 'LP');
    });

    test('country maps to column 5', () {
      expect(row[5], 'US');
    });

    test('year maps to column 6 as string', () {
      expect(row[6], '1959');
    });

    test('discogsReleaseId maps to column 7 as string', () {
      expect(row[7], '12345');
    });

    test('mediaCondition maps to column 8 as label', () {
      expect(row[8], 'Near Mint (NM or M-)');
    });

    test('sleeveCondition maps to column 9 as label', () {
      expect(row[9], 'Very Good Plus (VG+)');
    });

    test('notes maps to column 10', () {
      expect(row[10], 'First pressing');
    });

    test('tags are pipe-joined in column 11', () {
      expect(row[11], 'jazz|classic');
    });

    test('storageLocation maps to column 12', () {
      expect(row[12], 'Shelf A');
    });

    test('createdAt maps to column 13 as ISO 8601', () {
      expect(row[13], '2024-01-15T10:00:00.000Z');
    });

    test('updatedAt maps to column 14 as ISO 8601', () {
      expect(row[14], '2024-06-01T12:30:00.000Z');
    });

    test('bpm maps to column 15', () {
      expect(row[15], '128');
    });

    test('musicalKey maps to column 16 as label', () {
      expect(row[16], 'A major');
    });

    test('energyLevel maps to column 17', () {
      expect(row[17], '4');
    });

    test('gigCrates are pipe-joined in column 18', () {
      expect(row[18], 'Summer Set|Techno Night');
    });
  });

  group('CollectionCsvMapper.toRow — optional fields absent', () {
    late List<String> row;

    setUpAll(() {
      row = mapper.toRow(_minimalItem());
    });

    test('row length matches header count', () {
      expect(row.length, collectionCsvHeaders.length);
    });

    test('null label becomes empty string', () {
      expect(row[2], '');
    });

    test('null catno becomes empty string', () {
      expect(row[3], '');
    });

    test('null format becomes empty string', () {
      expect(row[4], '');
    });

    test('null country becomes empty string', () {
      expect(row[5], '');
    });

    test('null year becomes empty string', () {
      expect(row[6], '');
    });

    test('null notes becomes empty string', () {
      expect(row[10], '');
    });

    test('empty tags list becomes empty string', () {
      expect(row[11], '');
    });

    test('null storageLocation becomes empty string', () {
      expect(row[12], '');
    });

    test('mediaCondition notSet maps to Not set label', () {
      expect(row[8], 'Not set');
    });

    test('null bpm becomes empty string', () {
      expect(row[15], '');
    });

    test('null musicalKey becomes empty string', () {
      expect(row[16], '');
    });

    test('null energyLevel becomes empty string', () {
      expect(row[17], '');
    });

    test('empty gigCrates becomes empty string', () {
      expect(row[18], '');
    });
  });

  group('CollectionCsvMapper.toRow — tags encoding', () {
    test('single tag has no pipe separator', () {
      final item = _fullItem().copyWith(tags: ['vinyl']);
      expect(mapper.toRow(item)[11], 'vinyl');
    });

    test('three tags are separated by pipe', () {
      final item = _fullItem().copyWith(tags: ['a', 'b', 'c']);
      expect(mapper.toRow(item)[11], 'a|b|c');
    });
  });

  group('CollectionCsvMapper.toRow — date formatting', () {
    test('dates include time component', () {
      final row = mapper.toRow(_fullItem());
      expect(row[13], contains('T'));
      expect(row[14], contains('T'));
    });

    test('UTC dates end with Z', () {
      final row = mapper.toRow(_fullItem());
      expect(row[13], endsWith('Z'));
      expect(row[14], endsWith('Z'));
    });
  });

  group('CollectionCsvMapper.toRow — all RecordCondition values', () {
    for (final condition in RecordCondition.values) {
      test('${condition.name} maps to its label string', () {
        final item = _fullItem().copyWith(
          mediaCondition: condition,
          sleeveCondition: condition,
        );
        final row = mapper.toRow(item);
        expect(row[8], condition.label);
        expect(row[9], condition.label);
      });
    }
  });
}

import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/collection_sort.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _item(
  String id, {
  int? bpm,
  MusicalKey? musicalKey,
  int? energyLevel,
}) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: 'A',
  title: 'T',
  mediaCondition: RecordCondition.veryGood,
  sleeveCondition: RecordCondition.veryGood,
  tags: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  bpm: bpm,
  musicalKey: musicalKey,
  energyLevel: energyLevel,
);

void main() {
  group('CollectionSort (US-121)', () {
    test('newestFirst keeps the repository order untouched', () {
      final items = [_item('b', bpm: 200), _item('a', bpm: 100)];
      expect(CollectionSort.newestFirst.apply(items).map((i) => i.id), [
        'b',
        'a',
      ]);
    });

    test('bpm sorts ascending with items without BPM at the end', () {
      final items = [
        _item('none'),
        _item('fast', bpm: 140),
        _item('slow', bpm: 90),
      ];
      expect(CollectionSort.bpm.apply(items).map((i) => i.id), [
        'slow',
        'fast',
        'none',
      ]);
    });

    test('musicalKey sorts by key with items without key at the end', () {
      final items = [
        _item('none'),
        _item('late', musicalKey: MusicalKey.bMinor),
        _item('early', musicalKey: MusicalKey.cMajor),
      ];
      expect(CollectionSort.musicalKey.apply(items).map((i) => i.id), [
        'early',
        'late',
        'none',
      ]);
    });

    test(
      'energyLevel sorts ascending with items without energy at the end',
      () {
        final items = [
          _item('none'),
          _item('high', energyLevel: 5),
          _item('low', energyLevel: 1),
        ];
        expect(CollectionSort.energyLevel.apply(items).map((i) => i.id), [
          'low',
          'high',
          'none',
        ]);
      },
    );

    test('apply does not mutate the input list', () {
      final items = [_item('b', bpm: 200), _item('a', bpm: 100)];
      CollectionSort.bpm.apply(items);
      expect(items.map((i) => i.id), ['b', 'a']);
    });
  });
}

import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/collection_sort.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _item(String id) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: 'A',
  title: 'T',
  mediaCondition: RecordCondition.veryGood,
  sleeveCondition: RecordCondition.veryGood,
  tags: const [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test('newest first keeps the repository order (createdAt descending)', () {
    final items = [_item('b'), _item('a'), _item('c')];
    expect(CollectionSort.newestFirst.apply(items).map((i) => i.id), [
      'b',
      'a',
      'c',
    ]);
  });

  // US-165: the BPM, Key and Energy sorts were removed with the DJ fields.
  test('only newest first remains', () {
    expect(CollectionSort.values, [CollectionSort.newestFirst]);
  });
}

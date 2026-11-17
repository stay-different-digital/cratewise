import 'package:cratewise/domain/models/added_date_sort.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Item = ({String id, DateTime added});

void main() {
  final items = <_Item>[
    (id: 'mid', added: DateTime(2022)),
    (id: 'old', added: DateTime(2019)),
    (id: 'new', added: DateTime(2026)),
    (id: 'mid2', added: DateTime(2022)),
  ];
  List<String> ids(List<_Item> list) => [for (final i in list) i.id];

  test('newest first orders by added date, descending', () {
    expect(ids(AddedDateSort.newestFirst.apply(items, (i) => i.added)), [
      'new',
      'mid',
      'mid2',
      'old',
    ]);
  });

  test('oldest first orders by added date, ascending', () {
    expect(ids(AddedDateSort.oldestFirst.apply(items, (i) => i.added)), [
      'old',
      'mid',
      'mid2',
      'new',
    ]);
  });

  test('items added at the same moment keep their order', () {
    final same = [
      for (final id in ['a', 'b', 'c']) (id: id, added: DateTime(2024)),
    ];
    expect(ids(AddedDateSort.oldestFirst.apply(same, (i) => i.added)), [
      'a',
      'b',
      'c',
    ]);
  });
}

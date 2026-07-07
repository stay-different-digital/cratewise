import 'collection_item.dart';

/// Sort options for the collection list (US-121).
///
/// [newestFirst] preserves the repository order (createdAt descending).
/// The DJ-field sorts order ascending and put items without a value at the
/// end, per the acceptance criterion that empty values stay at the bottom.
enum CollectionSort {
  newestFirst('Newest first'),
  bpm('BPM'),
  musicalKey('Key'),
  energyLevel('Energy');

  const CollectionSort(this.label);

  final String label;

  List<CollectionItem> apply(List<CollectionItem> items) {
    if (this == CollectionSort.newestFirst) return items;

    int? sortKey(CollectionItem item) => switch (this) {
      CollectionSort.bpm => item.bpm,
      CollectionSort.musicalKey => item.musicalKey?.index,
      CollectionSort.energyLevel => item.energyLevel,
      CollectionSort.newestFirst => 0,
    };

    final sorted = List<CollectionItem>.from(items);
    sorted.sort((a, b) {
      final ka = sortKey(a);
      final kb = sortKey(b);
      if (ka == null && kb == null) return 0;
      if (ka == null) return 1;
      if (kb == null) return -1;
      return ka.compareTo(kb);
    });
    return sorted;
  }
}

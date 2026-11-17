import 'collection_item.dart';

/// Sort options for the collection list.
///
/// [newestFirst] preserves the repository order (createdAt descending). The
/// DJ-field sorts (BPM, Key, Energy) were removed with the DJ fields (US-165).
enum CollectionSort {
  newestFirst('Newest first');

  const CollectionSort(this.label);

  final String label;

  List<CollectionItem> apply(List<CollectionItem> items) => items;
}

import 'collection_item.dart';

class CsvCollectionExportPreview {
  const CsvCollectionExportPreview({
    required this.items,
    required this.headers,
    required this.sampleRows,
  });

  final List<CollectionItem> items;

  /// Column headers from [collectionCsvHeaders].
  final List<String> headers;

  /// First up to 3 rows, already mapped to string columns.
  final List<List<String>> sampleRows;

  int get rowCount => items.length;
}

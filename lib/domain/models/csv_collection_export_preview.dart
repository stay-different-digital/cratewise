import 'csv_export_preview.dart';
import 'collection_item.dart';

class CsvCollectionExportPreview implements CsvExportPreview {
  const CsvCollectionExportPreview({
    required this.items,
    required this.headers,
    required this.sampleRows,
  });

  final List<CollectionItem> items;

  /// Column headers from [collectionCsvHeaders].
  @override
  final List<String> headers;

  /// First up to 3 rows, already mapped to string columns.
  @override
  final List<List<String>> sampleRows;

  @override
  int get rowCount => items.length;
}

import 'csv_export_preview.dart';
import 'wishlist_item.dart';

class CsvWishlistExportPreview implements CsvExportPreview {
  const CsvWishlistExportPreview({
    required this.items,
    required this.headers,
    required this.sampleRows,
  });

  final List<WishlistItem> items;

  /// Column headers from [wishlistCsvHeaders].
  @override
  final List<String> headers;

  /// First up to 3 rows, already mapped to string columns.
  @override
  final List<List<String>> sampleRows;

  @override
  int get rowCount => items.length;
}

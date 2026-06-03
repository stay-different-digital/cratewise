import 'wishlist_item.dart';

class CsvWishlistExportPreview {
  const CsvWishlistExportPreview({
    required this.items,
    required this.headers,
    required this.sampleRows,
  });

  final List<WishlistItem> items;

  /// Column headers from [wishlistCsvHeaders].
  final List<String> headers;

  /// First up to 3 rows, already mapped to string columns.
  final List<List<String>> sampleRows;

  int get rowCount => items.length;
}

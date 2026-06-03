import 'package:cratewise/domain/models/csv_wishlist_export_preview.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

WishlistItem _item(String id) => WishlistItem(
      id: id,
      discogsReleaseId: 1,
      artist: 'Artist',
      title: 'Title',
      priority: WishlistPriority.low,
      syncStatus: SyncStatus.localOnly,
      createdAt: DateTime.utc(2024),
      updatedAt: DateTime.utc(2024),
    );

void main() {
  group('CsvWishlistExportPreview', () {
    test('rowCount returns items.length', () {
      final preview = CsvWishlistExportPreview(
        items: [_item('a'), _item('b')],
        headers: const ['H1', 'H2'],
        sampleRows: const [],
      );
      expect(preview.rowCount, 2);
    });

    test('rowCount is zero for empty items', () {
      final preview = CsvWishlistExportPreview(
        items: const [],
        headers: const ['H1'],
        sampleRows: const [],
      );
      expect(preview.rowCount, 0);
    });

    test('headers are stored as provided', () {
      const headers = ['Artist', 'Title', 'Priority'];
      final preview = CsvWishlistExportPreview(
        items: const [],
        headers: headers,
        sampleRows: const [],
      );
      expect(preview.headers, headers);
    });

    test('sampleRows are stored as provided', () {
      const sampleRows = [
        ['John Coltrane', 'A Love Supreme', '1965'],
      ];
      final preview = CsvWishlistExportPreview(
        items: const [],
        headers: const [],
        sampleRows: sampleRows,
      );
      expect(preview.sampleRows, sampleRows);
    });
  });
}

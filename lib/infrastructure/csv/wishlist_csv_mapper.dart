import '../../domain/models/wishlist_item.dart';

const List<String> wishlistCsvHeaders = [
  'Artist',
  'Title',
  'Label',
  'Catalog Number',
  'Format',
  'Country',
  'Year',
  'Discogs Release ID',
  'Target Price',
  'Priority',
  'Notes',
  'Created Date',
  'Updated Date',
];

class WishlistCsvMapper {
  const WishlistCsvMapper();

  /// Returns one CSV row for [item]. Column order matches [wishlistCsvHeaders].
  /// Optional fields map to empty string when absent.
  /// Target price is formatted to two decimal places when present.
  List<String> toRow(WishlistItem item) {
    return [
      item.artist,
      item.title,
      item.label ?? '',
      item.catno ?? '',
      item.format ?? '',
      item.country ?? '',
      item.year?.toString() ?? '',
      item.discogsReleaseId.toString(),
      item.targetPrice != null
          ? item.targetPrice!.toStringAsFixed(2)
          : '',
      item.priority.label,
      item.notes ?? '',
      item.createdAt.toIso8601String(),
      item.updatedAt.toIso8601String(),
    ];
  }
}

import '../../domain/models/collection_item.dart';

const List<String> collectionCsvHeaders = [
  'Artist',
  'Title',
  'Label',
  'Catalog Number',
  'Format',
  'Country',
  'Year',
  'Discogs Release ID',
  'Media Condition',
  'Sleeve Condition',
  'Notes',
  'Tags',
  'Storage Location',
  'Created Date',
  'Updated Date',
  'BPM',
  'Musical Key',
  'Energy',
  'Gig Crates',
];

class CollectionCsvMapper {
  const CollectionCsvMapper();

  /// Returns one CSV row for [item]. Column order matches [collectionCsvHeaders].
  /// Optional fields map to empty string when absent.
  /// Tags and Gig Crates are joined with '|' to avoid ambiguity with the CSV delimiter.
  List<String> toRow(CollectionItem item) {
    return [
      item.artist,
      item.title,
      item.label ?? '',
      item.catno ?? '',
      item.format ?? '',
      item.country ?? '',
      item.year?.toString() ?? '',
      item.discogsReleaseId.toString(),
      item.mediaCondition.label,
      item.sleeveCondition.label,
      item.notes ?? '',
      item.tags.join('|'),
      item.storageLocation ?? '',
      item.createdAt.toIso8601String(),
      item.updatedAt.toIso8601String(),
      item.bpm?.toString() ?? '',
      item.musicalKey?.label ?? '',
      item.energyLevel?.toString() ?? '',
      item.gigCrates.join('|'),
    ];
  }
}

import 'dart:convert';

import 'cached_release_metadata.dart';
import 'collection_item.dart';
import 'format_types.dart';
import 'sync_status.dart';

class CollectionFilterSet {
  const CollectionFilterSet({
    this.decades = const {},
    this.formats = const {},
    this.labels = const {},
    this.genres = const {},
    this.styles = const {},
    this.mediaConditions = const {},
    this.sleeveConditions = const {},
    this.tags = const {},
    this.storageLocation,
    this.syncStatuses = const {},
    this.hasCover,
  });

  final Set<int> decades;
  final Set<String> formats;
  final Set<String> labels;
  final Set<String> genres;
  final Set<String> styles;
  final Set<RecordCondition> mediaConditions;
  final Set<RecordCondition> sleeveConditions;
  final Set<String> tags;
  final String? storageLocation;
  final Set<SyncStatus> syncStatuses;
  final bool? hasCover;

  bool get isEmpty =>
      decades.isEmpty &&
      formats.isEmpty &&
      labels.isEmpty &&
      genres.isEmpty &&
      styles.isEmpty &&
      mediaConditions.isEmpty &&
      sleeveConditions.isEmpty &&
      tags.isEmpty &&
      storageLocation == null &&
      syncStatuses.isEmpty &&
      hasCover == null;

  int get activeCount =>
      (decades.isNotEmpty ? 1 : 0) +
      (formats.isNotEmpty ? 1 : 0) +
      (labels.isNotEmpty ? 1 : 0) +
      (genres.isNotEmpty ? 1 : 0) +
      (styles.isNotEmpty ? 1 : 0) +
      (mediaConditions.isNotEmpty ? 1 : 0) +
      (sleeveConditions.isNotEmpty ? 1 : 0) +
      (tags.isNotEmpty ? 1 : 0) +
      (storageLocation != null ? 1 : 0) +
      (syncStatuses.isNotEmpty ? 1 : 0) +
      (hasCover != null ? 1 : 0);

  List<CollectionItem> apply(
    List<CollectionItem> items, {
    List<CachedReleaseMetadata> metadata = const [],
  }) {
    if (isEmpty) return items;
    final metaMap = {for (final m in metadata) m.discogsReleaseId: m};
    return items.where((item) {
      if (decades.isNotEmpty) {
        final decade = item.year != null ? (item.year! ~/ 10) * 10 : null;
        if (decade == null || !decades.contains(decade)) return false;
      }
      // [formats] holds format *types* (US-143): an item matches when any of
      // its formats has a selected type, so "Vinyl" covers every vinyl
      // variant and a Vinyl + File release counts for both.
      if (formats.isNotEmpty &&
          !formatTypes(item.format).any(formats.contains)) {
        return false;
      }
      if (labels.isNotEmpty &&
          (item.label == null || !labels.contains(item.label))) {
        return false;
      }
      if (genres.isNotEmpty) {
        final meta = metaMap[item.discogsReleaseId];
        if (meta == null || !meta.genres.any(genres.contains)) return false;
      }
      if (styles.isNotEmpty) {
        final meta = metaMap[item.discogsReleaseId];
        if (meta == null || !meta.styles.any(styles.contains)) return false;
      }
      if (mediaConditions.isNotEmpty &&
          !mediaConditions.contains(item.mediaCondition)) {
        return false;
      }
      if (sleeveConditions.isNotEmpty &&
          !sleeveConditions.contains(item.sleeveCondition)) {
        return false;
      }
      if (tags.isNotEmpty && !item.tags.any(tags.contains)) return false;
      if (storageLocation != null && item.storageLocation != storageLocation) {
        return false;
      }
      if (syncStatuses.isNotEmpty && !syncStatuses.contains(item.syncStatus)) {
        return false;
      }
      if (hasCover != null) {
        final has = item.coverUrl != null && item.coverUrl!.isNotEmpty;
        if (has != hasCover) return false;
      }
      return true;
    }).toList();
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'decades': (decades.toList()..sort()),
    'formats': formats.toList(),
    'labels': labels.toList(),
    'genres': genres.toList(),
    'styles': styles.toList(),
    'mediaConditions': mediaConditions.map((c) => c.name).toList(),
    'sleeveConditions': sleeveConditions.map((c) => c.name).toList(),
    'tags': tags.toList(),
    'storageLocation': storageLocation,
    'syncStatuses': syncStatuses.map((s) => s.name).toList(),
    'hasCover': hasCover,
  };

  static CollectionFilterSet fromJson(Map<String, dynamic> json) =>
      CollectionFilterSet(
        decades: (json['decades'] as List).cast<int>().toSet(),
        // Sets saved before US-143 hold full format strings
        // ("Vinyl, 12\", 33 ⅓ RPM"); reduce them to their type so they keep
        // working. A type maps to itself, so new sets are unchanged.
        formats: (json['formats'] as List)
            .cast<String>()
            .expand(formatTypes)
            .toSet(),
        labels: (json['labels'] as List).cast<String>().toSet(),
        genres: (json['genres'] as List).cast<String>().toSet(),
        styles: (json['styles'] as List).cast<String>().toSet(),
        mediaConditions: (json['mediaConditions'] as List)
            .cast<String>()
            .map((n) => RecordCondition.values.byName(n))
            .toSet(),
        sleeveConditions: (json['sleeveConditions'] as List)
            .cast<String>()
            .map((n) => RecordCondition.values.byName(n))
            .toSet(),
        tags: (json['tags'] as List).cast<String>().toSet(),
        storageLocation: json['storageLocation'] as String?,
        syncStatuses: (json['syncStatuses'] as List)
            .cast<String>()
            .map((n) => SyncStatus.values.byName(n))
            .toSet(),
        hasCover: json['hasCover'] as bool?,
        // Sets saved between US-121 and US-165 also hold bpmMin, bpmMax,
        // musicalKeys, energyLevels and gigCrates; they are ignored.
      );

  String toJsonString() => jsonEncode(toJson());

  static CollectionFilterSet fromJsonString(String s) =>
      fromJson(jsonDecode(s) as Map<String, dynamic>);
}

import 'dart:convert';

import 'cached_release_metadata.dart';
import 'collection_item.dart';
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
    this.bpmMin,
    this.bpmMax,
    this.musicalKeys = const {},
    this.energyLevels = const {},
    this.gigCrates = const {},
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

  // DJ fields (US-121)
  final int? bpmMin;
  final int? bpmMax;
  final Set<MusicalKey> musicalKeys;
  final Set<int> energyLevels;
  final Set<String> gigCrates;

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
      hasCover == null &&
      bpmMin == null &&
      bpmMax == null &&
      musicalKeys.isEmpty &&
      energyLevels.isEmpty &&
      gigCrates.isEmpty;

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
      (hasCover != null ? 1 : 0) +
      ((bpmMin != null || bpmMax != null) ? 1 : 0) +
      (musicalKeys.isNotEmpty ? 1 : 0) +
      (energyLevels.isNotEmpty ? 1 : 0) +
      (gigCrates.isNotEmpty ? 1 : 0);

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
      if (formats.isNotEmpty &&
          (item.format == null || !formats.contains(item.format))) {
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
      if (bpmMin != null && (item.bpm == null || item.bpm! < bpmMin!)) {
        return false;
      }
      if (bpmMax != null && (item.bpm == null || item.bpm! > bpmMax!)) {
        return false;
      }
      if (musicalKeys.isNotEmpty &&
          (item.musicalKey == null || !musicalKeys.contains(item.musicalKey))) {
        return false;
      }
      if (energyLevels.isNotEmpty &&
          (item.energyLevel == null ||
              !energyLevels.contains(item.energyLevel))) {
        return false;
      }
      if (gigCrates.isNotEmpty && !item.gigCrates.any(gigCrates.contains)) {
        return false;
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
    'bpmMin': bpmMin,
    'bpmMax': bpmMax,
    'musicalKeys': musicalKeys.map((k) => k.name).toList(),
    'energyLevels': (energyLevels.toList()..sort()),
    'gigCrates': gigCrates.toList(),
  };

  static CollectionFilterSet fromJson(Map<String, dynamic> json) =>
      CollectionFilterSet(
        decades: (json['decades'] as List).cast<int>().toSet(),
        formats: (json['formats'] as List).cast<String>().toSet(),
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
        // DJ keys are absent in payloads saved before US-121; default them
        // so old saved searches keep loading.
        bpmMin: json['bpmMin'] as int?,
        bpmMax: json['bpmMax'] as int?,
        musicalKeys: ((json['musicalKeys'] as List?) ?? const [])
            .cast<String>()
            .map((n) => MusicalKey.values.byName(n))
            .toSet(),
        energyLevels: ((json['energyLevels'] as List?) ?? const [])
            .cast<int>()
            .toSet(),
        gigCrates: ((json['gigCrates'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
      );

  String toJsonString() => jsonEncode(toJson());

  static CollectionFilterSet fromJsonString(String s) =>
      fromJson(jsonDecode(s) as Map<String, dynamic>);
}

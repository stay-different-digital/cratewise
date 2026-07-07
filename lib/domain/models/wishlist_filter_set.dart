import 'dart:convert';

import 'cached_release_metadata.dart';
import 'sync_status.dart';
import 'wishlist_item.dart';

class WishlistFilterSet {
  const WishlistFilterSet({
    this.decades = const {},
    this.formats = const {},
    this.labels = const {},
    this.genres = const {},
    this.styles = const {},
    this.priorities = const {},
    this.syncStatuses = const {},
    this.hasTargetPrice,
    this.hasCover,
  });

  final Set<int> decades;
  final Set<String> formats;
  final Set<String> labels;
  final Set<String> genres;
  final Set<String> styles;
  final Set<WishlistPriority> priorities;
  final Set<SyncStatus> syncStatuses;
  final bool? hasTargetPrice;
  final bool? hasCover;

  bool get isEmpty =>
      decades.isEmpty &&
      formats.isEmpty &&
      labels.isEmpty &&
      genres.isEmpty &&
      styles.isEmpty &&
      priorities.isEmpty &&
      syncStatuses.isEmpty &&
      hasTargetPrice == null &&
      hasCover == null;

  int get activeCount =>
      (decades.isNotEmpty ? 1 : 0) +
      (formats.isNotEmpty ? 1 : 0) +
      (labels.isNotEmpty ? 1 : 0) +
      (genres.isNotEmpty ? 1 : 0) +
      (styles.isNotEmpty ? 1 : 0) +
      (priorities.isNotEmpty ? 1 : 0) +
      (syncStatuses.isNotEmpty ? 1 : 0) +
      (hasTargetPrice != null ? 1 : 0) +
      (hasCover != null ? 1 : 0);

  List<WishlistItem> apply(
    List<WishlistItem> items, {
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
      if (priorities.isNotEmpty && !priorities.contains(item.priority)) {
        return false;
      }
      if (syncStatuses.isNotEmpty && !syncStatuses.contains(item.syncStatus)) {
        return false;
      }
      if (hasTargetPrice != null) {
        if ((item.targetPrice != null) != hasTargetPrice) return false;
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
    'priorities': priorities.map((p) => p.name).toList(),
    'syncStatuses': syncStatuses.map((s) => s.name).toList(),
    'hasTargetPrice': hasTargetPrice,
    'hasCover': hasCover,
  };

  static WishlistFilterSet fromJson(Map<String, dynamic> json) =>
      WishlistFilterSet(
        decades: (json['decades'] as List).cast<int>().toSet(),
        formats: (json['formats'] as List).cast<String>().toSet(),
        labels: (json['labels'] as List).cast<String>().toSet(),
        genres: (json['genres'] as List).cast<String>().toSet(),
        styles: (json['styles'] as List).cast<String>().toSet(),
        priorities: (json['priorities'] as List)
            .cast<String>()
            .map((n) => WishlistPriority.values.byName(n))
            .toSet(),
        syncStatuses: (json['syncStatuses'] as List)
            .cast<String>()
            .map((n) => SyncStatus.values.byName(n))
            .toSet(),
        hasTargetPrice: json['hasTargetPrice'] as bool?,
        hasCover: json['hasCover'] as bool?,
      );

  String toJsonString() => jsonEncode(toJson());

  static WishlistFilterSet fromJsonString(String s) =>
      fromJson(jsonDecode(s) as Map<String, dynamic>);
}

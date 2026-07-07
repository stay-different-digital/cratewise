import 'cached_release_metadata.dart';
import 'collection_item.dart';

class CollectionStats {
  const CollectionStats({
    required this.totalItems,
    required this.uniqueArtists,
    required this.uniqueLabels,
    required this.byDecade,
    required this.byFormat,
    required this.byGenre,
    required this.byStyle,
    required this.missingCover,
    required this.missingYear,
  });

  final int totalItems;
  final int uniqueArtists;
  final int uniqueLabels;

  /// Decade label → count. Sorted chronologically; 'Unknown' is always last.
  final Map<String, int> byDecade;

  /// Primary format → count. Sorted by count descending.
  final Map<String, int> byFormat;

  /// Genre → count. Sorted by count descending. Empty when no metadata cached.
  final Map<String, int> byGenre;

  /// Style → count. Sorted by count descending. Empty when no metadata cached.
  final Map<String, int> byStyle;

  final int missingCover;
  final int missingYear;

  static CollectionStats from(
    List<CollectionItem> items, {
    List<CachedReleaseMetadata> metadata = const [],
  }) {
    final artists = <String>{};
    final labels = <String>{};
    final decades = <String, int>{};
    final formats = <String, int>{};
    var missingCover = 0;
    var missingYear = 0;

    for (final item in items) {
      artists.add(item.artist);
      if (item.label != null) labels.add(item.label!);

      final decade = item.year != null
          ? '${(item.year! ~/ 10) * 10}s'
          : 'Unknown';
      decades[decade] = (decades[decade] ?? 0) + 1;

      final format = item.format?.split(',').first.trim() ?? 'Unknown';
      formats[format] = (formats[format] ?? 0) + 1;

      if (item.coverUrl == null) missingCover++;
      if (item.year == null) missingYear++;
    }

    // Build genre/style counts from cached metadata, joined by discogsReleaseId.
    final releaseIds = {for (final i in items) i.discogsReleaseId};
    final genres = <String, int>{};
    final styles = <String, int>{};
    for (final m in metadata) {
      if (!releaseIds.contains(m.discogsReleaseId)) continue;
      for (final g in m.genres) {
        genres[g] = (genres[g] ?? 0) + 1;
      }
      for (final s in m.styles) {
        styles[s] = (styles[s] ?? 0) + 1;
      }
    }

    Map<String, int> sortedByCount(Map<String, int> m) => Map.fromEntries(
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    final sortedDecades = Map.fromEntries(
      decades.entries.toList()..sort((a, b) {
        if (a.key == 'Unknown') return 1;
        if (b.key == 'Unknown') return -1;
        return a.key.compareTo(b.key);
      }),
    );

    return CollectionStats(
      totalItems: items.length,
      uniqueArtists: artists.length,
      uniqueLabels: labels.length,
      byDecade: sortedDecades,
      byFormat: sortedByCount(formats),
      byGenre: sortedByCount(genres),
      byStyle: sortedByCount(styles),
      missingCover: missingCover,
      missingYear: missingYear,
    );
  }
}

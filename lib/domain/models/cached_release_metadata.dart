import 'sync_status.dart';

class CachedReleaseMetadata {
  const CachedReleaseMetadata({
    required this.discogsReleaseId,
    required this.artist,
    required this.title,
    required this.genres,
    required this.styles,
    required this.tracklist,
    required this.barcodes,
    required this.fetchedAt,
    required this.cacheSource,
    required this.syncStatus,
    this.label,
    this.catno,
    this.format,
    this.country,
    this.year,
    this.notes,
    this.coverUrl,
  });

  final int discogsReleaseId;
  final String artist;
  final String title;
  final String? label;
  final String? catno;
  final String? format;
  final String? country;
  final int? year;
  final List<String> genres;
  final List<String> styles;
  final List<String> tracklist;
  final String? notes;
  final List<String> barcodes;
  final String? coverUrl;
  final DateTime fetchedAt;
  final String cacheSource;
  final SyncStatus syncStatus;

  CachedReleaseMetadata copyWith({
    int? discogsReleaseId,
    String? artist,
    String? title,
    String? label,
    String? catno,
    String? format,
    String? country,
    int? year,
    List<String>? genres,
    List<String>? styles,
    List<String>? tracklist,
    String? notes,
    List<String>? barcodes,
    String? coverUrl,
    DateTime? fetchedAt,
    String? cacheSource,
    SyncStatus? syncStatus,
  }) {
    return CachedReleaseMetadata(
      discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      label: label ?? this.label,
      catno: catno ?? this.catno,
      format: format ?? this.format,
      country: country ?? this.country,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      styles: styles ?? this.styles,
      tracklist: tracklist ?? this.tracklist,
      notes: notes ?? this.notes,
      barcodes: barcodes ?? this.barcodes,
      coverUrl: coverUrl ?? this.coverUrl,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      cacheSource: cacheSource ?? this.cacheSource,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

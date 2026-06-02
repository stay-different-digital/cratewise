import 'sync_status.dart';

enum RecordCondition {
  mint,
  nearMint,
  veryGoodPlus,
  veryGood,
  goodPlus,
  good,
  fair,
  poor,
  notSet;

  String get label => switch (this) {
        mint => 'Mint (M)',
        nearMint => 'Near Mint (NM or M-)',
        veryGoodPlus => 'Very Good Plus (VG+)',
        veryGood => 'Very Good (VG)',
        goodPlus => 'Good Plus (G+)',
        good => 'Good (G)',
        fair => 'Fair (F)',
        poor => 'Poor (P)',
        notSet => 'Not set',
      };

  String get abbreviation => switch (this) {
        mint => 'M',
        nearMint => 'NM',
        veryGoodPlus => 'VG+',
        veryGood => 'VG',
        goodPlus => 'G+',
        good => 'G',
        fair => 'F',
        poor => 'P',
        notSet => '—',
      };
}

class CollectionItem {
  CollectionItem({
    required this.id,
    required this.discogsReleaseId,
    required this.artist,
    required this.title,
    required this.mediaCondition,
    required this.sleeveCondition,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.label,
    this.catno,
    this.format,
    this.country,
    this.year,
    this.coverUrl,
    this.notes,
    this.storageLocation,
    this.syncStatus = SyncStatus.localOnly,
  });

  final String id;
  final int discogsReleaseId;
  final String artist;
  final String title;
  final String? label;
  final String? catno;
  final String? format;
  final String? country;
  final int? year;
  final String? coverUrl;
  final RecordCondition mediaCondition;
  final RecordCondition sleeveCondition;
  final String? notes;
  final List<String> tags;
  final String? storageLocation;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionItem copyWith({
    String? id,
    int? discogsReleaseId,
    String? artist,
    String? title,
    String? label,
    String? catno,
    String? format,
    String? country,
    int? year,
    String? coverUrl,
    RecordCondition? mediaCondition,
    RecordCondition? sleeveCondition,
    String? notes,
    List<String>? tags,
    String? storageLocation,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      label: label ?? this.label,
      catno: catno ?? this.catno,
      format: format ?? this.format,
      country: country ?? this.country,
      year: year ?? this.year,
      coverUrl: coverUrl ?? this.coverUrl,
      mediaCondition: mediaCondition ?? this.mediaCondition,
      sleeveCondition: sleeveCondition ?? this.sleeveCondition,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      storageLocation: storageLocation ?? this.storageLocation,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

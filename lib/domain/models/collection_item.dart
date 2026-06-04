import 'dart:convert';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'discogsReleaseId': discogsReleaseId,
    'artist': artist,
    'title': title,
    'label': label,
    'catno': catno,
    'format': format,
    'country': country,
    'year': year,
    'coverUrl': coverUrl,
    'mediaCondition': mediaCondition.name,
    'sleeveCondition': sleeveCondition.name,
    'notes': notes,
    'tags': tags,
    'storageLocation': storageLocation,
    'syncStatus': syncStatus.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static CollectionItem fromJson(Map<String, dynamic> json) => CollectionItem(
    id: json['id'] as String,
    discogsReleaseId: json['discogsReleaseId'] as int,
    artist: json['artist'] as String,
    title: json['title'] as String,
    label: json['label'] as String?,
    catno: json['catno'] as String?,
    format: json['format'] as String?,
    country: json['country'] as String?,
    year: json['year'] as int?,
    coverUrl: json['coverUrl'] as String?,
    mediaCondition: RecordCondition.values.byName(
      json['mediaCondition'] as String,
    ),
    sleeveCondition: RecordCondition.values.byName(
      json['sleeveCondition'] as String,
    ),
    notes: json['notes'] as String?,
    tags: (json['tags'] as List<dynamic>).cast<String>(),
    storageLocation: json['storageLocation'] as String?,
    syncStatus: SyncStatus.values.byName(json['syncStatus'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static CollectionItem? tryFromJson(String encoded) {
    try {
      return fromJson(jsonDecode(encoded) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

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

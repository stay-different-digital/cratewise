import 'dart:convert';

import 'sync_status.dart';

/// Valid BPM range for DJ metadata. Shared by the edit UI and the CSV
/// import validator so the two layers cannot drift apart.
const int kMinBpm = 20;
const int kMaxBpm = 300;

enum MusicalKey {
  cMajor,
  dbMajor,
  dMajor,
  ebMajor,
  eMajor,
  fMajor,
  gbMajor,
  gMajor,
  abMajor,
  aMajor,
  bbMajor,
  bMajor,
  cMinor,
  dbMinor,
  dMinor,
  ebMinor,
  eMinor,
  fMinor,
  gbMinor,
  gMinor,
  abMinor,
  aMinor,
  bbMinor,
  bMinor;

  String get label => switch (this) {
    cMajor => 'C major',
    dbMajor => 'D♭ major',
    dMajor => 'D major',
    ebMajor => 'E♭ major',
    eMajor => 'E major',
    fMajor => 'F major',
    gbMajor => 'G♭ major',
    gMajor => 'G major',
    abMajor => 'A♭ major',
    aMajor => 'A major',
    bbMajor => 'B♭ major',
    bMajor => 'B major',
    cMinor => 'C minor',
    dbMinor => 'D♭ minor',
    dMinor => 'D minor',
    ebMinor => 'E♭ minor',
    eMinor => 'E minor',
    fMinor => 'F minor',
    gbMinor => 'G♭ minor',
    gMinor => 'G minor',
    abMinor => 'A♭ minor',
    aMinor => 'A minor',
    bbMinor => 'B♭ minor',
    bMinor => 'B minor',
  };

  static final Map<String, MusicalKey> _byNormalizedLabel = {
    for (final k in values) ...{
      k.label.toLowerCase(): k,
      k.label.replaceAll('♭', 'b').toLowerCase(): k,
      k.name.toLowerCase(): k,
    },
  };

  /// Case-insensitive lookup accepting the exact label ('A♭ major'), the
  /// ASCII-flat spelling ('Ab major'), or the enum name ('abMajor'), so
  /// hand-edited CSV imports don't fail on the unicode flat sign.
  static MusicalKey? tryFromLabel(String label) =>
      _byNormalizedLabel[label.trim().toLowerCase()];
}

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
    this.discogsInstanceId,
    this.bpm,
    this.musicalKey,
    this.energyLevel,
    List<String>? gigCrates,
  }) : gigCrates = gigCrates ?? const [];

  final String id;
  final int discogsReleaseId;

  /// The Discogs collection *instance* id, captured when the item is added to
  /// or imported from a Discogs collection. Needed to remove this specific
  /// collection entry from Discogs later (US-72). Null until linked.
  final int? discogsInstanceId;
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

  // DJ metadata (US-121) — local only, never synced to Discogs.
  final int? bpm;
  final MusicalKey? musicalKey;
  final int? energyLevel; // 1–5
  final List<String> gigCrates;

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
    'discogsInstanceId': discogsInstanceId,
    'bpm': bpm,
    'musicalKey': musicalKey?.name,
    'energyLevel': energyLevel,
    'gigCrates': gigCrates,
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
    discogsInstanceId: json['discogsInstanceId'] as int?,
    bpm: json['bpm'] as int?,
    musicalKey: json['musicalKey'] == null
        ? null
        : MusicalKey.values.byName(json['musicalKey'] as String),
    energyLevel: json['energyLevel'] as int?,
    gigCrates: (json['gigCrates'] as List<dynamic>?)?.cast<String>() ?? [],
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
    int? discogsInstanceId,
    // The DJ fields are nullable AND clearable, so they use closures:
    // omit to keep the current value, pass `() => x` to set, `() => null`
    // to clear.
    int? Function()? bpm,
    MusicalKey? Function()? musicalKey,
    int? Function()? energyLevel,
    List<String>? gigCrates,
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
      discogsInstanceId: discogsInstanceId ?? this.discogsInstanceId,
      bpm: bpm != null ? bpm() : this.bpm,
      musicalKey: musicalKey != null ? musicalKey() : this.musicalKey,
      energyLevel: energyLevel != null ? energyLevel() : this.energyLevel,
      gigCrates: gigCrates ?? this.gigCrates,
    );
  }
}

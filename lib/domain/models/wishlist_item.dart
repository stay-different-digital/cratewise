import 'dart:convert';

import 'sync_status.dart';

enum WishlistPriority {
  low,
  medium,
  high,
  mustHave;

  String get label => switch (this) {
    low => 'Low',
    medium => 'Medium',
    high => 'High',
    mustHave => 'Must have',
  };
}

class WishlistItem {
  WishlistItem({
    required this.id,
    required this.discogsReleaseId,
    required this.artist,
    required this.title,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.label,
    this.catno,
    this.format,
    this.country,
    this.year,
    this.coverUrl,
    this.targetPrice,
    this.notes,
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
  final double? targetPrice;
  final WishlistPriority priority;
  final String? notes;
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
    'targetPrice': targetPrice,
    'priority': priority.name,
    'notes': notes,
    'syncStatus': syncStatus.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static WishlistItem fromJson(Map<String, dynamic> json) => WishlistItem(
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
    targetPrice: (json['targetPrice'] as num?)?.toDouble(),
    priority: WishlistPriority.values.byName(json['priority'] as String),
    notes: json['notes'] as String?,
    syncStatus: SyncStatus.values.byName(json['syncStatus'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static WishlistItem? tryFromJson(String encoded) {
    try {
      return fromJson(jsonDecode(encoded) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  WishlistItem copyWith({
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
    double? targetPrice,
    bool clearTargetPrice = false,
    WishlistPriority? priority,
    String? notes,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WishlistItem(
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
      targetPrice: clearTargetPrice ? null : (targetPrice ?? this.targetPrice),
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

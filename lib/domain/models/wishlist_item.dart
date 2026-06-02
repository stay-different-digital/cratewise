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

import 'dart:convert';

import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

WishlistItem _makeItem({
  String id = 'item-1',
  int discogsReleaseId = 249504,
  String artist = 'Miles Davis',
  String title = 'Kind Of Blue',
  String? label = 'Columbia',
  String? catno = 'CL 1355',
  String? format = 'Vinyl, LP',
  String? country = 'US',
  int? year = 1959,
  String? coverUrl = 'https://i.discogs.com/cover.jpg',
  double? targetPrice = 25.0,
  WishlistPriority priority = WishlistPriority.high,
  String? notes,
  SyncStatus syncStatus = SyncStatus.localOnly,
}) {
  final now = DateTime(2026, 6, 1, 10, 0, 0);
  return WishlistItem(
    id: id,
    discogsReleaseId: discogsReleaseId,
    artist: artist,
    title: title,
    label: label,
    catno: catno,
    format: format,
    country: country,
    year: year,
    coverUrl: coverUrl,
    targetPrice: targetPrice,
    priority: priority,
    notes: notes,
    syncStatus: syncStatus,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('WishlistItem.toJson / fromJson', () {
    test('round-trips all non-null fields', () {
      final item = _makeItem();
      final decoded = WishlistItem.fromJson(item.toJson());
      expect(decoded.id, item.id);
      expect(decoded.discogsReleaseId, item.discogsReleaseId);
      expect(decoded.artist, item.artist);
      expect(decoded.title, item.title);
      expect(decoded.label, item.label);
      expect(decoded.catno, item.catno);
      expect(decoded.format, item.format);
      expect(decoded.country, item.country);
      expect(decoded.year, item.year);
      expect(decoded.coverUrl, item.coverUrl);
      expect(decoded.targetPrice, item.targetPrice);
      expect(decoded.priority, item.priority);
      expect(decoded.notes, item.notes);
      expect(decoded.syncStatus, item.syncStatus);
      expect(decoded.createdAt, item.createdAt);
      expect(decoded.updatedAt, item.updatedAt);
    });

    test('round-trips nullable fields as null', () {
      final item = _makeItem(
        label: null,
        catno: null,
        format: null,
        country: null,
        year: null,
        coverUrl: null,
        targetPrice: null,
        notes: null,
      );
      final decoded = WishlistItem.fromJson(item.toJson());
      expect(decoded.label, isNull);
      expect(decoded.year, isNull);
      expect(decoded.targetPrice, isNull);
      expect(decoded.notes, isNull);
    });

    test('tryFromJson returns item for valid JSON string', () {
      final item = _makeItem();
      final encoded = jsonEncode(item.toJson());
      final result = WishlistItem.tryFromJson(encoded);
      expect(result, isNotNull);
      expect(result!.id, item.id);
    });

    test('tryFromJson returns null for malformed JSON', () {
      expect(WishlistItem.tryFromJson('not json at all'), isNull);
    });

    test('tryFromJson returns null for JSON missing required fields', () {
      expect(WishlistItem.tryFromJson('{"id":"x"}'), isNull);
    });
  });
}

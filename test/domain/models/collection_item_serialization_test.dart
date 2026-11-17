import 'dart:convert';

import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _makeItem({
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
  RecordCondition mediaCondition = RecordCondition.veryGood,
  RecordCondition sleeveCondition = RecordCondition.nearMint,
  String? notes,
  List<String> tags = const ['jazz'],
  String? storageLocation = 'Shelf A',
  SyncStatus syncStatus = SyncStatus.localOnly,
  int? discogsInstanceId = 778899,
}) {
  final now = DateTime(2026, 6, 1, 10, 0, 0);
  return CollectionItem(
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
    mediaCondition: mediaCondition,
    sleeveCondition: sleeveCondition,
    notes: notes,
    tags: tags,
    storageLocation: storageLocation,
    syncStatus: syncStatus,
    discogsInstanceId: discogsInstanceId,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CollectionItem.toJson / fromJson', () {
    test('round-trips all non-null fields', () {
      final item = _makeItem();
      final decoded = CollectionItem.fromJson(item.toJson());
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
      expect(decoded.mediaCondition, item.mediaCondition);
      expect(decoded.sleeveCondition, item.sleeveCondition);
      expect(decoded.notes, item.notes);
      expect(decoded.tags, item.tags);
      expect(decoded.storageLocation, item.storageLocation);
      expect(decoded.syncStatus, item.syncStatus);
      expect(decoded.discogsInstanceId, item.discogsInstanceId);
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
        notes: null,
        storageLocation: null,
        tags: const [],
        discogsInstanceId: null,
      );
      final decoded = CollectionItem.fromJson(item.toJson());
      expect(decoded.discogsInstanceId, isNull);
      expect(decoded.label, isNull);
      expect(decoded.catno, isNull);
      expect(decoded.year, isNull);
      expect(decoded.coverUrl, isNull);
      expect(decoded.notes, isNull);
      expect(decoded.storageLocation, isNull);
      expect(decoded.tags, isEmpty);
    });

    test('tryFromJson returns item for valid JSON string', () {
      final item = _makeItem();
      final encoded = jsonEncode(item.toJson());
      final result = CollectionItem.tryFromJson(encoded);
      expect(result, isNotNull);
      expect(result!.id, item.id);
    });

    test('tryFromJson returns null for malformed JSON', () {
      expect(CollectionItem.tryFromJson('not json at all'), isNull);
    });

    test('tryFromJson returns null for JSON missing required fields', () {
      expect(CollectionItem.tryFromJson('{"id":"x"}'), isNull);
    });
  });

  group('CollectionItem JSON stored before US-165', () {
    test('DJ keys in old payloads are ignored', () {
      final json = {
        'id': 'x',
        'discogsReleaseId': 1,
        'artist': 'A',
        'title': 'T',
        'mediaCondition': 'veryGood',
        'sleeveCondition': 'veryGood',
        'tags': <String>[],
        'syncStatus': 'localOnly',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        'bpm': 128,
        'musicalKey': 'aMinor',
        'energyLevel': 4,
        'gigCrates': ['Warmup'],
      };
      final item = CollectionItem.fromJson(json);
      expect(item.id, 'x');
      expect(item.toJson().keys, isNot(contains('bpm')));
    });
  });
}

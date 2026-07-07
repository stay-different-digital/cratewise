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

    test('round-trips DJ fields (US-121)', () {
      final item = CollectionItem(
        id: 'dj-1',
        discogsReleaseId: 11111,
        artist: 'Daft Punk',
        title: 'Around the World',
        mediaCondition: RecordCondition.nearMint,
        sleeveCondition: RecordCondition.veryGoodPlus,
        tags: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        bpm: 121,
        musicalKey: MusicalKey.aMajor,
        energyLevel: 5,
        gigCrates: ['House Night', 'Summer Set'],
      );
      final decoded = CollectionItem.fromJson(item.toJson());
      expect(decoded.bpm, 121);
      expect(decoded.musicalKey, MusicalKey.aMajor);
      expect(decoded.energyLevel, 5);
      expect(decoded.gigCrates, ['House Night', 'Summer Set']);
    });

    test('fromJson with missing DJ fields defaults to null/empty (US-121)', () {
      final item = _makeItem();
      final json = item.toJson()
        ..remove('bpm')
        ..remove('musicalKey')
        ..remove('energyLevel')
        ..remove('gigCrates');
      final decoded = CollectionItem.fromJson(json);
      expect(decoded.bpm, isNull);
      expect(decoded.musicalKey, isNull);
      expect(decoded.energyLevel, isNull);
      expect(decoded.gigCrates, isEmpty);
    });

    test('copyWith keeps DJ fields when omitted and clears via closure', () {
      final item = _makeItem().copyWith(
        bpm: () => 128,
        musicalKey: () => MusicalKey.gbMinor,
        energyLevel: () => 4,
        gigCrates: ['Warmup'],
      );

      final untouched = item.copyWith(notes: 'other edit');
      expect(untouched.bpm, 128);
      expect(untouched.musicalKey, MusicalKey.gbMinor);
      expect(untouched.energyLevel, 4);
      expect(untouched.gigCrates, ['Warmup']);

      final cleared = item.copyWith(
        bpm: () => null,
        musicalKey: () => null,
        energyLevel: () => null,
        gigCrates: [],
      );
      expect(cleared.bpm, isNull);
      expect(cleared.musicalKey, isNull);
      expect(cleared.energyLevel, isNull);
      expect(cleared.gigCrates, isEmpty);
    });
  });
}

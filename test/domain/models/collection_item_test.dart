import 'package:cratewise/domain/models/collection_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 1, 1);
  final updatedAt = DateTime(2026, 1, 2);

  CollectionItem base() => CollectionItem(
        id: 'local-1',
        discogsReleaseId: 249504,
        artist: 'Miles Davis',
        title: 'Kind Of Blue',
        mediaCondition: RecordCondition.veryGoodPlus,
        sleeveCondition: RecordCondition.veryGood,
        tags: const ['jazz', 'essential'],
        createdAt: createdAt,
        updatedAt: updatedAt,
        label: 'Columbia',
        catno: 'CL 1355',
        format: 'Vinyl, LP, Album',
        country: 'US',
        year: 1959,
        coverUrl: 'https://i.discogs.com/cover.jpg',
        notes: 'Great pressing.',
        storageLocation: 'Shelf A',
      );

  group('CollectionItem', () {
    test('stores all required fields', () {
      final item = base();
      expect(item.id, 'local-1');
      expect(item.discogsReleaseId, 249504);
      expect(item.artist, 'Miles Davis');
      expect(item.title, 'Kind Of Blue');
      expect(item.mediaCondition, RecordCondition.veryGoodPlus);
      expect(item.sleeveCondition, RecordCondition.veryGood);
      expect(item.tags, ['jazz', 'essential']);
      expect(item.createdAt, createdAt);
      expect(item.updatedAt, updatedAt);
    });

    test('stores all optional fields', () {
      final item = base();
      expect(item.label, 'Columbia');
      expect(item.catno, 'CL 1355');
      expect(item.format, 'Vinyl, LP, Album');
      expect(item.country, 'US');
      expect(item.year, 1959);
      expect(item.coverUrl, 'https://i.discogs.com/cover.jpg');
      expect(item.notes, 'Great pressing.');
      expect(item.storageLocation, 'Shelf A');
    });

    test('optional fields default to null', () {
      final item = CollectionItem(
        id: 'local-2',
        discogsReleaseId: 1,
        artist: 'Unknown',
        title: 'Untitled',
        mediaCondition: RecordCondition.good,
        sleeveCondition: RecordCondition.fair,
        tags: const [],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      expect(item.label, isNull);
      expect(item.catno, isNull);
      expect(item.format, isNull);
      expect(item.country, isNull);
      expect(item.year, isNull);
      expect(item.coverUrl, isNull);
      expect(item.notes, isNull);
      expect(item.storageLocation, isNull);
    });

    group('copyWith', () {
      test('returns equal item when no overrides given', () {
        final item = base();
        final copy = item.copyWith();
        expect(copy.id, item.id);
        expect(copy.title, item.title);
        expect(copy.mediaCondition, item.mediaCondition);
        expect(copy.tags, item.tags);
      });

      test('overrides specified fields', () {
        final newUpdated = DateTime(2026, 6, 1);
        final copy = base().copyWith(
          mediaCondition: RecordCondition.nearMint,
          notes: 'Clean copy.',
          updatedAt: newUpdated,
        );
        expect(copy.mediaCondition, RecordCondition.nearMint);
        expect(copy.notes, 'Clean copy.');
        expect(copy.updatedAt, newUpdated);
      });

      test('does not mutate original', () {
        final item = base();
        item.copyWith(mediaCondition: RecordCondition.poor);
        expect(item.mediaCondition, RecordCondition.veryGoodPlus);
      });
    });
  });

  group('RecordCondition', () {
    test('all eight grades are defined', () {
      expect(RecordCondition.values.length, 8);
    });

    test('label returns human-readable string', () {
      expect(RecordCondition.nearMint.label, 'Near Mint (NM or M-)');
      expect(RecordCondition.veryGoodPlus.label, 'Very Good Plus (VG+)');
    });

    test('abbreviation returns short grade code', () {
      expect(RecordCondition.mint.abbreviation, 'M');
      expect(RecordCondition.veryGoodPlus.abbreviation, 'VG+');
      expect(RecordCondition.poor.abbreviation, 'P');
    });
  });
}

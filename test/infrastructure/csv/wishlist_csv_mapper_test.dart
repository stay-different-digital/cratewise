import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/infrastructure/csv/wishlist_csv_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

WishlistItem _fullItem() => WishlistItem(
      id: 'wish-1',
      discogsReleaseId: 54321,
      artist: 'John Coltrane',
      title: 'A Love Supreme',
      label: 'Impulse!',
      catno: 'A-77',
      format: 'LP',
      country: 'US',
      year: 1965,
      coverUrl: 'https://img.example.com/coltrane.jpg',
      targetPrice: 49.99,
      priority: WishlistPriority.high,
      notes: 'Original mono pressing',
      syncStatus: SyncStatus.localOnly,
      createdAt: DateTime.utc(2024, 2, 20, 9, 0, 0),
      updatedAt: DateTime.utc(2024, 7, 5, 14, 0, 0),
    );

WishlistItem _minimalItem() => WishlistItem(
      id: 'wish-2',
      discogsReleaseId: 77,
      artist: 'Various',
      title: 'Compilation',
      priority: WishlistPriority.low,
      syncStatus: SyncStatus.localOnly,
      createdAt: DateTime.utc(2024, 4, 1, 0, 0, 0),
      updatedAt: DateTime.utc(2024, 4, 1, 0, 0, 0),
    );

void main() {
  const mapper = WishlistCsvMapper();

  group('wishlistCsvHeaders', () {
    test('contains 13 headers', () {
      expect(wishlistCsvHeaders.length, 13);
    });

    test('first header is Artist', () {
      expect(wishlistCsvHeaders.first, 'Artist');
    });

    test('last header is Updated Date', () {
      expect(wishlistCsvHeaders.last, 'Updated Date');
    });

    test('contains expected fields', () {
      expect(wishlistCsvHeaders, contains('Discogs Release ID'));
      expect(wishlistCsvHeaders, contains('Target Price'));
      expect(wishlistCsvHeaders, contains('Priority'));
      expect(wishlistCsvHeaders, contains('Notes'));
      expect(wishlistCsvHeaders, contains('Created Date'));
    });

    test('does not contain collection-only fields', () {
      expect(wishlistCsvHeaders, isNot(contains('Media Condition')));
      expect(wishlistCsvHeaders, isNot(contains('Sleeve Condition')));
      expect(wishlistCsvHeaders, isNot(contains('Tags')));
      expect(wishlistCsvHeaders, isNot(contains('Storage Location')));
    });
  });

  group('WishlistCsvMapper.toRow — fully populated item', () {
    late List<String> row;

    setUpAll(() {
      row = mapper.toRow(_fullItem());
    });

    test('row length matches header count', () {
      expect(row.length, wishlistCsvHeaders.length);
    });

    test('artist maps to column 0', () {
      expect(row[0], 'John Coltrane');
    });

    test('title maps to column 1', () {
      expect(row[1], 'A Love Supreme');
    });

    test('label maps to column 2', () {
      expect(row[2], 'Impulse!');
    });

    test('catno maps to column 3', () {
      expect(row[3], 'A-77');
    });

    test('format maps to column 4', () {
      expect(row[4], 'LP');
    });

    test('country maps to column 5', () {
      expect(row[5], 'US');
    });

    test('year maps to column 6 as string', () {
      expect(row[6], '1965');
    });

    test('discogsReleaseId maps to column 7 as string', () {
      expect(row[7], '54321');
    });

    test('targetPrice maps to column 8 formatted to 2 decimal places', () {
      expect(row[8], '49.99');
    });

    test('priority maps to column 9 as label', () {
      expect(row[9], 'High');
    });

    test('notes maps to column 10', () {
      expect(row[10], 'Original mono pressing');
    });

    test('createdAt maps to column 11 as ISO 8601', () {
      expect(row[11], '2024-02-20T09:00:00.000Z');
    });

    test('updatedAt maps to column 12 as ISO 8601', () {
      expect(row[12], '2024-07-05T14:00:00.000Z');
    });
  });

  group('WishlistCsvMapper.toRow — optional fields absent', () {
    late List<String> row;

    setUpAll(() {
      row = mapper.toRow(_minimalItem());
    });

    test('row length matches header count', () {
      expect(row.length, wishlistCsvHeaders.length);
    });

    test('null label becomes empty string', () {
      expect(row[2], '');
    });

    test('null catno becomes empty string', () {
      expect(row[3], '');
    });

    test('null format becomes empty string', () {
      expect(row[4], '');
    });

    test('null country becomes empty string', () {
      expect(row[5], '');
    });

    test('null year becomes empty string', () {
      expect(row[6], '');
    });

    test('null targetPrice becomes empty string', () {
      expect(row[8], '');
    });

    test('null notes becomes empty string', () {
      expect(row[10], '');
    });
  });

  group('WishlistCsvMapper.toRow — target price formatting', () {
    test('integer price is formatted to two decimal places', () {
      final item = _fullItem().copyWith(targetPrice: 20.0);
      expect(mapper.toRow(item)[8], '20.00');
    });

    test('price with one decimal is padded to two', () {
      final item = _fullItem().copyWith(targetPrice: 15.5);
      expect(mapper.toRow(item)[8], '15.50');
    });

    test('price with many decimals is rounded to two', () {
      final item = _fullItem().copyWith(targetPrice: 9.999);
      expect(mapper.toRow(item)[8], '10.00');
    });

    test('null price cleared via clearTargetPrice maps to empty string', () {
      final item = _fullItem().copyWith(clearTargetPrice: true);
      expect(mapper.toRow(item)[8], '');
    });
  });

  group('WishlistCsvMapper.toRow — all WishlistPriority values', () {
    for (final priority in WishlistPriority.values) {
      test('${priority.name} maps to its label string', () {
        final item = _fullItem().copyWith(priority: priority);
        expect(mapper.toRow(item)[9], priority.label);
      });
    }
  });

  group('WishlistCsvMapper.toRow — date formatting', () {
    test('dates include time component', () {
      final row = mapper.toRow(_fullItem());
      expect(row[11], contains('T'));
      expect(row[12], contains('T'));
    });

    test('UTC dates end with Z', () {
      final row = mapper.toRow(_fullItem());
      expect(row[11], endsWith('Z'));
      expect(row[12], endsWith('Z'));
    });
  });
}

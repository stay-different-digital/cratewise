import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_filter_set.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

WishlistItem _item({
  String id = '1',
  int releaseId = 1,
  String? format,
  String? label,
  int? year,
  WishlistPriority priority = WishlistPriority.medium,
  double? targetPrice,
  String? coverUrl,
  SyncStatus syncStatus = SyncStatus.localOnly,
}) => WishlistItem(
  id: id,
  discogsReleaseId: releaseId,
  artist: 'A',
  title: 'T',
  priority: priority,
  format: format,
  label: label,
  year: year,
  targetPrice: targetPrice,
  coverUrl: coverUrl,
  syncStatus: syncStatus,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

CachedReleaseMetadata _meta({
  int releaseId = 1,
  List<String> genres = const [],
  List<String> styles = const [],
}) => CachedReleaseMetadata(
  discogsReleaseId: releaseId,
  artist: 'A',
  title: 'T',
  genres: genres,
  styles: styles,
  tracklist: const [],
  identifiers: const [],
  fetchedAt: DateTime(2026),
  cacheSource: 'api',
  syncStatus: SyncStatus.localOnly,
);

void main() {
  group('WishlistFilterSet', () {
    test('isEmpty when no filters', () {
      expect(const WishlistFilterSet().isEmpty, isTrue);
    });

    test('isEmpty false when priority set', () {
      expect(
        WishlistFilterSet(priorities: {WishlistPriority.high}).isEmpty,
        isFalse,
      );
    });

    test('apply with empty filter returns all items', () {
      final items = [_item(id: '1'), _item(id: '2')];
      expect(const WishlistFilterSet().apply(items), hasLength(2));
    });

    test('filters by priority', () {
      final items = [
        _item(id: '1', priority: WishlistPriority.high),
        _item(id: '2', priority: WishlistPriority.low),
      ];
      final result = WishlistFilterSet(
        priorities: {WishlistPriority.high},
      ).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by decade', () {
      final items = [_item(id: '1', year: 1990), _item(id: '2', year: 2005)];
      final result = WishlistFilterSet(decades: {1990}).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by format', () {
      final items = [
        _item(id: '1', format: 'LP'),
        _item(id: '2', format: '12"'),
      ];
      final result = WishlistFilterSet(formats: {'LP'}).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by hasTargetPrice = true', () {
      final items = [
        _item(id: '1', targetPrice: 15.0),
        _item(id: '2', targetPrice: null),
      ];
      final result = WishlistFilterSet(hasTargetPrice: true).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by hasTargetPrice = false', () {
      final items = [
        _item(id: '1', targetPrice: 15.0),
        _item(id: '2', targetPrice: null),
      ];
      final result = WishlistFilterSet(hasTargetPrice: false).apply(items);
      expect(result.map((i) => i.id), ['2']);
    });

    test('filters by hasCover', () {
      final items = [
        _item(id: '1', coverUrl: 'https://cover.jpg'),
        _item(id: '2', coverUrl: null),
      ];
      final result = WishlistFilterSet(hasCover: true).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('filters by genre from metadata', () {
      final items = [
        _item(id: '1', releaseId: 10),
        _item(id: '2', releaseId: 20),
      ];
      final meta = [
        _meta(releaseId: 10, genres: ['Electronic']),
        _meta(releaseId: 20, genres: ['Jazz']),
      ];
      final result = WishlistFilterSet(
        genres: {'Electronic'},
      ).apply(items, metadata: meta);
      expect(result.map((i) => i.id), ['1']);
    });

    test('combined filters: priority AND format', () {
      final items = [
        _item(id: '1', priority: WishlistPriority.high, format: 'LP'),
        _item(id: '2', priority: WishlistPriority.high, format: '12"'),
        _item(id: '3', priority: WishlistPriority.low, format: 'LP'),
      ];
      final result = WishlistFilterSet(
        priorities: {WishlistPriority.high},
        formats: {'LP'},
      ).apply(items);
      expect(result.map((i) => i.id), ['1']);
    });

    test('empty result when no items match', () {
      final items = [_item(id: '1', priority: WishlistPriority.low)];
      final result = WishlistFilterSet(
        priorities: {WishlistPriority.high},
      ).apply(items);
      expect(result, isEmpty);
    });

    test('toJson / fromJson round-trip', () {
      final original = WishlistFilterSet(
        priorities: {WishlistPriority.high, WishlistPriority.mustHave},
        formats: {'LP'},
        hasTargetPrice: true,
        hasCover: false,
      );
      final restored = WishlistFilterSet.fromJsonString(
        original.toJsonString(),
      );
      expect(restored.priorities, original.priorities);
      expect(restored.formats, original.formats);
      expect(restored.hasTargetPrice, original.hasTargetPrice);
      expect(restored.hasCover, original.hasCover);
    });
  });

  group('WishlistFilterSet — format types (US-147)', () {
    final vinyl = _item(id: 'v', format: 'Vinyl, LP, Album');
    final file = _item(id: 'f', format: 'File, FLAC');
    final mixed = _item(id: 'm', format: 'Vinyl, LP\nFile, MP3');

    test('"Vinyl" hides File-only items; mixed items count for each type', () {
      expect(
        const WishlistFilterSet(
          formats: {'Vinyl'},
        ).apply([vinyl, file, mixed]).map((i) => i.id),
        ['v', 'm'],
      );
      expect(
        const WishlistFilterSet(
          formats: {'File'},
        ).apply([vinyl, file, mixed]).map((i) => i.id),
        ['f', 'm'],
      );
    });

    test('saved sets with full format strings load as types', () {
      final old = {
        ...const WishlistFilterSet().toJson(),
        'formats': ['Vinyl, 12", 33 ⅓ RPM'],
      };
      expect(WishlistFilterSet.fromJson(old).formats, {'Vinyl'});
    });
  });
}

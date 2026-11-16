import 'package:cratewise/application/services/search_query_cache.dart';
import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/domain/models/search_filter.dart';
import 'package:cratewise/domain/models/search_result_page.dart';
import 'package:cratewise/domain/models/search_sort.dart';
import 'package:flutter_test/flutter_test.dart';

SearchResultPage _page(List<String> titles) {
  return SearchResultPage(
    items: titles
        .map(
          (t) => ReleaseSearchResult(
            id: 1,
            title: t,
            artist: '',
            format: '',
            label: '',
            country: '',
          ),
        )
        .toList(),
    currentPage: 1,
    totalPages: 1,
    totalResults: titles.length,
  );
}

void main() {
  group('SearchQueryCache', () {
    test('returns null for a missing key', () {
      final cache = SearchQueryCache();
      expect(cache.get('foo'), isNull);
    });

    test('returns a stored page', () {
      final cache = SearchQueryCache();
      final page = _page(['Kind Of Blue']);
      cache.put('miles', page);
      expect(cache.get('miles'), same(page));
    });

    test('returns null for an expired entry', () {
      DateTime now = DateTime(2026, 6, 9, 12);
      final cache = SearchQueryCache(
        ttl: const Duration(hours: 1),
        clock: () => now,
      );
      cache.put('miles', _page(['A']));
      // Advance clock past the TTL
      now = now.add(const Duration(hours: 2));
      expect(cache.get('miles'), isNull);
    });

    test('evicts the oldest entry when maxEntries is exceeded', () {
      final cache = SearchQueryCache(maxEntries: 2);
      cache.put('a', _page(['A']));
      cache.put('b', _page(['B']));
      cache.put('c', _page(['C'])); // should evict 'a'
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNotNull);
      expect(cache.get('c'), isNotNull);
    });

    test('get() refreshes recency so accessed entry is evicted last', () {
      final cache = SearchQueryCache(maxEntries: 2);
      cache.put('a', _page(['A']));
      cache.put('b', _page(['B']));
      cache.get('a'); // 'a' is now most recently used; 'b' becomes oldest
      cache.put('c', _page(['C'])); // should evict 'b'
      expect(cache.get('a'), isNotNull);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), isNotNull);
    });

    test(
      'normalizeKey trims, lowercases, defaults to All / relevance / any',
      () {
        expect(
          SearchQueryCache.normalizeKey('  Miles Davis  '),
          equals('all:relevance:any:miles davis'),
        );
        expect(
          SearchQueryCache.normalizeKey('BEATLES'),
          equals('all:relevance:any:beatles'),
        );
      },
    );

    test('normalizeKey scopes the key by filter (US-85)', () {
      expect(
        SearchQueryCache.normalizeKey('blue', SearchFilter.artist),
        equals('artist:relevance:any:blue'),
      );
      // Same text under different filters must not collide.
      expect(
        SearchQueryCache.normalizeKey('blue', SearchFilter.artist),
        isNot(equals(SearchQueryCache.normalizeKey('blue'))),
      );
      expect(
        SearchQueryCache.normalizeKey('blue', SearchFilter.label),
        equals('label:relevance:any:blue'),
      );
    });

    test('normalizeKey scopes the key by sort (US-133)', () {
      final relevance = SearchQueryCache.normalizeKey(
        'blue note',
        SearchFilter.label,
      );
      final newest = SearchQueryCache.normalizeKey(
        'blue note',
        SearchFilter.label,
        SearchSort.newestFirst,
      );
      final oldest = SearchQueryCache.normalizeKey(
        'blue note',
        SearchFilter.label,
        SearchSort.oldestFirst,
      );
      expect(newest, 'label:newestFirst:any:blue note');
      expect({relevance, newest, oldest}, hasLength(3));
    });

    test('normalizeKey scopes the key by the vinyl-only toggle (US-142)', () {
      final any = SearchQueryCache.normalizeKey(
        'blue note',
        SearchFilter.label,
      );
      final vinyl = SearchQueryCache.normalizeKey(
        'blue note',
        SearchFilter.label,
        SearchSort.relevance,
        true,
      );
      expect(vinyl, 'label:relevance:vinyl:blue note');
      expect(vinyl, isNot(any));
    });

    test('put overwrites an existing entry and resets its TTL', () {
      DateTime now = DateTime(2026, 6, 9, 12);
      final cache = SearchQueryCache(
        ttl: const Duration(hours: 1),
        clock: () => now,
      );
      final p1 = _page(['First']);
      final p2 = _page(['Second']);
      cache.put('q', p1);
      now = now.add(const Duration(minutes: 50)); // still within TTL
      cache.put('q', p2); // overwrite; new TTL starts from new 'now'
      now = now.add(
        const Duration(minutes: 20),
      ); // 70 min from put, 20 from overwrite
      // Original TTL would have expired but the overwrite extended it
      expect(cache.get('q'), same(p2));
    });
  });
}

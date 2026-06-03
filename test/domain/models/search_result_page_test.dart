import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/domain/models/search_result_page.dart';
import 'package:flutter_test/flutter_test.dart';

const _item = ReleaseSearchResult(
  id: 1,
  title: 'Kind Of Blue',
  artist: 'Miles Davis',
  format: 'Vinyl',
  label: 'Columbia',
  country: 'US',
);

void main() {
  group('SearchResultPage', () {
    test('hasMore is true when currentPage < totalPages', () {
      const page = SearchResultPage(
        items: [_item],
        currentPage: 1,
        totalPages: 3,
        totalResults: 150,
      );
      expect(page.hasMore, isTrue);
    });

    test('hasMore is false when currentPage == totalPages', () {
      const page = SearchResultPage(
        items: [_item],
        currentPage: 3,
        totalPages: 3,
        totalResults: 150,
      );
      expect(page.hasMore, isFalse);
    });

    test('hasMore is false when totalPages is 1', () {
      const page = SearchResultPage(
        items: [_item],
        currentPage: 1,
        totalPages: 1,
        totalResults: 20,
      );
      expect(page.hasMore, isFalse);
    });

    test('items list is accessible', () {
      const page = SearchResultPage(
        items: [_item],
        currentPage: 1,
        totalPages: 1,
        totalResults: 1,
      );
      expect(page.items, hasLength(1));
      expect(page.items.first, _item);
    });

    test('totalResults reflects the full count across all pages', () {
      const page = SearchResultPage(
        items: [_item],
        currentPage: 1,
        totalPages: 7,
        totalResults: 340,
      );
      expect(page.totalResults, 340);
    });
  });
}

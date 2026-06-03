import 'release_search_result.dart';

class SearchResultPage {
  const SearchResultPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalResults,
  });

  final List<ReleaseSearchResult> items;
  final int currentPage;
  final int totalPages;
  final int totalResults;

  bool get hasMore => currentPage < totalPages;
}

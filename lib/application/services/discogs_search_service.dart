import '../../domain/models/release_search_result.dart';
import '../../domain/models/search_filter.dart';
import '../../domain/models/search_result_page.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_search_result.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';

class DiscogsSearchService {
  DiscogsSearchService({TokenStorage? storage, DiscogsApiClient? apiClient})
    : _storage = storage ?? DiscogsTokenStorage(),
      _apiClient = apiClient ?? DiscogsApiClient();

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;

  /// Searches Discogs releases for [query] using the saved token.
  ///
  /// [page] is 1-based; defaults to the first page. [filter] scopes the match
  /// to a single field (US-85); defaults to [SearchFilter.all] (general query).
  /// Throws [NoTokenError] if no token is stored.
  /// Propagates [AppError] subtypes from the API client.
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
  }) async {
    final token = await _storage.loadToken();
    if (token == null) throw const NoTokenError();
    try {
      final dto = await _apiClient.searchReleases(
        query,
        token,
        page: page,
        filter: filter,
      );
      return SearchResultPage(
        items: dto.results.map(_toResult).toList(),
        currentPage: dto.currentPage,
        totalPages: dto.totalPages,
        totalResults: dto.totalResults,
      );
    } on InvalidTokenError catch (e) {
      await _storage.clearIfRevoked(e);
      rethrow;
    }
  }

  ReleaseSearchResult _toResult(DiscogsSearchResultDto dto) {
    return ReleaseSearchResult(
      id: dto.id,
      artist: dto.artist,
      title: dto.title,
      format: dto.format,
      label: dto.label,
      country: dto.country,
      year: dto.year,
      coverUrl: dto.thumbUrl,
    );
  }
}

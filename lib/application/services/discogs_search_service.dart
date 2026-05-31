import '../../domain/models/release_search_result.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_search_result.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';

class DiscogsSearchService {
  DiscogsSearchService({
    TokenStorage? storage,
    DiscogsApiClient? apiClient,
  })  : _storage = storage ?? DiscogsTokenStorage(),
        _apiClient = apiClient ?? DiscogsApiClient();

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;

  /// Searches Discogs releases for [query] using the saved token.
  /// Throws [NoTokenError] if no token is stored.
  /// Propagates [AppError] subtypes from the API client.
  Future<List<ReleaseSearchResult>> search(String query) async {
    final token = await _storage.loadToken();
    if (token == null) throw const NoTokenError();
    final dtos = await _apiClient.searchReleases(query, token);
    return dtos.map(_toResult).toList();
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

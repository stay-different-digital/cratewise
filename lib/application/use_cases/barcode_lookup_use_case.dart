import '../../domain/models/release_search_result.dart';
import '../../domain/models/search_result_page.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_search_result.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';

sealed class BarcodeLookupResult {
  const BarcodeLookupResult();
}

class BarcodeLookupSuccess extends BarcodeLookupResult {
  const BarcodeLookupSuccess(this.page);
  final SearchResultPage page;
}

class BarcodeLookupNoResults extends BarcodeLookupResult {
  const BarcodeLookupNoResults();
}

class BarcodeLookupEmptyInput extends BarcodeLookupResult {
  const BarcodeLookupEmptyInput();
}

class BarcodeLookupNoToken extends BarcodeLookupResult {
  const BarcodeLookupNoToken();
}

class BarcodeLookupRateLimited extends BarcodeLookupResult {
  const BarcodeLookupRateLimited();
}

class BarcodeLookupError extends BarcodeLookupResult {
  const BarcodeLookupError(this.error);
  final AppError error;
}

class BarcodeLookupUseCase {
  BarcodeLookupUseCase({TokenStorage? storage, DiscogsApiClient? apiClient})
    : _storage = storage ?? DiscogsTokenStorage(),
      _apiClient = apiClient ?? DiscogsApiClient();

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;

  Future<BarcodeLookupResult> execute(String barcode, {int page = 1}) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return const BarcodeLookupEmptyInput();

    try {
      final token = await _storage.loadToken();
      if (token == null) return const BarcodeLookupNoToken();

      final dto = await _apiClient.searchByBarcode(trimmed, token, page: page);
      if (dto.results.isEmpty && dto.totalResults == 0) {
        return const BarcodeLookupNoResults();
      }
      return BarcodeLookupSuccess(
        SearchResultPage(
          items: _mapResults(dto.results),
          currentPage: dto.currentPage,
          totalPages: dto.totalPages,
          totalResults: dto.totalResults,
        ),
      );
    } on RateLimitedError {
      return const BarcodeLookupRateLimited();
    } on AppError catch (e) {
      await _storage.clearIfRevoked(e);
      return BarcodeLookupError(e);
    }
  }

  List<ReleaseSearchResult> _mapResults(List<DiscogsSearchResultDto> dtos) {
    return dtos
        .map(
          (dto) => ReleaseSearchResult(
            id: dto.id,
            artist: dto.artist,
            title: dto.title,
            format: dto.format,
            label: dto.label,
            country: dto.country,
            year: dto.year,
            coverUrl: dto.thumbUrl,
          ),
        )
        .toList();
  }
}

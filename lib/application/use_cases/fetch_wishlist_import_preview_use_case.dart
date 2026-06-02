import '../../domain/models/wishlist_import_preview.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_wantlist_item.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';
import 'build_wishlist_import_preview_use_case.dart';

sealed class FetchWishlistImportPreviewResult {
  const FetchWishlistImportPreviewResult();
}

class FetchWishlistPreviewReady extends FetchWishlistImportPreviewResult {
  const FetchWishlistPreviewReady(this.preview);
  final WishlistImportPreview preview;
}

class FetchWishlistPreviewNoToken extends FetchWishlistImportPreviewResult {
  const FetchWishlistPreviewNoToken();
}

class FetchWishlistPreviewNetworkError extends FetchWishlistImportPreviewResult {
  const FetchWishlistPreviewNetworkError();
}

class FetchWishlistPreviewRateLimited extends FetchWishlistImportPreviewResult {
  const FetchWishlistPreviewRateLimited();
}

class FetchWishlistPreviewError extends FetchWishlistImportPreviewResult {
  const FetchWishlistPreviewError(this.error);
  final AppError error;
}

class FetchWishlistImportPreviewUseCase {
  FetchWishlistImportPreviewUseCase({
    required this.previewBuilder,
    TokenStorage? storage,
    DiscogsApiClient? apiClient,
  })  : _storage = storage ?? DiscogsTokenStorage(),
        _apiClient = apiClient ?? DiscogsApiClient();

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;
  final BuildWishlistImportPreviewUseCase previewBuilder;

  Future<FetchWishlistImportPreviewResult> execute() async {
    try {
      final token = await _storage.loadToken();
      if (token == null) return const FetchWishlistPreviewNoToken();
      final username = await _storage.loadUsername();
      if (username == null) return const FetchWishlistPreviewNoToken();

      final allItems = <DiscogsWantlistItemDto>[];
      var page = 1;
      var totalPages = 1;

      do {
        final dto = await _apiClient.fetchWantlistPage(
          username,
          token,
          page: page,
          perPage: 100,
        );
        allItems.addAll(dto.items);
        totalPages = dto.totalPages;
        page++;
      } while (page <= totalPages);

      final preview = await previewBuilder.execute(allItems);
      return FetchWishlistPreviewReady(preview);
    } on RateLimitedError {
      return const FetchWishlistPreviewRateLimited();
    } on NetworkError {
      return const FetchWishlistPreviewNetworkError();
    } on AppError catch (e) {
      return FetchWishlistPreviewError(e);
    }
  }
}

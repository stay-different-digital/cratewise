import '../../domain/models/wishlist_import_preview.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_wantlist_item.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';
import 'build_wishlist_import_preview_use_case.dart';

const _kRateLimitRetryDelay = Duration(seconds: 60);
const _kMaxPageRetries = 3;

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

class FetchWishlistPreviewNetworkError
    extends FetchWishlistImportPreviewResult {
  const FetchWishlistPreviewNetworkError();
}

/// All per-page retry attempts were exhausted due to repeated 429 responses.
class FetchWishlistPreviewRateLimitExhausted
    extends FetchWishlistImportPreviewResult {
  const FetchWishlistPreviewRateLimitExhausted();
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
    Future<void> Function(Duration)? delay,
    int? maxPageRetries,
  }) : _storage = storage ?? DiscogsTokenStorage(),
       _apiClient = apiClient ?? DiscogsApiClient(),
       _delay = delay ?? ((d) => Future.delayed(d)),
       _maxPageRetries = maxPageRetries ?? _kMaxPageRetries;

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;
  final Future<void> Function(Duration) _delay;
  final int _maxPageRetries;
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
        final dto = await _fetchPageWithRetry(username, token, page);
        allItems.addAll(dto.items);
        totalPages = dto.totalPages;
        page++;
      } while (page <= totalPages);

      final preview = await previewBuilder.execute(allItems);
      return FetchWishlistPreviewReady(preview);
    } on _RateLimitExhausted {
      return const FetchWishlistPreviewRateLimitExhausted();
    } on NetworkError {
      return const FetchWishlistPreviewNetworkError();
    } on AppError catch (e) {
      await _storage.clearIfRevoked(e);
      return FetchWishlistPreviewError(e);
    }
  }

  Future<DiscogsWantlistPageDto> _fetchPageWithRetry(
    String username,
    String token,
    int page,
  ) async {
    var attempts = 0;
    while (true) {
      try {
        return await _apiClient.fetchWantlistPage(
          username,
          token,
          page: page,
          perPage: 100,
        );
      } on RateLimitedError {
        if (attempts >= _maxPageRetries) throw _RateLimitExhausted();
        attempts++;
        await _delay(_kRateLimitRetryDelay);
      }
    }
  }
}

class _RateLimitExhausted implements Exception {}

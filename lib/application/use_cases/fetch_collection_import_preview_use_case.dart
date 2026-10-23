import '../../domain/models/collection_import_preview.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_collection_item.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';
import 'build_collection_import_preview_use_case.dart';

const _kRateLimitRetryDelay = Duration(seconds: 60);
const _kMaxPageRetries = 3;

sealed class FetchCollectionImportPreviewResult {
  const FetchCollectionImportPreviewResult();
}

class FetchPreviewReady extends FetchCollectionImportPreviewResult {
  const FetchPreviewReady(this.preview);
  final CollectionImportPreview preview;
}

class FetchPreviewNoToken extends FetchCollectionImportPreviewResult {
  const FetchPreviewNoToken();
}

class FetchPreviewNetworkError extends FetchCollectionImportPreviewResult {
  const FetchPreviewNetworkError();
}

/// All per-page retry attempts were exhausted due to repeated 429 responses.
class FetchPreviewRateLimitExhausted
    extends FetchCollectionImportPreviewResult {
  const FetchPreviewRateLimitExhausted();
}

class FetchPreviewError extends FetchCollectionImportPreviewResult {
  const FetchPreviewError(this.error);
  final AppError error;
}

class FetchCollectionImportPreviewUseCase {
  FetchCollectionImportPreviewUseCase({
    required this.previewBuilder,
    TokenStorage? storage,
    DiscogsApiClient? apiClient,
    Future<void> Function(Duration)? delay,
    int? maxPageRetries,
  }) : _storage = storage ?? DiscogsTokenStorage(),
       _apiClient = apiClient ?? DiscogsApiClient.shared,
       _delay = delay ?? ((d) => Future.delayed(d)),
       _maxPageRetries = maxPageRetries ?? _kMaxPageRetries;

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;
  final Future<void> Function(Duration) _delay;
  final int _maxPageRetries;
  final BuildCollectionImportPreviewUseCase previewBuilder;

  Future<FetchCollectionImportPreviewResult> execute() async {
    try {
      final token = await _storage.loadToken();
      if (token == null) return const FetchPreviewNoToken();
      final username = await _storage.loadUsername();
      if (username == null) return const FetchPreviewNoToken();

      final allItems = <DiscogsCollectionItemDto>[];
      var page = 1;
      var totalPages = 1;

      do {
        final dto = await _fetchPageWithRetry(username, token, page);
        allItems.addAll(dto.items);
        totalPages = dto.totalPages;
        page++;
      } while (page <= totalPages);

      final preview = await previewBuilder.execute(allItems);
      return FetchPreviewReady(preview);
    } on _RateLimitExhausted {
      return const FetchPreviewRateLimitExhausted();
    } on NetworkError {
      return const FetchPreviewNetworkError();
    } on AppError catch (e) {
      await _storage.clearIfRevoked(e);
      return FetchPreviewError(e);
    }
  }

  Future<DiscogsCollectionPageDto> _fetchPageWithRetry(
    String username,
    String token,
    int page,
  ) async {
    var attempts = 0;
    while (true) {
      try {
        return await _apiClient.fetchCollectionPage(
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

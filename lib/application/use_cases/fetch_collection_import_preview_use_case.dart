import '../../domain/models/collection_import_preview.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_collection_item.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';
import 'build_collection_import_preview_use_case.dart';

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

class FetchPreviewRateLimited extends FetchCollectionImportPreviewResult {
  const FetchPreviewRateLimited();
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
  })  : _storage = storage ?? DiscogsTokenStorage(),
        _apiClient = apiClient ?? DiscogsApiClient();

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;
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
        final dto = await _apiClient.fetchCollectionPage(
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
      return FetchPreviewReady(preview);
    } on RateLimitedError {
      return const FetchPreviewRateLimited();
    } on NetworkError {
      return const FetchPreviewNetworkError();
    } on AppError catch (e) {
      return FetchPreviewError(e);
    }
  }
}

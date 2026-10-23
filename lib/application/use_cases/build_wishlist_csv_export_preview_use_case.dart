import '../../domain/models/csv_wishlist_export_preview.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/csv/wishlist_csv_mapper.dart';
import '../../shared/errors/app_error.dart';

sealed class BuildWishlistCsvExportPreviewResult {
  const BuildWishlistCsvExportPreviewResult();
}

class WishlistCsvExportPreviewReady
    extends BuildWishlistCsvExportPreviewResult {
  const WishlistCsvExportPreviewReady(this.preview);
  final CsvWishlistExportPreview preview;
}

class WishlistCsvExportPreviewError
    extends BuildWishlistCsvExportPreviewResult {
  const WishlistCsvExportPreviewError();
}

class BuildWishlistCsvExportPreviewUseCase {
  const BuildWishlistCsvExportPreviewUseCase({
    required this._repository,
    this._mapper = const WishlistCsvMapper(),
  });

  final WishlistRepository _repository;
  final WishlistCsvMapper _mapper;

  Future<BuildWishlistCsvExportPreviewResult> execute() async {
    try {
      final items = await _repository.getAll();
      final sampleRows = items.take(3).map(_mapper.toRow).toList();
      return WishlistCsvExportPreviewReady(
        CsvWishlistExportPreview(
          items: items,
          headers: wishlistCsvHeaders,
          sampleRows: sampleRows,
        ),
      );
    } catch (e, st) {
      logSwallowed(e, st, 'BuildWishlistCsvExportPreviewUseCase');
      return const WishlistCsvExportPreviewError();
    }
  }
}

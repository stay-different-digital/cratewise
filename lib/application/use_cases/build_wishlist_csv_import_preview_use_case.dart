import '../../domain/models/csv_wishlist_import_preview.dart';
import '../../infrastructure/csv/csv_parser.dart';
import '../../infrastructure/csv/wishlist_csv_validator.dart';
import '../../shared/errors/app_error.dart';

sealed class BuildWishlistCsvImportPreviewResult {
  const BuildWishlistCsvImportPreviewResult();
}

class WishlistCsvImportPreviewReady
    extends BuildWishlistCsvImportPreviewResult {
  const WishlistCsvImportPreviewReady({
    required this.filename,
    required this.preview,
  });
  final String filename;
  final CsvWishlistImportPreview preview;
}

class WishlistCsvImportPreviewParseFailed
    extends BuildWishlistCsvImportPreviewResult {
  const WishlistCsvImportPreviewParseFailed(this.reason);
  final String reason;
}

class WishlistCsvImportPreviewError
    extends BuildWishlistCsvImportPreviewResult {
  const WishlistCsvImportPreviewError();
}

class BuildWishlistCsvImportPreviewUseCase {
  const BuildWishlistCsvImportPreviewUseCase({
    this.parser = const CsvParser(),
    this.validator = const WishlistCsvValidator(),
  });

  final CsvParser parser;
  final WishlistCsvValidator validator;

  BuildWishlistCsvImportPreviewResult execute({
    required String filename,
    required String content,
  }) {
    try {
      final parsed = parser.parse(content);
      return switch (parsed) {
        CsvParseSuccess() => WishlistCsvImportPreviewReady(
          filename: filename,
          preview: validator.validate(parsed),
        ),
        CsvParseFailure(:final reason) => WishlistCsvImportPreviewParseFailed(
          reason,
        ),
      };
    } catch (e, st) {
      logSwallowed(e, st, 'BuildWishlistCsvImportPreviewUseCase');
      return const WishlistCsvImportPreviewError();
    }
  }
}

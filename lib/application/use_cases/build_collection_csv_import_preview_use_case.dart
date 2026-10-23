import '../../domain/models/csv_collection_import_preview.dart';
import '../../infrastructure/csv/collection_csv_validator.dart';
import '../../infrastructure/csv/csv_parser.dart';
import '../../shared/errors/app_error.dart';

sealed class BuildCollectionCsvImportPreviewResult {
  const BuildCollectionCsvImportPreviewResult();
}

class CollectionCsvImportPreviewReady
    extends BuildCollectionCsvImportPreviewResult {
  const CollectionCsvImportPreviewReady({
    required this.filename,
    required this.preview,
  });
  final String filename;
  final CsvCollectionImportPreview preview;
}

class CollectionCsvImportPreviewParseFailed
    extends BuildCollectionCsvImportPreviewResult {
  const CollectionCsvImportPreviewParseFailed(this.reason);
  final String reason;
}

class CollectionCsvImportPreviewError
    extends BuildCollectionCsvImportPreviewResult {
  const CollectionCsvImportPreviewError();
}

class BuildCollectionCsvImportPreviewUseCase {
  const BuildCollectionCsvImportPreviewUseCase({
    this.parser = const CsvParser(),
    this.validator = const CollectionCsvValidator(),
  });

  final CsvParser parser;
  final CollectionCsvValidator validator;

  BuildCollectionCsvImportPreviewResult execute({
    required String filename,
    required String content,
  }) {
    try {
      final parsed = parser.parse(content);
      return switch (parsed) {
        CsvParseSuccess() => CollectionCsvImportPreviewReady(
          filename: filename,
          preview: validator.validate(parsed),
        ),
        CsvParseFailure(:final reason) => CollectionCsvImportPreviewParseFailed(
          reason,
        ),
      };
    } catch (e, st) {
      logSwallowed(e, st, 'BuildCollectionCsvImportPreviewUseCase');
      return const CollectionCsvImportPreviewError();
    }
  }
}

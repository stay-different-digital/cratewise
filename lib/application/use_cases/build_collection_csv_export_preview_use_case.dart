import '../../domain/models/csv_collection_export_preview.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../infrastructure/csv/collection_csv_mapper.dart';
import '../../shared/errors/app_error.dart';

sealed class BuildCollectionCsvExportPreviewResult {
  const BuildCollectionCsvExportPreviewResult();
}

class CollectionCsvExportPreviewReady
    extends BuildCollectionCsvExportPreviewResult {
  const CollectionCsvExportPreviewReady(this.preview);
  final CsvCollectionExportPreview preview;
}

class CollectionCsvExportPreviewError
    extends BuildCollectionCsvExportPreviewResult {
  const CollectionCsvExportPreviewError();
}

class BuildCollectionCsvExportPreviewUseCase {
  const BuildCollectionCsvExportPreviewUseCase({
    required this._repository,
    this._mapper = const CollectionCsvMapper(),
  });

  final CollectionRepository _repository;
  final CollectionCsvMapper _mapper;

  Future<BuildCollectionCsvExportPreviewResult> execute() async {
    try {
      final items = await _repository.getAll();
      final sampleRows = items.take(3).map(_mapper.toRow).toList();
      return CollectionCsvExportPreviewReady(
        CsvCollectionExportPreview(
          items: items,
          headers: collectionCsvHeaders,
          sampleRows: sampleRows,
        ),
      );
    } catch (e, st) {
      logSwallowed(e, st, 'BuildCollectionCsvExportPreviewUseCase');
      return const CollectionCsvExportPreviewError();
    }
  }
}

import '../../domain/models/collection_export_preview.dart';
import '../../domain/repositories/collection_repository.dart';
import 'check_collection_export_capability_use_case.dart';

sealed class BuildCollectionExportPreviewResult {
  const BuildCollectionExportPreviewResult();
}

class CollectionExportPreviewReady extends BuildCollectionExportPreviewResult {
  const CollectionExportPreviewReady(this.preview);

  final CollectionExportPreview preview;
}

/// Export to Discogs is not yet supported.
/// [reason] is a safe, user-facing message.
class CollectionExportPreviewNotSupported
    extends BuildCollectionExportPreviewResult {
  const CollectionExportPreviewNotSupported(this.reason);

  final String reason;
}

class CollectionExportPreviewError extends BuildCollectionExportPreviewResult {
  const CollectionExportPreviewError();
}

class BuildCollectionExportPreviewUseCase {
  const BuildCollectionExportPreviewUseCase({
    required this._repository,
    required this._capabilityUseCase,
  });

  final CollectionRepository _repository;
  final CheckCollectionExportCapabilityUseCase _capabilityUseCase;

  Future<BuildCollectionExportPreviewResult> execute() async {
    final capability = _capabilityUseCase.execute();
    if (capability is CollectionExportNotSupported) {
      return CollectionExportPreviewNotSupported(capability.reason);
    }

    try {
      final items = await _repository.getAll();
      final rows = items.map(classifyForExport).toList();
      return CollectionExportPreviewReady(CollectionExportPreview(rows: rows));
    } catch (_) {
      return const CollectionExportPreviewError();
    }
  }
}

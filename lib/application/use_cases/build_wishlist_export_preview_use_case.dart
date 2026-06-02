import '../../domain/models/wishlist_export_preview.dart';
import '../../domain/repositories/wishlist_repository.dart';
import 'check_wishlist_export_capability_use_case.dart';

sealed class BuildWishlistExportPreviewResult {
  const BuildWishlistExportPreviewResult();
}

class WishlistExportPreviewReady extends BuildWishlistExportPreviewResult {
  const WishlistExportPreviewReady(this.preview);

  final WishlistExportPreview preview;
}

/// Export to Discogs is not yet supported.
/// [reason] is a safe, user-facing message.
class WishlistExportPreviewNotSupported
    extends BuildWishlistExportPreviewResult {
  const WishlistExportPreviewNotSupported(this.reason);

  final String reason;
}

class WishlistExportPreviewError extends BuildWishlistExportPreviewResult {
  const WishlistExportPreviewError();
}

class BuildWishlistExportPreviewUseCase {
  const BuildWishlistExportPreviewUseCase({
    required this._repository,
    required this._capabilityUseCase,
  });

  final WishlistRepository _repository;
  final CheckWishlistExportCapabilityUseCase _capabilityUseCase;

  Future<BuildWishlistExportPreviewResult> execute() async {
    final capability = _capabilityUseCase.execute();
    if (capability is WishlistExportNotSupported) {
      return WishlistExportPreviewNotSupported(capability.reason);
    }

    try {
      final items = await _repository.getAll();
      final rows = items.map(classifyWishlistItemForExport).toList();
      return WishlistExportPreviewReady(WishlistExportPreview(rows: rows));
    } catch (_) {
      return const WishlistExportPreviewError();
    }
  }
}

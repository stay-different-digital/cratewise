import '../../domain/models/wishlist_import_preview.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/discogs/dto/discogs_wantlist_item.dart';

class BuildWishlistImportPreviewUseCase {
  const BuildWishlistImportPreviewUseCase(this._repository);

  final WishlistRepository _repository;

  Future<WishlistImportPreview> execute(
    List<DiscogsWantlistItemDto> items,
  ) async {
    final rows = <WishlistImportRow>[];
    for (final item in items) {
      rows.add(await _classify(item));
    }
    return WishlistImportPreview(rows: rows);
  }

  Future<WishlistImportRow> _classify(DiscogsWantlistItemDto item) async {
    if (item.releaseId == 0) {
      return InvalidWishlistRow(
        releaseId: 0,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        reason: 'Missing release ID',
      );
    }
    if (item.title.trim().isEmpty) {
      return InvalidWishlistRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        reason: 'Missing title',
      );
    }
    if (await _repository.containsRelease(item.releaseId)) {
      return DuplicateWishlistRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
      );
    }
    return NewWishlistRow(
      releaseId: item.releaseId,
      title: item.title,
      artist: item.artist,
      year: item.year,
      thumbUrl: item.thumbUrl,
    );
  }
}

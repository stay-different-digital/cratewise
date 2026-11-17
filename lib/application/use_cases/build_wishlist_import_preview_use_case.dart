import '../../domain/models/pending_discogs_deletion.dart';
import '../../domain/models/wishlist_import_preview.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/discogs/dto/discogs_wantlist_item.dart';

class BuildWishlistImportPreviewUseCase {
  const BuildWishlistImportPreviewUseCase(
    this._repository, {
    PendingDiscogsDeletionRepository? deletionRepository,
    // Named params can't be private, so this can't be an initializing formal.
    // ignore: prefer_initializing_formals
  }) : _deletionRepository = deletionRepository;

  final WishlistRepository _repository;
  final PendingDiscogsDeletionRepository? _deletionRepository;

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
    // A pending-deletion tombstone means the user deleted this locally and
    // asked to remove it from Discogs; re-importing would undo that (US-79).
    if (await _hasPendingDeletion(item.releaseId)) {
      return ConflictWishlistRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
      );
    }
    if (await _repository.containsRelease(item.releaseId)) {
      return DuplicateWishlistRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        dateAdded: DateTime.tryParse(item.dateAdded),
      );
    }
    return NewWishlistRow(
      releaseId: item.releaseId,
      title: item.title,
      artist: item.artist,
      year: item.year,
      thumbUrl: item.thumbUrl,
      dateAdded: DateTime.tryParse(item.dateAdded),
    );
  }

  Future<bool> _hasPendingDeletion(int releaseId) async {
    final repo = _deletionRepository;
    if (repo == null) return false;
    return repo.containsRelease(releaseId, DeletionEntityType.wishlist);
  }
}

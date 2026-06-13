import '../../domain/models/collection_import_preview.dart';
import '../../domain/models/pending_discogs_deletion.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import '../../infrastructure/discogs/dto/discogs_collection_item.dart';

class BuildCollectionImportPreviewUseCase {
  const BuildCollectionImportPreviewUseCase(
    this._repository, {
    PendingDiscogsDeletionRepository? deletionRepository,
    // Named params can't be private, so this can't be an initializing formal.
    // ignore: prefer_initializing_formals
  }) : _deletionRepository = deletionRepository;

  final CollectionRepository _repository;
  final PendingDiscogsDeletionRepository? _deletionRepository;

  Future<CollectionImportPreview> execute(
    List<DiscogsCollectionItemDto> items,
  ) async {
    final rows = <CollectionImportRow>[];
    for (final item in items) {
      rows.add(await _classify(item));
    }
    return CollectionImportPreview(rows: rows);
  }

  Future<CollectionImportRow> _classify(DiscogsCollectionItemDto item) async {
    if (item.releaseId == 0) {
      return InvalidCollectionRow(
        releaseId: 0,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        reason: 'Missing release ID',
      );
    }
    if (item.title.trim().isEmpty) {
      return InvalidCollectionRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        reason: 'Missing title',
      );
    }
    // A pending-deletion tombstone means the user deleted this locally and
    // asked to remove it from Discogs; re-importing would undo that (US-72).
    if (await _hasPendingDeletion(item.releaseId)) {
      return ConflictCollectionRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        instanceId: item.instanceId,
      );
    }
    if (await _repository.containsRelease(item.releaseId)) {
      return DuplicateCollectionRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        instanceId: item.instanceId,
      );
    }
    return NewCollectionRow(
      releaseId: item.releaseId,
      title: item.title,
      artist: item.artist,
      year: item.year,
      thumbUrl: item.thumbUrl,
      instanceId: item.instanceId,
    );
  }

  Future<bool> _hasPendingDeletion(int releaseId) async {
    final repo = _deletionRepository;
    if (repo == null) return false;
    return repo.containsRelease(releaseId, DeletionEntityType.collection);
  }
}

import '../../domain/models/collection_import_preview.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../infrastructure/discogs/dto/discogs_collection_item.dart';

class BuildCollectionImportPreviewUseCase {
  const BuildCollectionImportPreviewUseCase(this._repository);

  final CollectionRepository _repository;

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
    if (await _repository.containsRelease(item.releaseId)) {
      return DuplicateCollectionRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
      );
    }
    return NewCollectionRow(
      releaseId: item.releaseId,
      title: item.title,
      artist: item.artist,
      year: item.year,
      thumbUrl: item.thumbUrl,
    );
  }
}

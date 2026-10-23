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

  /// Matches Discogs instances to local items per instance (US-129): an
  /// instance already linked locally is a duplicate; otherwise it claims one
  /// unlinked local copy of the same release; with no copy left it is new.
  /// Local state is loaded once up front instead of queried per row.
  Future<CollectionImportPreview> execute(
    List<DiscogsCollectionItemDto> items,
  ) async {
    final local = await _repository.getAll();
    final linkedInstanceIds = {
      for (final i in local)
        if (i.discogsInstanceId != null) i.discogsInstanceId!,
    };
    final unlinkedByRelease = <int, List<String>>{};
    for (final i in local) {
      if (i.discogsInstanceId == null) {
        unlinkedByRelease.putIfAbsent(i.discogsReleaseId, () => []).add(i.id);
      }
    }
    final tombstones =
        await _deletionRepository?.getByType(DeletionEntityType.collection) ??
        const <PendingDiscogsDeletion>[];

    final rows = <CollectionImportRow>[];
    for (final item in items) {
      rows.add(
        _classify(item, linkedInstanceIds, unlinkedByRelease, tombstones),
      );
    }
    return CollectionImportPreview(rows: rows);
  }

  CollectionImportRow _classify(
    DiscogsCollectionItemDto item,
    Set<int> linkedInstanceIds,
    Map<int, List<String>> unlinkedByRelease,
    List<PendingDiscogsDeletion> tombstones,
  ) {
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
    // A tombstone with an instance id only covers that one copy.
    final deleted = tombstones.any(
      (t) =>
          t.discogsReleaseId == item.releaseId &&
          (t.discogsInstanceId == null ||
              t.discogsInstanceId == item.instanceId),
    );
    if (deleted) {
      return ConflictCollectionRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        instanceId: item.instanceId,
      );
    }
    final alreadyLinked =
        item.instanceId != 0 && linkedInstanceIds.contains(item.instanceId);
    final unlinked = unlinkedByRelease[item.releaseId];
    if (alreadyLinked || (unlinked != null && unlinked.isNotEmpty)) {
      return DuplicateCollectionRow(
        releaseId: item.releaseId,
        title: item.title,
        artist: item.artist,
        year: item.year,
        thumbUrl: item.thumbUrl,
        instanceId: item.instanceId,
        linkTargetId: alreadyLinked ? null : unlinked!.removeAt(0),
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
}

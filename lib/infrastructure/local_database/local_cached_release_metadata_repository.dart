import 'package:drift/drift.dart';

import '../../domain/models/cached_release_metadata.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import 'app_database.dart';

class LocalCachedReleaseMetadataRepository
    implements CachedReleaseMetadataRepository {
  LocalCachedReleaseMetadataRepository(this._db);

  final AppDatabase _db;

  @override
  Future<CachedReleaseMetadata?> getByReleaseId(int discogsReleaseId) async {
    final row =
        await (_db.select(_db.cachedReleases)
              ..where((t) => t.discogsReleaseId.equals(discogsReleaseId)))
            .getSingleOrNull();
    return row == null ? null : _rowToModel(row);
  }

  @override
  Future<void> save(CachedReleaseMetadata metadata) async {
    await _db
        .into(_db.cachedReleases)
        .insertOnConflictUpdate(_modelToCompanion(metadata));
  }

  @override
  Future<void> remove(int discogsReleaseId) async {
    await (_db.delete(
      _db.cachedReleases,
    )..where((t) => t.discogsReleaseId.equals(discogsReleaseId))).go();
  }

  CachedReleaseMetadata _rowToModel(CachedReleaseRow row) {
    return CachedReleaseMetadata(
      discogsReleaseId: row.discogsReleaseId,
      artist: row.artist,
      title: row.title,
      label: row.label,
      catno: row.catno,
      format: row.format,
      country: row.country,
      year: row.year,
      genres: row.genres,
      styles: row.styles,
      tracklist: row.tracklist,
      notes: row.notes,
      identifiers: row.identifiers,
      coverUrl: row.coverUrl,
      fetchedAt: row.fetchedAt,
      cacheSource: row.cacheSource,
      syncStatus: row.syncStatus,
    );
  }

  CachedReleasesCompanion _modelToCompanion(CachedReleaseMetadata m) {
    return CachedReleasesCompanion(
      discogsReleaseId: Value(m.discogsReleaseId),
      artist: Value(m.artist),
      title: Value(m.title),
      label: Value(m.label),
      catno: Value(m.catno),
      format: Value(m.format),
      country: Value(m.country),
      year: Value(m.year),
      genres: Value(m.genres),
      styles: Value(m.styles),
      tracklist: Value(m.tracklist),
      notes: Value(m.notes),
      identifiers: Value(m.identifiers),
      coverUrl: Value(m.coverUrl),
      fetchedAt: Value(m.fetchedAt),
      cacheSource: Value(m.cacheSource),
      syncStatus: Value(m.syncStatus),
    );
  }
}

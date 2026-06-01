import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_release.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';

class DiscogsReleaseDetailService {
  DiscogsReleaseDetailService({
    TokenStorage? storage,
    DiscogsApiClient? apiClient,
    this._cacheRepository,
  })  : _storage = storage ?? DiscogsTokenStorage(),
        _apiClient = apiClient ?? DiscogsApiClient();

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;
  final CachedReleaseMetadataRepository? _cacheRepository;

  /// Fetches full release details for [releaseId] using the saved token.
  /// Throws [NoTokenError] if no token is stored.
  /// Propagates [AppError] subtypes from the API client.
  Future<ReleaseDetail> fetchDetail(int releaseId) async {
    final token = await _storage.loadToken();
    if (token == null) throw const NoTokenError();
    final dto = await _apiClient.fetchRelease(releaseId, token);
    final detail = _toDetail(dto);
    await _tryCache(detail);
    return detail;
  }

  Future<void> _tryCache(ReleaseDetail detail) async {
    if (_cacheRepository == null) return;
    try {
      await _cacheRepository.save(_toCachedMetadata(detail));
    } catch (_) {
      // cache failure must not break the detail load
    }
  }

  CachedReleaseMetadata _toCachedMetadata(ReleaseDetail detail) =>
      CachedReleaseMetadata(
        discogsReleaseId: detail.id,
        artist: detail.artist,
        title: detail.title,
        label: detail.label.isEmpty ? null : detail.label,
        catno: detail.catno.isEmpty ? null : detail.catno,
        format: detail.format.isEmpty ? null : detail.format,
        country: detail.country.isEmpty ? null : detail.country,
        year: detail.year,
        genres: detail.genres,
        styles: detail.styles,
        tracklist: detail.tracklist.map((t) => t.title).toList(),
        notes: detail.notes,
        barcodes: detail.identifiers
            .where((i) => i.type.toLowerCase() == 'barcode')
            .map((i) => i.value)
            .toList(),
        coverUrl: detail.coverUrl,
        fetchedAt: DateTime.now(),
        cacheSource: 'discogs_api',
        syncStatus: SyncStatus.localOnly,
      );

  ReleaseDetail _toDetail(DiscogsReleaseDto dto) {
    return ReleaseDetail(
      id: dto.id,
      title: dto.title,
      artist: dto.artist,
      label: dto.label,
      catno: dto.catno,
      format: dto.format,
      country: dto.country,
      year: dto.year,
      genres: dto.genres,
      styles: dto.styles,
      tracklist: dto.tracklist
          .map((t) => ReleaseTrack(
                position: t.position,
                title: t.title,
                duration: t.duration,
              ))
          .toList(),
      notes: dto.notes,
      coverUrl: dto.coverUrl,
      identifiers: dto.identifiers
          .map((i) => ReleaseIdentifier(type: i.type, value: i.value))
          .toList(),
    );
  }
}

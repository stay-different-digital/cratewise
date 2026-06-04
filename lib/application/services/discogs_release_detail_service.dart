import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_release.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';
import 'cache_retry_recorder.dart';
import 'thumbnail_cache_service.dart';

class DiscogsReleaseDetailService {
  DiscogsReleaseDetailService({
    TokenStorage? storage,
    DiscogsApiClient? apiClient,
    this._cacheRepository,
    this._thumbnailCacheService,
    this._cacheRetryRecorder,
  }) : _storage = storage ?? DiscogsTokenStorage(),
       _apiClient = apiClient ?? DiscogsApiClient();

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;
  final CachedReleaseMetadataRepository? _cacheRepository;
  final ThumbnailCacheService? _thumbnailCacheService;
  final CacheRetryRecorder? _cacheRetryRecorder;

  /// Fetches full release details for [releaseId] using the saved token.
  /// Throws [NoTokenError] if no token is stored.
  /// Propagates [AppError] subtypes from the API client.
  Future<ReleaseDetail> fetchDetail(int releaseId) async {
    final token = await _storage.loadToken();
    if (token == null) throw const NoTokenError();
    try {
      final dto = await _apiClient.fetchRelease(releaseId, token);
      final detail = _toDetail(dto);
      await _tryCache(detail);
      await _tryThumbnailCache(detail.id, dto.thumbUrl ?? detail.coverUrl);
      return detail;
    } on AppError catch (e) {
      await _cacheRetryRecorder?.recordMetadataFailure(releaseId, e);
      await _storage.clearIfRevoked(e);
      rethrow;
    }
  }

  Future<void> _tryThumbnailCache(int releaseId, String? imageUrl) async {
    if (_thumbnailCacheService == null) return;
    try {
      final path = await _thumbnailCacheService.getOrFetch(releaseId, imageUrl);
      if (path == null && imageUrl != null && imageUrl.isNotEmpty) {
        await _cacheRetryRecorder?.recordThumbnailFailure(releaseId);
      }
    } catch (_) {
      // thumbnail cache failure must not break the detail load
    }
  }

  Future<void> _tryCache(ReleaseDetail detail) async {
    if (_cacheRepository == null) return;
    try {
      await _cacheRepository.save(_toCachedMetadata(detail));
    } catch (_) {
      await _cacheRetryRecorder?.recordMetadataCacheWriteFailure(detail.id);
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
        tracklist: detail.tracklist,
        notes: detail.notes,
        identifiers: detail.identifiers,
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
          .map(
            (t) => ReleaseTrack(
              position: t.position,
              title: t.title,
              duration: t.duration,
            ),
          )
          .toList(),
      notes: dto.notes,
      coverUrl: dto.coverUrl,
      identifiers: dto.identifiers
          .map((i) => ReleaseIdentifier(type: i.type, value: i.value))
          .toList(),
    );
  }
}

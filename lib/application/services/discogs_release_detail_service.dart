import '../../domain/models/release_detail.dart';
import '../../domain/repositories/token_storage.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_release.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../shared/errors/app_error.dart';

class DiscogsReleaseDetailService {
  DiscogsReleaseDetailService({
    TokenStorage? storage,
    DiscogsApiClient? apiClient,
  })  : _storage = storage ?? DiscogsTokenStorage(),
        _apiClient = apiClient ?? DiscogsApiClient();

  final TokenStorage _storage;
  final DiscogsApiClient _apiClient;

  /// Fetches full release details for [releaseId] using the saved token.
  /// Throws [NoTokenError] if no token is stored.
  /// Propagates [AppError] subtypes from the API client.
  Future<ReleaseDetail> fetchDetail(int releaseId) async {
    final token = await _storage.loadToken();
    if (token == null) throw const NoTokenError();
    final dto = await _apiClient.fetchRelease(releaseId, token);
    return _toDetail(dto);
  }

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

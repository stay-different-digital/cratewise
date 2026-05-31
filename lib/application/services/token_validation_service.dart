import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/discogs/dto/discogs_identity.dart';

class TokenValidationService {
  TokenValidationService({DiscogsApiClient? apiClient})
      : _client = apiClient ?? DiscogsApiClient();

  final DiscogsApiClient _client;

  Future<DiscogsIdentity> validateToken(String token) =>
      _client.fetchIdentity(token);
}

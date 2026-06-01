import 'package:http/http.dart' as http;

import '../../domain/repositories/thumbnail_repository.dart';

class ThumbnailCacheService {
  ThumbnailCacheService({
    required this._repository,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final ThumbnailRepository _repository;
  final http.Client _httpClient;

  Future<String?> getOrFetch(int releaseId, String? imageUrl) async {
    final cached = await _repository.getLocalPath(releaseId);
    if (cached != null) return cached;

    if (imageUrl == null || imageUrl.isEmpty) return null;

    try {
      final response = await _httpClient.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;
      await _repository.save(releaseId, response.bodyBytes);
      return await _repository.getLocalPath(releaseId);
    } catch (_) {
      return null;
    }
  }
}

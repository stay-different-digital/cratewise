import 'dart:async';

import 'package:http/http.dart' as http;

import '../../domain/repositories/thumbnail_repository.dart';
import 'thumbnail_eviction_service.dart';

class ThumbnailCacheService {
  ThumbnailCacheService({
    required ThumbnailRepository repository,
    http.Client? httpClient,
    ThumbnailEvictionService? evictionService,
  }) : _repository = repository,
       _httpClient = httpClient ?? http.Client(),
       _evictionService =
           evictionService ?? ThumbnailEvictionService(repository: repository);

  final ThumbnailRepository _repository;
  final http.Client _httpClient;
  final ThumbnailEvictionService _evictionService;

  Future<String?> getOrFetch(int releaseId, String? imageUrl) async {
    final cached = await _repository.getLocalPath(releaseId);
    if (cached != null) return cached;

    if (imageUrl == null || imageUrl.isEmpty) return null;

    try {
      final response = await _httpClient.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;
      await _repository.save(releaseId, response.bodyBytes);
      unawaited(_evictionService.evictIfNeeded());
      return await _repository.getLocalPath(releaseId);
    } catch (_) {
      return null;
    }
  }
}

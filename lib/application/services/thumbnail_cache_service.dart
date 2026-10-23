import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../domain/repositories/thumbnail_repository.dart';
import 'thumbnail_eviction_service.dart';

/// Downloads a cover image; null on network error, timeout, non-200 or a
/// non-image response (US-128). A missing content-type is accepted.
Future<Uint8List?> downloadImage(
  http.Client client,
  String url, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  try {
    final response = await client.get(Uri.parse(url)).timeout(timeout);
    final type = response.headers['content-type'];
    if (response.statusCode != 200) return null;
    if (type != null && !type.startsWith('image/')) return null;
    return response.bodyBytes;
  } on Exception {
    return null;
  }
}

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

  void close() => _httpClient.close();

  Future<String?> getOrFetch(int releaseId, String? imageUrl) async {
    final cached = await _repository.getLocalPath(releaseId);
    if (cached != null) return cached;

    if (imageUrl == null || imageUrl.isEmpty) return null;

    final bytes = await downloadImage(_httpClient, imageUrl);
    if (bytes == null) return null;
    try {
      await _repository.save(releaseId, bytes);
      unawaited(_evictionService.evictIfNeeded());
      return await _repository.getLocalPath(releaseId);
    } catch (_) {
      return null;
    }
  }
}

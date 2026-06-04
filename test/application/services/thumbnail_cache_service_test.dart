import 'dart:typed_data';

import 'package:cratewise/application/services/thumbnail_cache_service.dart';
import 'package:cratewise/application/services/thumbnail_eviction_service.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeThumbnailRepository implements ThumbnailRepository {
  final Map<int, String> _paths = {};
  final Map<int, List<int>> _bytes = {};
  bool saveThrows = false;
  int saveCallCount = 0;

  @override
  Future<String?> getLocalPath(int releaseId) async => _paths[releaseId];

  @override
  Future<void> save(int releaseId, List<int> bytes) async {
    saveCallCount++;
    if (saveThrows) throw Exception('disk full');
    _bytes[releaseId] = bytes;
    _paths[releaseId] = '/fake/thumb_$releaseId.jpg';
  }

  @override
  Future<void> remove(int releaseId) async {
    _paths.remove(releaseId);
    _bytes.remove(releaseId);
  }

  @override
  Future<bool> exists(int releaseId) async => _paths.containsKey(releaseId);
  @override
  Future<int> totalSizeBytes() async => 0;
  @override
  Future<List<ThumbnailEntry>> listEntries() async => [];
  @override
  Future<void> removeAll() async {}

  List<int>? savedBytes(int releaseId) => _bytes[releaseId];
}

class _SpyEvictionService extends ThumbnailEvictionService {
  _SpyEvictionService() : super(repository: _FakeRepo());
  int evictCallCount = 0;

  @override
  Future<void> evictIfNeeded({
    int maxBytes = kDefaultThumbnailCacheLimitBytes,
  }) async {
    evictCallCount++;
  }
}

class _FakeRepo implements ThumbnailRepository {
  @override
  Future<String?> getLocalPath(int id) async => null;
  @override
  Future<void> save(int id, List<int> bytes) async {}
  @override
  Future<void> remove(int id) async {}
  @override
  Future<bool> exists(int id) async => false;
  @override
  Future<int> totalSizeBytes() async => 0;
  @override
  Future<List<ThumbnailEntry>> listEntries() async => [];
  @override
  Future<void> removeAll() async {}
}

ThumbnailCacheService _makeService(
  _FakeThumbnailRepository repo,
  http.Client httpClient,
) => ThumbnailCacheService(repository: repo, httpClient: httpClient);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ThumbnailCacheService.getOrFetch', () {
    test('returns null when imageUrl is null', () async {
      final repo = _FakeThumbnailRepository();
      final service = _makeService(
        repo,
        MockClient((_) async => http.Response('', 200)),
      );
      expect(await service.getOrFetch(249504, null), isNull);
    });

    test('returns null when imageUrl is empty string', () async {
      final repo = _FakeThumbnailRepository();
      final service = _makeService(
        repo,
        MockClient((_) async => http.Response('', 200)),
      );
      expect(await service.getOrFetch(249504, ''), isNull);
    });

    test(
      'returns cached path without making HTTP call when already cached',
      () async {
        final repo = _FakeThumbnailRepository();
        var httpCallCount = 0;
        final client = MockClient((_) async {
          httpCallCount++;
          return http.Response('', 200);
        });
        await repo.save(249504, [1, 2, 3]);
        final service = _makeService(repo, client);
        final path = await service.getOrFetch(
          249504,
          'https://example.com/cover.jpg',
        );
        expect(path, '/fake/thumb_249504.jpg');
        expect(httpCallCount, 0);
      },
    );

    test('downloads, saves, and returns local path when not cached', () async {
      final repo = _FakeThumbnailRepository();
      final imageBytes = Uint8List.fromList([0xff, 0xd8, 0xff]);
      final service = _makeService(
        repo,
        MockClient((_) async => http.Response.bytes(imageBytes, 200)),
      );
      final path = await service.getOrFetch(
        249504,
        'https://example.com/cover.jpg',
      );
      expect(path, '/fake/thumb_249504.jpg');
      expect(repo.savedBytes(249504), imageBytes);
    });

    test('returns null when HTTP response is not 200', () async {
      final repo = _FakeThumbnailRepository();
      final service = _makeService(
        repo,
        MockClient((_) async => http.Response('Not Found', 404)),
      );
      final path = await service.getOrFetch(
        249504,
        'https://example.com/cover.jpg',
      );
      expect(path, isNull);
      expect(repo.saveCallCount, 0);
    });

    test('returns null on 403 response', () async {
      final repo = _FakeThumbnailRepository();
      final service = _makeService(
        repo,
        MockClient((_) async => http.Response('Forbidden', 403)),
      );
      expect(
        await service.getOrFetch(1, 'https://example.com/cover.jpg'),
        isNull,
      );
    });

    test('returns null when HTTP throws (network error)', () async {
      final repo = _FakeThumbnailRepository();
      final service = _makeService(
        repo,
        MockClient((_) async => throw Exception('no internet')),
      );
      final path = await service.getOrFetch(
        249504,
        'https://example.com/cover.jpg',
      );
      expect(path, isNull);
    });

    test('returns null when repository.save throws', () async {
      final repo = _FakeThumbnailRepository()..saveThrows = true;
      final imageBytes = Uint8List.fromList([0xff, 0xd8, 0xff]);
      final service = _makeService(
        repo,
        MockClient((_) async => http.Response.bytes(imageBytes, 200)),
      );
      final path = await service.getOrFetch(
        249504,
        'https://example.com/cover.jpg',
      );
      expect(path, isNull);
    });

    test('does not call save when already cached', () async {
      final repo = _FakeThumbnailRepository();
      await repo.save(249504, [1, 2, 3]);
      final countBefore = repo.saveCallCount;
      final service = _makeService(
        repo,
        MockClient(
          (_) async => http.Response.bytes(Uint8List.fromList([]), 200),
        ),
      );
      await service.getOrFetch(249504, 'https://example.com/cover.jpg');
      expect(repo.saveCallCount, countBefore);
    });

    test('passes the correct URL to the HTTP client', () async {
      final repo = _FakeThumbnailRepository();
      Uri? capturedUri;
      final service = _makeService(
        repo,
        MockClient((request) async {
          capturedUri = request.url;
          return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
        }),
      );
      await service.getOrFetch(249504, 'https://i.discogs.com/cover.jpg');
      expect(capturedUri?.toString(), 'https://i.discogs.com/cover.jpg');
    });
  });

  group('ThumbnailCacheService — eviction', () {
    test('evictIfNeeded is called after a successful download', () async {
      final repo = _FakeThumbnailRepository();
      final eviction = _SpyEvictionService();
      final service = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient(
          (_) async => http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200),
        ),
        evictionService: eviction,
      );
      await service.getOrFetch(1, 'https://example.com/cover.jpg');
      // give the unawaited future a chance to run
      await Future<void>.delayed(Duration.zero);
      expect(eviction.evictCallCount, 1);
    });

    test('evictIfNeeded is NOT called when already cached', () async {
      final repo = _FakeThumbnailRepository();
      await repo.save(249504, [1, 2, 3]);
      final eviction = _SpyEvictionService();
      final service = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient((_) async => http.Response('', 200)),
        evictionService: eviction,
      );
      await service.getOrFetch(249504, 'https://example.com/cover.jpg');
      await Future<void>.delayed(Duration.zero);
      expect(eviction.evictCallCount, 0);
    });

    test('evictIfNeeded is NOT called when HTTP fetch fails', () async {
      final repo = _FakeThumbnailRepository();
      final eviction = _SpyEvictionService();
      final service = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient((_) async => http.Response('', 500)),
        evictionService: eviction,
      );
      await service.getOrFetch(1, 'https://example.com/cover.jpg');
      await Future<void>.delayed(Duration.zero);
      expect(eviction.evictCallCount, 0);
    });
  });
}

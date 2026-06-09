import 'dart:convert';

import 'package:cratewise/application/services/cache_retry_recorder.dart';
import 'package:cratewise/application/services/discogs_release_detail_service.dart';
import 'package:cratewise/application/services/thumbnail_cache_service.dart';
import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/release_detail.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/repositories/cached_release_metadata_repository.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _SpyThumbnailRepository implements ThumbnailRepository {
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
  Future<void> remove(int releaseId) async => _paths.remove(releaseId);

  @override
  Future<bool> exists(int releaseId) async => _paths.containsKey(releaseId);
  @override
  Future<int> totalSizeBytes() async => 0;
  @override
  Future<List<ThumbnailEntry>> listEntries() async => [];
  @override
  Future<void> removeAll() async {}
}

class _SpyCacheRepository implements CachedReleaseMetadataRepository {
  final List<CachedReleaseMetadata> saved = [];
  bool shouldThrow = false;

  @override
  Future<CachedReleaseMetadata?> getByReleaseId(int id) async => null;

  @override
  Future<void> save(CachedReleaseMetadata metadata) async {
    if (shouldThrow) throw Exception('simulated DB error');
    saved.add(metadata);
  }

  @override
  Future<void> remove(int id) async {}
}

class _SpyRetryRepo implements RetryActionRepository {
  final List<RetryAction> _actions = [];

  @override
  Future<void> add(RetryAction action) async => _actions.add(action);

  @override
  Future<List<RetryAction>> getAll() async => List.unmodifiable(_actions);

  @override
  Future<RetryAction?> getById(String id) async =>
      _actions.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<RetryAction>> getPending() async =>
      _actions.where((a) => a.status == RetryActionStatus.pending).toList();

  @override
  Future<void> update(RetryAction action) async {}

  @override
  Future<void> remove(String id) async =>
      _actions.removeWhere((a) => a.id == id);

  @override
  Future<void> deleteFailedBefore(DateTime cutoff) async {}

  @override
  Future<void> deleteAll() async {}
}

class _FakeStorage implements TokenStorage {
  _FakeStorage({this.token});
  final String? token;

  @override
  Future<String?> loadToken() async => token;
  @override
  Future<String?> loadUsername() async => null;
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async {}
}

class _SpyStorage implements TokenStorage {
  _SpyStorage({this.token = 'fake_token'});
  final String? token;
  int deleteCallCount = 0;

  @override
  Future<String?> loadToken() async => token;
  @override
  Future<String?> loadUsername() async => 'testuser';
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async => deleteCallCount++;
}

DiscogsReleaseDetailService _makeService(
  String? token,
  http.Client httpClient, {
  CachedReleaseMetadataRepository? cacheRepo,
  ThumbnailCacheService? thumbnailService,
  CacheRetryRecorder? retryRecorder,
}) {
  return DiscogsReleaseDetailService(
    storage: _FakeStorage(token: token),
    apiClient: DiscogsApiClient(httpClient: httpClient),
    cacheRepository: cacheRepo,
    thumbnailCacheService: thumbnailService,
    cacheRetryRecorder: retryRecorder,
  );
}

final _kindOfBlueJson = {
  'id': 249504,
  'title': 'Kind Of Blue',
  'artists': [
    {'name': 'Miles Davis', 'id': 15885},
  ],
  'labels': [
    {'name': 'Columbia', 'catno': 'CL 1355'},
  ],
  'formats': [
    {
      'name': 'Vinyl',
      'qty': '1',
      'descriptions': ['LP', 'Album'],
    },
  ],
  'genres': ['Jazz'],
  'styles': ['Modal', 'Bop'],
  'year': 1959,
  'country': 'US',
  'notes': 'A seminal jazz album.',
  'images': [
    {'type': 'primary', 'uri': 'https://i.discogs.com/cover.jpg'},
  ],
  'tracklist': [
    {
      'position': 'A1',
      'type_': 'track',
      'title': 'So What',
      'duration': '9:22',
    },
    {
      'position': 'A2',
      'type_': 'track',
      'title': 'Freddie Freeloader',
      'duration': '9:46',
    },
  ],
  'identifiers': [
    {'type': 'Barcode', 'value': '074643602222'},
  ],
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DiscogsReleaseDetailService.fetchDetail', () {
    test('throws NoTokenError when no token is saved', () async {
      final service = _makeService(
        null,
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
      );
      expect(() => service.fetchDetail(249504), throwsA(isA<NoTokenError>()));
    });

    test(
      'returns ReleaseDetail when token is present and API succeeds',
      () async {
        final service = _makeService(
          'fake_token',
          MockClient(
            (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
          ),
        );
        final detail = await service.fetchDetail(249504);
        expect(detail, isA<ReleaseDetail>());
      },
    );

    test('maps all DTO fields to ReleaseDetail correctly', () async {
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
      );
      final detail = await service.fetchDetail(249504);
      expect(detail.id, 249504);
      expect(detail.title, 'Kind Of Blue');
      expect(detail.artist, 'Miles Davis');
      expect(detail.label, 'Columbia');
      expect(detail.catno, 'CL 1355');
      expect(detail.format, 'Vinyl, LP, Album');
      expect(detail.country, 'US');
      expect(detail.year, 1959);
      expect(detail.genres, ['Jazz']);
      expect(detail.styles, ['Modal', 'Bop']);
      expect(detail.notes, 'A seminal jazz album.');
      expect(detail.coverUrl, 'https://i.discogs.com/cover.jpg');
    });

    test('maps tracklist correctly', () async {
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
      );
      final detail = await service.fetchDetail(249504);
      expect(detail.tracklist, hasLength(2));
      expect(detail.tracklist.first, isA<ReleaseTrack>());
      expect(detail.tracklist.first.position, 'A1');
      expect(detail.tracklist.first.title, 'So What');
      expect(detail.tracklist.first.duration, '9:22');
    });

    test('maps identifiers correctly', () async {
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
      );
      final detail = await service.fetchDetail(249504);
      expect(detail.identifiers, hasLength(1));
      expect(detail.identifiers.first, isA<ReleaseIdentifier>());
      expect(detail.identifiers.first.type, 'Barcode');
      expect(detail.identifiers.first.value, '074643602222');
    });

    test('propagates RateLimitedError from API client', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response('', 429)),
      );
      expect(() => service.fetchDetail(1), throwsA(isA<RateLimitedError>()));
    });

    test('propagates InvalidTokenError from API client', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response('', 401)),
      );
      expect(() => service.fetchDetail(1), throwsA(isA<InvalidTokenError>()));
    });

    test('propagates NetworkError from API client', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => throw Exception('no internet')),
      );
      expect(() => service.fetchDetail(1), throwsA(isA<NetworkError>()));
    });

    test('token is not present in thrown errors', () async {
      const sensitiveToken = 'super_secret_xyz';
      final service = _makeService(
        sensitiveToken,
        MockClient((_) async => http.Response('', 401)),
      );
      try {
        await service.fetchDetail(1);
        fail('expected InvalidTokenError');
      } on InvalidTokenError catch (e) {
        expect(e.toString(), isNot(contains(sensitiveToken)));
      }
    });
  });

  group('DiscogsReleaseDetailService — caching', () {
    test('saves metadata to cache after successful fetch', () async {
      final cache = _SpyCacheRepository();
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
        cacheRepo: cache,
      );
      await service.fetchDetail(249504);
      expect(cache.saved, hasLength(1));
      expect(cache.saved.first.discogsReleaseId, 249504);
      expect(cache.saved.first.title, 'Kind Of Blue');
      expect(cache.saved.first.artist, 'Miles Davis');
    });

    test('cached metadata maps fields from ReleaseDetail correctly', () async {
      final cache = _SpyCacheRepository();
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
        cacheRepo: cache,
      );
      await service.fetchDetail(249504);
      final meta = cache.saved.first;
      expect(meta.label, 'Columbia');
      expect(meta.catno, 'CL 1355');
      expect(meta.country, 'US');
      expect(meta.year, 1959);
      expect(meta.genres, ['Jazz']);
      expect(meta.styles, ['Modal', 'Bop']);
      expect(meta.identifiers, hasLength(1));
      expect(meta.identifiers.first.type, 'Barcode');
      expect(meta.identifiers.first.value, '074643602222');
      expect(meta.cacheSource, 'discogs_api');
    });

    test(
      'cached metadata saves full tracklist with position and duration',
      () async {
        final cache = _SpyCacheRepository();
        final service = _makeService(
          'fake_token',
          MockClient(
            (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
          ),
          cacheRepo: cache,
        );
        await service.fetchDetail(249504);
        final meta = cache.saved.first;
        expect(meta.tracklist, hasLength(2));
        expect(meta.tracklist.first.position, 'A1');
        expect(meta.tracklist.first.title, 'So What');
        expect(meta.tracklist.first.duration, '9:22');
      },
    );

    test(
      'cache save failure does not prevent returning ReleaseDetail',
      () async {
        final cache = _SpyCacheRepository()..shouldThrow = true;
        final service = _makeService(
          'fake_token',
          MockClient(
            (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
          ),
          cacheRepo: cache,
        );
        final detail = await service.fetchDetail(249504);
        expect(detail.title, 'Kind Of Blue');
      },
    );

    test('does not save to cache when API returns an error', () async {
      final cache = _SpyCacheRepository();
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response('', 429)),
        cacheRepo: cache,
      );
      await expectLater(
        () => service.fetchDetail(1),
        throwsA(isA<RateLimitedError>()),
      );
      expect(cache.saved, isEmpty);
    });

    test('cached metadata does not contain the token', () async {
      const sensitiveToken = 'super_secret_token_xyz';
      final cache = _SpyCacheRepository();
      final service = _makeService(
        sensitiveToken,
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
        cacheRepo: cache,
      );
      await service.fetchDetail(249504);
      final meta = cache.saved.first;
      expect(meta.artist, isNot(contains(sensitiveToken)));
      expect(meta.title, isNot(contains(sensitiveToken)));
      expect(meta.cacheSource, isNot(contains(sensitiveToken)));
    });

    test('works correctly without a cache repository', () async {
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
      );
      final detail = await service.fetchDetail(249504);
      expect(detail.title, 'Kind Of Blue');
    });
  });

  group('DiscogsReleaseDetailService — thumbnail caching', () {
    test('thumbnail is fetched after successful detail load', () async {
      final repo = _SpyThumbnailRepository();
      final thumbService = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient(
          (_) async => http.Response.bytes([0xff, 0xd8], 200),
        ),
      );
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
        thumbnailService: thumbService,
      );
      await service.fetchDetail(249504);
      expect(repo.saveCallCount, 1);
    });

    test(
      'thumbnail save failure does not prevent returning ReleaseDetail',
      () async {
        final repo = _SpyThumbnailRepository()..saveThrows = true;
        final thumbService = ThumbnailCacheService(
          repository: repo,
          httpClient: MockClient(
            (_) async => http.Response.bytes([0xff, 0xd8], 200),
          ),
        );
        final service = _makeService(
          'fake_token',
          MockClient(
            (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
          ),
          thumbnailService: thumbService,
        );
        final detail = await service.fetchDetail(249504);
        expect(detail.title, 'Kind Of Blue');
      },
    );

    test('thumbnail not fetched when API returns error', () async {
      final repo = _SpyThumbnailRepository();
      final thumbService = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient((_) async => http.Response('', 200)),
      );
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response('', 429)),
        thumbnailService: thumbService,
      );
      await expectLater(
        () => service.fetchDetail(1),
        throwsA(isA<RateLimitedError>()),
      );
      expect(repo.saveCallCount, 0);
    });

    test('missing coverUrl is handled safely', () async {
      final noCoverJson = Map<String, dynamic>.from(_kindOfBlueJson)
        ..remove('images');
      final repo = _SpyThumbnailRepository();
      final thumbService = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient((_) async => http.Response('', 200)),
      );
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(jsonEncode(noCoverJson), 200)),
        thumbnailService: thumbService,
      );
      final detail = await service.fetchDetail(249504);
      expect(detail.title, 'Kind Of Blue');
      expect(repo.saveCallCount, 0);
    });

    test('works correctly without a thumbnail service', () async {
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
      );
      final detail = await service.fetchDetail(249504);
      expect(detail.title, 'Kind Of Blue');
    });
  });

  group('DiscogsReleaseDetailService — thumbnail URL selection', () {
    test('uses uri150 URL for thumbnail cache when available', () async {
      String? capturedUrl;
      final repo = _SpyThumbnailRepository();
      final thumbService = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response.bytes([0xff, 0xd8], 200);
        }),
      );
      final withUri150 = {
        ..._kindOfBlueJson,
        'images': [
          {
            'type': 'primary',
            'uri': 'https://i.discogs.com/cover.jpg',
            'uri150': 'https://i.discogs.com/thumb150.jpg',
          },
        ],
      };
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(jsonEncode(withUri150), 200)),
        thumbnailService: thumbService,
      );
      await service.fetchDetail(249504);
      expect(capturedUrl, 'https://i.discogs.com/thumb150.jpg');
    });

    test('falls back to uri when uri150 is absent', () async {
      String? capturedUrl;
      final repo = _SpyThumbnailRepository();
      final thumbService = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response.bytes([0xff, 0xd8], 200);
        }),
      );
      final noUri150 = {
        ..._kindOfBlueJson,
        'images': [
          {'type': 'primary', 'uri': 'https://i.discogs.com/cover.jpg'},
        ],
      };
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(jsonEncode(noUri150), 200)),
        thumbnailService: thumbService,
      );
      await service.fetchDetail(249504);
      expect(capturedUrl, 'https://i.discogs.com/cover.jpg');
    });
  });

  group('DiscogsReleaseDetailService — retry recording', () {
    test(
      'records metadata retry action when API throws NetworkError',
      () async {
        final retryRepo = _SpyRetryRepo();
        final service = _makeService(
          'fake_token',
          MockClient((_) async => throw Exception('no internet')),
          retryRecorder: CacheRetryRecorder(retryRepo),
        );
        await expectLater(
          () => service.fetchDetail(249504),
          throwsA(isA<NetworkError>()),
        );
        expect(retryRepo._actions, hasLength(1));
        expect(
          retryRepo._actions.first.actionType,
          RetryActionType.refreshReleaseMetadata,
        );
        expect(retryRepo._actions.first.entityId, '249504');
      },
    );

    test(
      'records metadata retry action when API throws RateLimitedError',
      () async {
        final retryRepo = _SpyRetryRepo();
        final service = _makeService(
          'fake_token',
          MockClient((_) async => http.Response('', 429)),
          retryRecorder: CacheRetryRecorder(retryRepo),
        );
        await expectLater(
          () => service.fetchDetail(1),
          throwsA(isA<RateLimitedError>()),
        );
        expect(retryRepo._actions, hasLength(1));
        expect(
          retryRepo._actions.first.actionType,
          RetryActionType.refreshReleaseMetadata,
        );
      },
    );

    test(
      'does not record retry action when API throws InvalidTokenError',
      () async {
        final retryRepo = _SpyRetryRepo();
        final service = _makeService(
          'fake_token',
          MockClient((_) async => http.Response('', 401)),
          retryRecorder: CacheRetryRecorder(retryRepo),
        );
        await expectLater(
          () => service.fetchDetail(1),
          throwsA(isA<InvalidTokenError>()),
        );
        expect(retryRepo._actions, isEmpty);
      },
    );

    test('still throws original error after recording retry action', () async {
      final retryRepo = _SpyRetryRepo();
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response('', 429)),
        retryRecorder: CacheRetryRecorder(retryRepo),
      );
      expect(() => service.fetchDetail(1), throwsA(isA<RateLimitedError>()));
    });

    test(
      'does not record retry action when no retry recorder is set',
      () async {
        final service = _makeService(
          'fake_token',
          MockClient((_) async => throw Exception('no internet')),
        );
        await expectLater(
          () => service.fetchDetail(1),
          throwsA(isA<NetworkError>()),
        );
      },
    );

    test(
      'records thumbnail retry action when thumbnail fetch returns null',
      () async {
        final retryRepo = _SpyRetryRepo();
        final repo = _SpyThumbnailRepository();
        final thumbService = ThumbnailCacheService(
          repository: repo,
          httpClient: MockClient((_) async => http.Response('Not Found', 404)),
        );
        final service = _makeService(
          'fake_token',
          MockClient(
            (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
          ),
          thumbnailService: thumbService,
          retryRecorder: CacheRetryRecorder(retryRepo),
        );
        await service.fetchDetail(249504);
        expect(
          retryRepo._actions.where(
            (a) => a.actionType == RetryActionType.cacheThumbnail,
          ),
          hasLength(1),
        );
        expect(retryRepo._actions.first.entityId, '249504');
      },
    );

    test('records metadata retry action when cache write fails', () async {
      final retryRepo = _SpyRetryRepo();
      final cache = _SpyCacheRepository()..shouldThrow = true;
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
        cacheRepo: cache,
        retryRecorder: CacheRetryRecorder(retryRepo),
      );
      await service.fetchDetail(249504);
      expect(
        retryRepo._actions.where(
          (a) => a.actionType == RetryActionType.refreshReleaseMetadata,
        ),
        hasLength(1),
      );
      expect(retryRepo._actions.first.entityId, '249504');
    });

    test('records thumbnail retry action when thumbnail save fails', () async {
      final retryRepo = _SpyRetryRepo();
      final repo = _SpyThumbnailRepository()..saveThrows = true;
      final thumbService = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient(
          (_) async => http.Response.bytes([0xff, 0xd8], 200),
        ),
      );
      final service = _makeService(
        'fake_token',
        MockClient(
          (_) async => http.Response(jsonEncode(_kindOfBlueJson), 200),
        ),
        thumbnailService: thumbService,
        retryRecorder: CacheRetryRecorder(retryRepo),
      );
      await service.fetchDetail(249504);
      expect(
        retryRepo._actions.where(
          (a) => a.actionType == RetryActionType.cacheThumbnail,
        ),
        hasLength(1),
      );
      expect(retryRepo._actions.first.entityId, '249504');
    });

    test('does not record thumbnail retry when cover URL is absent', () async {
      final noCoverJson = Map<String, dynamic>.from(_kindOfBlueJson)
        ..remove('images');
      final retryRepo = _SpyRetryRepo();
      final repo = _SpyThumbnailRepository();
      final thumbService = ThumbnailCacheService(
        repository: repo,
        httpClient: MockClient((_) async => http.Response('', 200)),
      );
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(jsonEncode(noCoverJson), 200)),
        thumbnailService: thumbService,
        retryRecorder: CacheRetryRecorder(retryRepo),
      );
      await service.fetchDetail(249504);
      expect(
        retryRepo._actions.where(
          (a) => a.actionType == RetryActionType.cacheThumbnail,
        ),
        isEmpty,
      );
    });

    test('recorded retry action does not contain token', () async {
      const sensitiveToken = 'secret_token_xyz';
      final retryRepo = _SpyRetryRepo();
      final service = _makeService(
        sensitiveToken,
        MockClient((_) async => throw Exception('no internet')),
        retryRecorder: CacheRetryRecorder(retryRepo),
      );
      await expectLater(
        () => service.fetchDetail(1),
        throwsA(isA<NetworkError>()),
      );
      expect(retryRepo._actions, hasLength(1));
      final action = retryRepo._actions.first;
      expect(action.safeErrorMessage, isNot(contains(sensitiveToken)));
      expect(action.entityId, isNot(contains(sensitiveToken)));
    });
  });

  group('DiscogsReleaseDetailService revoked token', () {
    test('clears credentials when API returns 401', () async {
      final spy = _SpyStorage(token: 'fake_token');
      final service = DiscogsReleaseDetailService(
        storage: spy,
        apiClient: DiscogsApiClient(
          httpClient: MockClient((_) async => http.Response('', 401)),
        ),
      );
      await expectLater(
        () => service.fetchDetail(249504),
        throwsA(isA<InvalidTokenError>()),
      );
      expect(spy.deleteCallCount, 1);
    });

    test('does not clear credentials on non-401 error', () async {
      final spy = _SpyStorage(token: 'fake_token');
      final service = DiscogsReleaseDetailService(
        storage: spy,
        apiClient: DiscogsApiClient(
          httpClient: MockClient((_) async => throw Exception('network error')),
        ),
      );
      await expectLater(
        () => service.fetchDetail(249504),
        throwsA(isA<NetworkError>()),
      );
      expect(spy.deleteCallCount, 0);
    });
  });
}

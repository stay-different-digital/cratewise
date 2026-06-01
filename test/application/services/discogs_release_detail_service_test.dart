import 'dart:convert';

import 'package:cratewise/application/services/discogs_release_detail_service.dart';
import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/release_detail.dart';
import 'package:cratewise/domain/repositories/cached_release_metadata_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

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

DiscogsReleaseDetailService _makeService(
  String? token,
  http.Client httpClient, {
  CachedReleaseMetadataRepository? cacheRepo,
}) {
  return DiscogsReleaseDetailService(
    storage: _FakeStorage(token: token),
    apiClient: DiscogsApiClient(httpClient: httpClient),
    cacheRepository: cacheRepo,
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
    {
      'type': 'primary',
      'uri': 'https://i.discogs.com/cover.jpg',
    },
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
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
      );
      expect(
        () => service.fetchDetail(249504),
        throwsA(isA<NoTokenError>()),
      );
    });

    test('returns ReleaseDetail when token is present and API succeeds',
        () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
      );
      final detail = await service.fetchDetail(249504);
      expect(detail, isA<ReleaseDetail>());
    });

    test('maps all DTO fields to ReleaseDetail correctly', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
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
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
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
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
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
      expect(
        () => service.fetchDetail(1),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('propagates InvalidTokenError from API client', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response('', 401)),
      );
      expect(
        () => service.fetchDetail(1),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('propagates NetworkError from API client', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => service.fetchDetail(1),
        throwsA(isA<NetworkError>()),
      );
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
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
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
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
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
      expect(meta.barcodes, ['074643602222']);
      expect(meta.cacheSource, 'discogs_api');
    });

    test('cache save failure does not prevent returning ReleaseDetail', () async {
      final cache = _SpyCacheRepository()..shouldThrow = true;
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
        cacheRepo: cache,
      );
      final detail = await service.fetchDetail(249504);
      expect(detail.title, 'Kind Of Blue');
    });

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
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
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
        MockClient((_) async => http.Response(jsonEncode(_kindOfBlueJson), 200)),
      );
      final detail = await service.fetchDetail(249504);
      expect(detail.title, 'Kind Of Blue');
    });
  });
}

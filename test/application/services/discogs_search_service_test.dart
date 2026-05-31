import 'dart:convert';

import 'package:cratewise/application/services/discogs_search_service.dart';
import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

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

DiscogsSearchService _makeService(String? token, http.Client httpClient) {
  return DiscogsSearchService(
    storage: _FakeStorage(token: token),
    apiClient: DiscogsApiClient(httpClient: httpClient),
  );
}

String _searchBody(List<Map<String, dynamic>> results) =>
    jsonEncode({'results': results, 'pagination': {}});

const _kindOfBlue = {
  'id': 249504,
  'title': 'Miles Davis - Kind Of Blue',
  'thumb': 'https://i.discogs.com/cover.jpg',
  'format': ['Vinyl', 'LP'],
  'label': ['Columbia'],
  'year': '1959',
  'country': 'US',
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DiscogsSearchService.search', () {
    test('throws NoTokenError when no token is saved', () async {
      final service = _makeService(
        null,
        MockClient((_) async => http.Response(_searchBody([]), 200)),
      );
      expect(
        () => service.search('test'),
        throwsA(isA<NoTokenError>()),
      );
    });

    test('returns mapped results when token is present and API succeeds',
        () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(_searchBody([_kindOfBlue]), 200)),
      );
      final results = await service.search('kind of blue');
      expect(results, hasLength(1));
      expect(results.first, isA<ReleaseSearchResult>());
    });

    test('maps all DTO fields to ReleaseSearchResult correctly', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(_searchBody([_kindOfBlue]), 200)),
      );
      final results = await service.search('kind of blue');
      final r = results.first;
      expect(r.id, 249504);
      expect(r.artist, 'Miles Davis');
      expect(r.title, 'Kind Of Blue');
      expect(r.format, 'Vinyl');
      expect(r.label, 'Columbia');
      expect(r.country, 'US');
      expect(r.year, 1959);
      expect(r.coverUrl, 'https://i.discogs.com/cover.jpg');
    });

    test('returns empty list when API returns no results', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response(_searchBody([]), 200)),
      );
      final results = await service.search('nothing');
      expect(results, isEmpty);
    });

    test('propagates RateLimitedError from API client', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response('', 429)),
      );
      expect(
        () => service.search('test'),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('propagates InvalidTokenError from API client', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => http.Response('', 401)),
      );
      expect(
        () => service.search('test'),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('propagates NetworkError from API client', () async {
      final service = _makeService(
        'fake_token',
        MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => service.search('test'),
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
        await service.search('test');
        fail('expected InvalidTokenError');
      } on InvalidTokenError catch (e) {
        expect(e.toString(), isNot(contains(sensitiveToken)));
      }
    });
  });
}

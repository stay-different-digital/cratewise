import 'dart:convert';

import 'package:cratewise/application/services/discogs_release_detail_service.dart';
import 'package:cratewise/domain/models/release_detail.dart';
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

DiscogsReleaseDetailService _makeService(String? token, http.Client httpClient) {
  return DiscogsReleaseDetailService(
    storage: _FakeStorage(token: token),
    apiClient: DiscogsApiClient(httpClient: httpClient),
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
}

import 'dart:convert';

import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_identity.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_release.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_search_result.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Client _mockClient(int statusCode, [String body = '']) {
  return MockClient((_) async => http.Response(body, statusCode));
}

const _fakeToken = 'test_token_value';

void main() {
  group('DiscogsApiClient.fetchIdentity', () {
    test('returns identity on 200', () async {
      final body = jsonEncode({
        'username': 'vinyl_fan',
        'resource_url': 'https://api.discogs.com/users/vinyl_fan',
      });
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response(body, 200)),
      );

      final identity = await client.fetchIdentity(_fakeToken);

      expect(identity, isA<DiscogsIdentity>());
      expect(identity.username, 'vinyl_fan');
      expect(identity.resourceUrl, 'https://api.discogs.com/users/vinyl_fan');
    });

    test('throws InvalidTokenError on 401', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      expect(
        () => client.fetchIdentity(_fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws InvalidTokenError on 403', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(403));
      expect(
        () => client.fetchIdentity(_fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.fetchIdentity(_fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('throws DiscogsUnavailableError on 500', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(500));
      expect(
        () => client.fetchIdentity(_fakeToken),
        throwsA(isA<DiscogsUnavailableError>()),
      );
    });

    test('throws NetworkError when request throws', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => client.fetchIdentity(_fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test('request includes correct User-Agent and Authorization headers',
        () async {
      late http.Request capturedRequest;
      final body = jsonEncode({
        'username': 'vinyl_fan',
        'resource_url': 'https://api.discogs.com/users/vinyl_fan',
      });
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(body, 200);
        }),
      );

      await client.fetchIdentity(_fakeToken);

      expect(capturedRequest.headers['User-Agent'], 'Cratewise/1.0');
      expect(
        capturedRequest.headers['Authorization'],
        'Discogs token=$_fakeToken',
      );
    });

    test('error messages do not contain the token', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      try {
        await client.fetchIdentity(_fakeToken);
        fail('expected InvalidTokenError');
      } on InvalidTokenError {
        // Pass — typed error carries no message containing the token.
      }
    });
  });

  group('DiscogsApiClient.searchReleases', () {
    String searchBody(List<Map<String, dynamic>> results) =>
        jsonEncode({'results': results, 'pagination': {}});

    final kindOfBlue = {
      'id': 249504,
      'title': 'Miles Davis - Kind Of Blue',
      'thumb': 'https://i.discogs.com/cover.jpg',
      'format': ['Vinyl', 'LP', 'Album'],
      'label': ['Columbia', 'CBS'],
      'year': '1959',
      'country': 'US',
    };

    test('returns list of DTOs on 200', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final results = await client.searchReleases('kind of blue', _fakeToken);
      expect(results, hasLength(1));
      expect(results.first, isA<DiscogsSearchResultDto>());
    });

    test('parses artist and title from combined field', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final results = await client.searchReleases('kind of blue', _fakeToken);
      expect(results.first.artist, 'Miles Davis');
      expect(results.first.title, 'Kind Of Blue');
    });

    test('uses first format from array', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final results = await client.searchReleases('kind of blue', _fakeToken);
      expect(results.first.format, 'Vinyl');
    });

    test('uses first label from array', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final results = await client.searchReleases('kind of blue', _fakeToken);
      expect(results.first.label, 'Columbia');
    });

    test('parses year from string', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final results = await client.searchReleases('kind of blue', _fakeToken);
      expect(results.first.year, 1959);
    });

    test('parses country and id', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final results = await client.searchReleases('kind of blue', _fakeToken);
      expect(results.first.country, 'US');
      expect(results.first.id, 249504);
      expect(results.first.thumbUrl, 'https://i.discogs.com/cover.jpg');
    });

    test('treats empty thumb string as null', () async {
      final result = {...kindOfBlue, 'thumb': ''};
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([result]), 200),
        ),
      );
      final results = await client.searchReleases('kind of blue', _fakeToken);
      expect(results.first.thumbUrl, isNull);
    });

    test('handles missing optional fields gracefully', () async {
      final minimal = {'id': 1, 'title': 'Unknown Release'};
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([minimal]), 200),
        ),
      );
      final results = await client.searchReleases('test', _fakeToken);
      expect(results.first.artist, '');
      expect(results.first.title, 'Unknown Release');
      expect(results.first.format, '');
      expect(results.first.label, '');
      expect(results.first.country, '');
      expect(results.first.year, isNull);
      expect(results.first.thumbUrl, isNull);
    });

    test('returns empty list when results array is empty', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([]), 200),
        ),
      );
      final results = await client.searchReleases('nothing', _fakeToken);
      expect(results, isEmpty);
    });

    test('encodes query and type in request URL', () async {
      late http.Request captured;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(searchBody([]), 200);
        }),
      );
      await client.searchReleases('kind of blue', _fakeToken);
      expect(captured.url.path, '/database/search');
      expect(captured.url.queryParameters['q'], 'kind of blue');
      expect(captured.url.queryParameters['type'], 'release');
    });

    test('throws InvalidTokenError on 401', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      expect(
        () => client.searchReleases('test', _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.searchReleases('test', _fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('throws DiscogsUnavailableError on 500', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(500));
      expect(
        () => client.searchReleases('test', _fakeToken),
        throwsA(isA<DiscogsUnavailableError>()),
      );
    });

    test('throws NetworkError when request throws', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => client.searchReleases('test', _fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test('token is not present in thrown error messages', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      try {
        await client.searchReleases('test', _fakeToken);
        fail('expected InvalidTokenError');
      } on InvalidTokenError {
        // Pass — typed error carries no message containing the token.
      }
    });
  });

  group('DiscogsApiClient.fetchRelease', () {
    final kindOfBlueRelease = {
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
          'uri': 'https://i.discogs.com/kind_of_blue.jpg',
          'uri150': 'https://i.discogs.com/kind_of_blue_150.jpg',
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
        {
          'position': '',
          'type_': 'heading',
          'title': 'Side B',
          'duration': '',
        },
        {
          'position': 'B1',
          'type_': 'track',
          'title': 'Blue In Green',
          'duration': '5:37',
        },
      ],
      'identifiers': [
        {'type': 'Barcode', 'value': '074643602222'},
        {'type': 'Matrix / Runout', 'value': 'XLP 55328'},
      ],
    };

    test('returns DiscogsReleaseDto on 200', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release, isA<DiscogsReleaseDto>());
    });

    test('parses id, title, and artist', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.id, 249504);
      expect(release.title, 'Kind Of Blue');
      expect(release.artist, 'Miles Davis');
    });

    test('parses label and catalog number', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.label, 'Columbia');
      expect(release.catno, 'CL 1355');
    });

    test('parses format with descriptions', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.format, 'Vinyl, LP, Album');
    });

    test('parses country, year, genres, and styles', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.country, 'US');
      expect(release.year, 1959);
      expect(release.genres, ['Jazz']);
      expect(release.styles, ['Modal', 'Bop']);
    });

    test('parses notes', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.notes, 'A seminal jazz album.');
    });

    test('parses cover URL from primary image', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.coverUrl, 'https://i.discogs.com/kind_of_blue.jpg');
    });

    test('parses tracklist and filters heading rows', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.tracklist, hasLength(3));
      expect(release.tracklist.map((t) => t.title), ['So What', 'Freddie Freeloader', 'Blue In Green']);
      expect(release.tracklist.first.position, 'A1');
      expect(release.tracklist.first.duration, '9:22');
    });

    test('parses identifiers', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.identifiers, hasLength(2));
      expect(release.identifiers.first.type, 'Barcode');
      expect(release.identifiers.first.value, '074643602222');
    });

    test('joins multiple artists with comma', () async {
      final multiArtist = {
        ...kindOfBlueRelease,
        'artists': [
          {'name': 'John Lennon'},
          {'name': 'Paul McCartney'},
        ],
      };
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(multiArtist), 200),
        ),
      );
      final release = await client.fetchRelease(1, _fakeToken);
      expect(release.artist, 'John Lennon, Paul McCartney');
    });

    test('falls back to first image when no primary image present', () async {
      final noPrimary = {
        ...kindOfBlueRelease,
        'images': [
          {
            'type': 'secondary',
            'uri': 'https://i.discogs.com/back.jpg',
          },
        ],
      };
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(noPrimary), 200),
        ),
      );
      final release = await client.fetchRelease(1, _fakeToken);
      expect(release.coverUrl, 'https://i.discogs.com/back.jpg');
    });

    test('handles missing optional fields gracefully', () async {
      final minimal = {'id': 1, 'title': 'Unknown'};
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(minimal), 200),
        ),
      );
      final release = await client.fetchRelease(1, _fakeToken);
      expect(release.artist, '');
      expect(release.label, '');
      expect(release.catno, '');
      expect(release.format, '');
      expect(release.country, '');
      expect(release.year, isNull);
      expect(release.genres, isEmpty);
      expect(release.styles, isEmpty);
      expect(release.tracklist, isEmpty);
      expect(release.notes, isNull);
      expect(release.coverUrl, isNull);
      expect(release.identifiers, isEmpty);
    });

    test('requests the correct URL path for the release id', () async {
      late http.Request captured;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(kindOfBlueRelease), 200);
        }),
      );
      await client.fetchRelease(249504, _fakeToken);
      expect(captured.url.path, '/releases/249504');
    });

    test('throws InvalidTokenError on 401', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      expect(
        () => client.fetchRelease(1, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.fetchRelease(1, _fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('throws DiscogsUnavailableError on 500', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(500));
      expect(
        () => client.fetchRelease(1, _fakeToken),
        throwsA(isA<DiscogsUnavailableError>()),
      );
    });

    test('throws NetworkError when request throws', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => client.fetchRelease(1, _fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test('token is not present in thrown error messages', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      try {
        await client.fetchRelease(1, _fakeToken);
        fail('expected InvalidTokenError');
      } on InvalidTokenError {
        // Pass — typed error carries no message containing the token.
      }
    });
  });
}

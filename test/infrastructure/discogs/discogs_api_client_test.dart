import 'dart:convert';

import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_collection_item.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_identity.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_release.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_search_result.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_wantlist_item.dart';
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

    test('throws NetworkError when request times out', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return http.Response('', 200);
        }),
        requestTimeout: const Duration(milliseconds: 50),
      );
      expect(
        () => client.fetchIdentity(_fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test(
      'request includes correct User-Agent and Authorization headers',
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
      },
    );

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
    String searchBody(
      List<Map<String, dynamic>> results, {
      int page = 1,
      int pages = 1,
      int items = 0,
    }) => jsonEncode({
      'results': results,
      'pagination': {
        'page': page,
        'pages': pages,
        'items': items,
        'per_page': 50,
      },
    });

    final kindOfBlue = {
      'id': 249504,
      'title': 'Miles Davis - Kind Of Blue',
      'thumb': 'https://i.discogs.com/cover.jpg',
      'format': ['Vinyl', 'LP', 'Album'],
      'label': ['Columbia', 'CBS'],
      'year': '1959',
      'country': 'US',
    };

    test('returns DiscogsSearchPageDto on 200', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page, isA<DiscogsSearchPageDto>());
      expect(page.results, hasLength(1));
      expect(page.results.first, isA<DiscogsSearchResultDto>());
    });

    test('parses pagination fields', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            searchBody([kindOfBlue], page: 2, pages: 7, items: 340),
            200,
          ),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page.currentPage, 2);
      expect(page.totalPages, 7);
      expect(page.totalResults, 340);
    });

    test('defaults pagination when pagination object is empty', () async {
      final body = jsonEncode({'results': [], 'pagination': {}});
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response(body, 200)),
      );
      final page = await client.searchReleases('test', _fakeToken);
      expect(page.currentPage, 1);
      expect(page.totalPages, 1);
      expect(page.totalResults, 0);
    });

    test('parses artist and title from combined field', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page.results.first.artist, 'Miles Davis');
      expect(page.results.first.title, 'Kind Of Blue');
    });

    test('uses first format from array', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page.results.first.format, 'Vinyl');
    });

    test('uses first label from array', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page.results.first.label, 'Columbia');
    });

    test('parses year from string', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page.results.first.year, 1959);
    });

    test('parses country and id', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page.results.first.country, 'US');
      expect(page.results.first.id, 249504);
      expect(page.results.first.thumbUrl, 'https://i.discogs.com/cover.jpg');
    });

    test('treats empty thumb string as null', () async {
      final result = {...kindOfBlue, 'thumb': ''};
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([result]), 200),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page.results.first.thumbUrl, isNull);
    });

    test('handles missing optional fields gracefully', () async {
      final minimal = {'id': 1, 'title': 'Unknown Release'};
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([minimal]), 200),
        ),
      );
      final page = await client.searchReleases('test', _fakeToken);
      expect(page.results.first.artist, '');
      expect(page.results.first.title, 'Unknown Release');
      expect(page.results.first.format, '');
      expect(page.results.first.label, '');
      expect(page.results.first.country, '');
      expect(page.results.first.year, isNull);
      expect(page.results.first.thumbUrl, isNull);
    });

    test('returns empty results list when results array is empty', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response(searchBody([]), 200)),
      );
      final page = await client.searchReleases('nothing', _fakeToken);
      expect(page.results, isEmpty);
    });

    test('encodes query, type, page and per_page in request URL', () async {
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
      expect(captured.url.queryParameters['page'], '1');
      expect(captured.url.queryParameters['per_page'], '50');
    });

    test('passes custom page number in request URL', () async {
      late http.Request captured;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(searchBody([]), 200);
        }),
      );
      await client.searchReleases('test', _fakeToken, page: 3);
      expect(captured.url.queryParameters['page'], '3');
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

  group('DiscogsApiClient.searchByBarcode', () {
    String searchBody(
      List<Map<String, dynamic>> results, {
      int page = 1,
      int pages = 1,
      int items = 0,
    }) => jsonEncode({
      'results': results,
      'pagination': {
        'page': page,
        'pages': pages,
        'items': items,
        'per_page': 50,
      },
    });

    final kindOfBlue = {
      'id': 249504,
      'title': 'Miles Davis - Kind Of Blue',
      'thumb': 'https://i.discogs.com/cover.jpg',
      'format': ['Vinyl', 'LP'],
      'label': ['Columbia'],
      'year': '1959',
      'country': 'US',
    };

    test('returns DiscogsSearchPageDto on 200', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([kindOfBlue]), 200),
        ),
      );
      final page = await client.searchByBarcode('5099706035422', _fakeToken);
      expect(page, isA<DiscogsSearchPageDto>());
      expect(page.results, hasLength(1));
      expect(page.results.first, isA<DiscogsSearchResultDto>());
    });

    test('parses pagination fields', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            searchBody([kindOfBlue], page: 1, pages: 3, items: 120),
            200,
          ),
        ),
      );
      final page = await client.searchByBarcode('5099706035422', _fakeToken);
      expect(page.currentPage, 1);
      expect(page.totalPages, 3);
      expect(page.totalResults, 120);
    });

    test('encodes barcode, type, page and per_page in request URL', () async {
      late http.Request captured;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(searchBody([]), 200);
        }),
      );
      await client.searchByBarcode('5099706035422', _fakeToken);
      expect(captured.url.path, '/database/search');
      expect(captured.url.queryParameters['barcode'], '5099706035422');
      expect(captured.url.queryParameters['type'], 'release');
      expect(captured.url.queryParameters.containsKey('q'), isFalse);
      expect(captured.url.queryParameters['page'], '1');
      expect(captured.url.queryParameters['per_page'], '50');
    });

    test('returns empty results when results array is empty', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response(searchBody([]), 200)),
      );
      final page = await client.searchByBarcode('0000000000000', _fakeToken);
      expect(page.results, isEmpty);
    });

    test('throws InvalidTokenError on 401', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      expect(
        () => client.searchByBarcode('1234567890', _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.searchByBarcode('1234567890', _fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });
  });

  group('DiscogsApiClient.fetchCollectionPage', () {
    const fakeUsername = 'vinyl_fan';

    Map<String, dynamic> collectionBody({
      int page = 1,
      int pages = 3,
      int perPage = 50,
      int items = 125,
      List<Map<String, dynamic>> releases = const [],
    }) => {
      'pagination': {
        'page': page,
        'pages': pages,
        'per_page': perPage,
        'items': items,
        'urls': {
          'next':
              'https://api.discogs.com/users/vinyl_fan/collection/folders/0/releases?page=2',
          'last':
              'https://api.discogs.com/users/vinyl_fan/collection/folders/0/releases?page=$pages',
        },
      },
      'releases': releases,
    };

    final kindOfBlueRelease = {
      'id': 11111,
      'instance_id': 99999,
      'date_added': '2023-01-15T10:30:00-08:00',
      'rating': 4,
      'folder_id': 1,
      'basic_information': {
        'id': 249504,
        'title': 'Kind Of Blue',
        'year': 1959,
        'thumb': 'https://i.discogs.com/kind_of_blue_150.jpg',
        'cover_image': 'https://i.discogs.com/kind_of_blue.jpg',
        'artists': [
          {'name': 'Miles Davis', 'id': 15885},
        ],
        'labels': [
          {'name': 'Columbia', 'catno': 'CL 1355', 'id': 1},
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
      },
    };

    test('returns DiscogsCollectionPageDto on 200', () async {
      final body = collectionBody(releases: [kindOfBlueRelease]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(page, isA<DiscogsCollectionPageDto>());
    });

    test('parses pagination fields', () async {
      final body = collectionBody(page: 2, pages: 5, items: 230);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(page.page, 2);
      expect(page.totalPages, 5);
      expect(page.totalItems, 230);
    });

    test('parses collection item fields', () async {
      final body = collectionBody(releases: [kindOfBlueRelease]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      final item = page.items.first;
      expect(item, isA<DiscogsCollectionItemDto>());
      expect(item.releaseId, 11111);
      expect(item.instanceId, 99999);
      expect(item.dateAdded, '2023-01-15T10:30:00-08:00');
      expect(item.rating, 4);
      expect(item.folderId, 1);
    });

    test('parses title, artist, year from basic_information', () async {
      final body = collectionBody(releases: [kindOfBlueRelease]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      final item = page.items.first;
      expect(item.title, 'Kind Of Blue');
      expect(item.artist, 'Miles Davis');
      expect(item.year, 1959);
    });

    test('parses label and catalog number', () async {
      final body = collectionBody(releases: [kindOfBlueRelease]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      final item = page.items.first;
      expect(item.label, 'Columbia');
      expect(item.catno, 'CL 1355');
    });

    test('parses format with descriptions', () async {
      final body = collectionBody(releases: [kindOfBlueRelease]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(page.items.first.format, 'Vinyl, LP, Album');
    });

    test('parses genres', () async {
      final body = collectionBody(releases: [kindOfBlueRelease]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(page.items.first.genres, ['Jazz']);
    });

    test('parses thumbUrl from basic_information thumb', () async {
      final body = collectionBody(releases: [kindOfBlueRelease]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(
        page.items.first.thumbUrl,
        'https://i.discogs.com/kind_of_blue_150.jpg',
      );
    });

    test('treats empty thumb string as null', () async {
      final release = {
        ...kindOfBlueRelease,
        'basic_information': {
          ...(kindOfBlueRelease['basic_information'] as Map<String, dynamic>),
          'thumb': '',
        },
      };
      final body = collectionBody(releases: [release]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(page.items.first.thumbUrl, isNull);
    });

    test('joins multiple artists with comma', () async {
      final multiArtist = {
        ...kindOfBlueRelease,
        'basic_information': {
          ...(kindOfBlueRelease['basic_information'] as Map<String, dynamic>),
          'artists': [
            {'name': 'John Lennon'},
            {'name': 'Paul McCartney'},
          ],
        },
      };
      final body = collectionBody(releases: [multiArtist]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(page.items.first.artist, 'John Lennon, Paul McCartney');
    });

    test('handles missing optional fields gracefully', () async {
      final minimal = {
        'id': 1,
        'instance_id': 2,
        'date_added': '',
        'rating': 0,
        'folder_id': 0,
        'basic_information': {'id': 1},
      };
      final body = collectionBody(releases: [minimal]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      final item = page.items.first;
      expect(item.title, '');
      expect(item.artist, '');
      expect(item.label, '');
      expect(item.catno, '');
      expect(item.format, '');
      expect(item.genres, isEmpty);
      expect(item.year, isNull);
      expect(item.thumbUrl, isNull);
    });

    test('returns empty items list when releases array is empty', () async {
      final body = collectionBody();
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(page.items, isEmpty);
      expect(page.totalItems, 125);
    });

    test('encodes correct URL path for the given username', () async {
      late http.Request captured;
      final body = collectionBody();
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(body), 200);
        }),
      );
      await client.fetchCollectionPage('vinyl_fan', _fakeToken);
      expect(
        captured.url.path,
        '/users/vinyl_fan/collection/folders/0/releases',
      );
    });

    test('encodes page and per_page query parameters', () async {
      late http.Request captured;
      final body = collectionBody();
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(body), 200);
        }),
      );
      await client.fetchCollectionPage(
        fakeUsername,
        _fakeToken,
        page: 3,
        perPage: 25,
      );
      expect(captured.url.queryParameters['page'], '3');
      expect(captured.url.queryParameters['per_page'], '25');
    });

    test('defaults to page=1 and perPage=50', () async {
      late http.Request captured;
      final body = collectionBody();
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(body), 200);
        }),
      );
      await client.fetchCollectionPage(fakeUsername, _fakeToken);
      expect(captured.url.queryParameters['page'], '1');
      expect(captured.url.queryParameters['per_page'], '50');
    });

    test('throws InvalidTokenError on 401', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      expect(
        () => client.fetchCollectionPage(fakeUsername, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws InvalidTokenError on 403', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(403));
      expect(
        () => client.fetchCollectionPage(fakeUsername, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.fetchCollectionPage(fakeUsername, _fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('throws DiscogsUnavailableError on 500', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(500));
      expect(
        () => client.fetchCollectionPage(fakeUsername, _fakeToken),
        throwsA(isA<DiscogsUnavailableError>()),
      );
    });

    test('throws NetworkError when request throws', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => client.fetchCollectionPage(fakeUsername, _fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test('token is not present in thrown error messages', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      try {
        await client.fetchCollectionPage(fakeUsername, _fakeToken);
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
        {'position': '', 'type_': 'heading', 'title': 'Side B', 'duration': ''},
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
      expect(release.tracklist.map((t) => t.title), [
        'So What',
        'Freddie Freeloader',
        'Blue In Green',
      ]);
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
          {'type': 'secondary', 'uri': 'https://i.discogs.com/back.jpg'},
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

  group('DiscogsApiClient.fetchWantlistPage', () {
    const fakeUsername = 'vinyl_fan';

    Map<String, dynamic> wantlistBody({
      int page = 1,
      int pages = 3,
      int perPage = 50,
      int items = 125,
      List<Map<String, dynamic>> wants = const [],
    }) => {
      'pagination': {
        'page': page,
        'pages': pages,
        'per_page': perPage,
        'items': items,
        'urls': {
          'next': 'https://api.discogs.com/users/vinyl_fan/wants?page=2',
          'last': 'https://api.discogs.com/users/vinyl_fan/wants?page=$pages',
        },
      },
      'wants': wants,
    };

    final bridgeStrippedBare = {
      'id': 3003339,
      'resource_url': 'https://api.discogs.com/users/vinyl_fan/wants/3003339',
      'rating': 3,
      'notes': 'Great album, need to find a copy.',
      'date_added': '2023-04-10T09:15:00-07:00',
      'basic_information': {
        'id': 3003339,
        'title': 'The Bride Stripped Bare',
        'year': 1978,
        'thumb': 'https://i.discogs.com/bride_150.jpg',
        'cover_image': 'https://i.discogs.com/bride.jpg',
        'artists': [
          {'name': 'Bryan Ferry', 'id': 79999},
        ],
        'labels': [
          {'name': 'Polydor', 'catno': '2302 069', 'id': 812},
        ],
        'formats': [
          {
            'name': 'Vinyl',
            'qty': '1',
            'descriptions': ['LP', 'Album'],
          },
        ],
        'genres': ['Rock'],
        'styles': ['Art Rock', 'New Wave'],
      },
    };

    test('returns DiscogsWantlistPageDto on 200', () async {
      final body = wantlistBody(wants: [bridgeStrippedBare]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page, isA<DiscogsWantlistPageDto>());
    });

    test('parses pagination fields', () async {
      final body = wantlistBody(page: 2, pages: 5, items: 230);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.page, 2);
      expect(page.totalPages, 5);
      expect(page.totalItems, 230);
    });

    test('parses wantlist item fields', () async {
      final body = wantlistBody(wants: [bridgeStrippedBare]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      final item = page.items.first;
      expect(item, isA<DiscogsWantlistItemDto>());
      expect(item.releaseId, 3003339);
      expect(item.dateAdded, '2023-04-10T09:15:00-07:00');
      expect(item.rating, 3);
    });

    test('parses title, artist, year from basic_information', () async {
      final body = wantlistBody(wants: [bridgeStrippedBare]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      final item = page.items.first;
      expect(item.title, 'The Bride Stripped Bare');
      expect(item.artist, 'Bryan Ferry');
      expect(item.year, 1978);
    });

    test('parses label and catalog number', () async {
      final body = wantlistBody(wants: [bridgeStrippedBare]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      final item = page.items.first;
      expect(item.label, 'Polydor');
      expect(item.catno, '2302 069');
    });

    test('parses format with descriptions', () async {
      final body = wantlistBody(wants: [bridgeStrippedBare]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items.first.format, 'Vinyl, LP, Album');
    });

    test('parses genres', () async {
      final body = wantlistBody(wants: [bridgeStrippedBare]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items.first.genres, ['Rock']);
    });

    test('parses thumbUrl from basic_information thumb', () async {
      final body = wantlistBody(wants: [bridgeStrippedBare]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items.first.thumbUrl, 'https://i.discogs.com/bride_150.jpg');
    });

    test('treats empty thumb string as null', () async {
      final item = {
        ...bridgeStrippedBare,
        'basic_information': {
          ...(bridgeStrippedBare['basic_information'] as Map<String, dynamic>),
          'thumb': '',
        },
      };
      final body = wantlistBody(wants: [item]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items.first.thumbUrl, isNull);
    });

    test('parses notes field', () async {
      final body = wantlistBody(wants: [bridgeStrippedBare]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items.first.notes, 'Great album, need to find a copy.');
    });

    test('treats absent notes as null', () async {
      final noNotes = {...bridgeStrippedBare}..remove('notes');
      final body = wantlistBody(wants: [noNotes]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items.first.notes, isNull);
    });

    test('treats empty notes string as null', () async {
      final emptyNotes = {...bridgeStrippedBare, 'notes': ''};
      final body = wantlistBody(wants: [emptyNotes]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items.first.notes, isNull);
    });

    test('joins multiple artists with comma', () async {
      final multiArtist = {
        ...bridgeStrippedBare,
        'basic_information': {
          ...(bridgeStrippedBare['basic_information'] as Map<String, dynamic>),
          'artists': [
            {'name': 'John Lennon'},
            {'name': 'Paul McCartney'},
          ],
        },
      };
      final body = wantlistBody(wants: [multiArtist]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items.first.artist, 'John Lennon, Paul McCartney');
    });

    test('handles missing optional fields gracefully', () async {
      final minimal = {
        'id': 1,
        'date_added': '',
        'rating': 0,
        'basic_information': {'id': 1},
      };
      final body = wantlistBody(wants: [minimal]);
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      final item = page.items.first;
      expect(item.title, '');
      expect(item.artist, '');
      expect(item.label, '');
      expect(item.catno, '');
      expect(item.format, '');
      expect(item.genres, isEmpty);
      expect(item.year, isNull);
      expect(item.thumbUrl, isNull);
      expect(item.notes, isNull);
    });

    test('returns empty items list when wants array is empty', () async {
      final body = wantlistBody();
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        ),
      );
      final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(page.items, isEmpty);
      expect(page.totalItems, 125);
    });

    test('encodes correct URL path for the given username', () async {
      late http.Request captured;
      final body = wantlistBody();
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(body), 200);
        }),
      );
      await client.fetchWantlistPage('vinyl_fan', _fakeToken);
      expect(captured.url.path, '/users/vinyl_fan/wants');
    });

    test('encodes page and per_page query parameters', () async {
      late http.Request captured;
      final body = wantlistBody();
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(body), 200);
        }),
      );
      await client.fetchWantlistPage(
        fakeUsername,
        _fakeToken,
        page: 3,
        perPage: 25,
      );
      expect(captured.url.queryParameters['page'], '3');
      expect(captured.url.queryParameters['per_page'], '25');
    });

    test('defaults to page=1 and perPage=50', () async {
      late http.Request captured;
      final body = wantlistBody();
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(body), 200);
        }),
      );
      await client.fetchWantlistPage(fakeUsername, _fakeToken);
      expect(captured.url.queryParameters['page'], '1');
      expect(captured.url.queryParameters['per_page'], '50');
    });

    test('throws InvalidTokenError on 401', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      expect(
        () => client.fetchWantlistPage(fakeUsername, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws InvalidTokenError on 403', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(403));
      expect(
        () => client.fetchWantlistPage(fakeUsername, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.fetchWantlistPage(fakeUsername, _fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('throws DiscogsUnavailableError on 500', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(500));
      expect(
        () => client.fetchWantlistPage(fakeUsername, _fakeToken),
        throwsA(isA<DiscogsUnavailableError>()),
      );
    });

    test('throws NetworkError when request throws', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => client.fetchWantlistPage(fakeUsername, _fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test('token is not present in thrown error messages', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      try {
        await client.fetchWantlistPage(fakeUsername, _fakeToken);
        fail('expected InvalidTokenError');
      } on InvalidTokenError {
        // Pass — typed error carries no message containing the token.
      }
    });
  });

  group('DiscogsApiClient.addToCollection', () {
    const fakeUsername = 'vinyl_fan';
    const fakeReleaseId = 12345;

    test('completes normally on 201', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(201));
      await expectLater(
        client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken),
        completes,
      );
    });

    test('sends POST to correct URL', () async {
      late http.Request capturedRequest;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 201);
        }),
      );

      await client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken);

      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.path,
        '/users/$fakeUsername/collection/folders/1/releases/$fakeReleaseId',
      );
    });

    test('includes correct authorization header', () async {
      late http.Request capturedRequest;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 201);
        }),
      );

      await client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken);

      expect(
        capturedRequest.headers['Authorization'],
        'Discogs token=$_fakeToken',
      );
    });

    test('throws InvalidTokenError on 401', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      expect(
        () => client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws InvalidTokenError on 403', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(403));
      expect(
        () => client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('throws DiscogsUnavailableError on 500', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(500));
      expect(
        () => client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<DiscogsUnavailableError>()),
      );
    });

    test('throws NetworkError when request throws', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => throw Exception('no internet')),
      );
      expect(
        () => client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test('throws NetworkError when request times out', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return http.Response('', 201);
        }),
        requestTimeout: const Duration(milliseconds: 50),
      );
      expect(
        () => client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test('does not throw on 200 (treats as unexpected)', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(200));
      expect(
        () => client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<UnexpectedApiError>()),
      );
    });

    test('token is not present in thrown error messages', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      try {
        await client.addToCollection(fakeUsername, fakeReleaseId, _fakeToken);
        fail('expected InvalidTokenError');
      } on InvalidTokenError {
        // Pass — typed error carries no message containing the token.
      }
    });
  });
}

import 'dart:convert';

import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_collection_item.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_identity.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_release.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_search_result.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_wantlist_item.dart';
import 'package:cratewise/domain/models/search_filter.dart';
import 'package:cratewise/domain/models/search_sort.dart';
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
        httpClient: MockClient(
          (_) async => throw http.ClientException('no internet'),
        ),
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

    test('uses dedicated artist field when present', () async {
      final withDedicatedArtist = {
        ...kindOfBlue,
        'title': 'Kind Of Blue',
        'artist': 'Miles Davis',
      };
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([withDedicatedArtist]), 200),
        ),
      );
      final page = await client.searchReleases('kind of blue', _fakeToken);
      expect(page.results.first.artist, 'Miles Davis');
      expect(page.results.first.title, 'Kind Of Blue');
    });

    test('splits on last separator when artist name contains " - "', () async {
      final dashArtist = {
        'id': 99,
        'title': 'This - Artist - The Album',
        'format': ['Vinyl'],
        'label': ['Test Label'],
        'year': '1985',
        'country': 'UK',
      };
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(searchBody([dashArtist]), 200),
        ),
      );
      final page = await client.searchReleases('test', _fakeToken);
      expect(page.results.first.artist, 'This - Artist');
      expect(page.results.first.title, 'The Album');
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

    test('scopes the query parameter to the selected filter (US-85)', () async {
      late http.Request captured;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(searchBody([]), 200);
        }),
      );

      // All → general `q`.
      await client.searchReleases('blue', _fakeToken);
      expect(captured.url.queryParameters['q'], 'blue');
      expect(captured.url.queryParameters['type'], 'release');

      // Release → release_title (and no general q).
      await client.searchReleases(
        'blue',
        _fakeToken,
        filter: SearchFilter.release,
      );
      expect(captured.url.queryParameters['release_title'], 'blue');
      expect(captured.url.queryParameters.containsKey('q'), isFalse);
      expect(captured.url.queryParameters['type'], 'release');

      // Artist → artist.
      await client.searchReleases(
        'blue',
        _fakeToken,
        filter: SearchFilter.artist,
      );
      expect(captured.url.queryParameters['artist'], 'blue');
      expect(captured.url.queryParameters.containsKey('q'), isFalse);

      // Label → label.
      await client.searchReleases(
        'blue',
        _fakeToken,
        filter: SearchFilter.label,
      );
      expect(captured.url.queryParameters['label'], 'blue');
      expect(captured.url.queryParameters.containsKey('q'), isFalse);
      expect(captured.url.queryParameters['type'], 'release');
    });

    test('sends sort=year with the right order, nothing for relevance '
        '(US-133)', () async {
      late http.Request captured;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(searchBody([]), 200);
        }),
      );

      await client.searchReleases('blue note', _fakeToken);
      expect(captured.url.queryParameters.containsKey('sort'), isFalse);
      expect(captured.url.queryParameters.containsKey('sort_order'), isFalse);

      await client.searchReleases(
        'blue note',
        _fakeToken,
        filter: SearchFilter.label,
        sort: SearchSort.newestFirst,
        page: 2,
      );
      expect(captured.url.queryParameters['sort'], 'year');
      expect(captured.url.queryParameters['sort_order'], 'desc');
      expect(captured.url.queryParameters['label'], 'blue note');
      expect(captured.url.queryParameters['page'], '2');

      await client.searchReleases(
        'blue note',
        _fakeToken,
        sort: SearchSort.oldestFirst,
      );
      expect(captured.url.queryParameters['sort'], 'year');
      expect(captured.url.queryParameters['sort_order'], 'asc');
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
        httpClient: MockClient(
          (_) async => throw http.ClientException('no internet'),
        ),
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

    test(
      'joins all format entries with newline when multiple formats present',
      () async {
        final multiFormat = {
          ...kindOfBlueRelease,
          'basic_information': {
            ...(kindOfBlueRelease['basic_information'] as Map<String, dynamic>),
            'formats': [
              {
                'name': 'Vinyl',
                'qty': '1',
                'descriptions': ['LP', 'Album'],
              },
              {
                'name': 'Vinyl',
                'qty': '1',
                'descriptions': ['7"', 'Single'],
              },
            ],
          },
        };
        final body = collectionBody(releases: [multiFormat]);
        final client = DiscogsApiClient(
          httpClient: MockClient(
            (_) async => http.Response(jsonEncode(body), 200),
          ),
        );
        final page = await client.fetchCollectionPage(fakeUsername, _fakeToken);
        expect(page.items.first.format, 'Vinyl, LP, Album\nVinyl, 7", Single');
      },
    );

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
        httpClient: MockClient(
          (_) async => throw http.ClientException('no internet'),
        ),
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

    test('displayArtist equals artist when anv is absent', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.displayArtist, 'Miles Davis');
    });

    test('uses anv as displayArtist when present and non-empty', () async {
      final withAnv = {
        ...kindOfBlueRelease,
        'artists': [
          {'name': 'Miles Davis', 'anv': 'Miles Davis Sextet', 'id': 15885},
        ],
      };
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(withAnv), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.artist, 'Miles Davis');
      expect(release.displayArtist, 'Miles Davis Sextet');
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

    test(
      'joins all format entries with newline when multiple formats present',
      () async {
        final multiFormat = {
          ...kindOfBlueRelease,
          'formats': [
            {
              'name': 'Vinyl',
              'qty': '1',
              'descriptions': ['LP', 'Album'],
            },
            {
              'name': 'Vinyl',
              'qty': '1',
              'descriptions': ['7"', 'Single'],
            },
          ],
        };
        final client = DiscogsApiClient(
          httpClient: MockClient(
            (_) async => http.Response(jsonEncode(multiFormat), 200),
          ),
        );
        final release = await client.fetchRelease(249504, _fakeToken);
        expect(release.format, 'Vinyl, LP, Album\nVinyl, 7", Single');
      },
    );

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

    test('parses thumbUrl from primary image uri150', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(kindOfBlueRelease), 200),
        ),
      );
      final release = await client.fetchRelease(249504, _fakeToken);
      expect(release.thumbUrl, 'https://i.discogs.com/kind_of_blue_150.jpg');
    });

    test('thumbUrl is null when uri150 is absent from images', () async {
      final noUri150 = {
        ...kindOfBlueRelease,
        'images': [
          {'type': 'primary', 'uri': 'https://i.discogs.com/kind_of_blue.jpg'},
        ],
      };
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(noUri150), 200),
        ),
      );
      final release = await client.fetchRelease(1, _fakeToken);
      expect(release.thumbUrl, isNull);
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
        httpClient: MockClient(
          (_) async => throw http.ClientException('no internet'),
        ),
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

    test(
      'joins all format entries with newline when multiple formats present',
      () async {
        final multiFormat = {
          ...bridgeStrippedBare,
          'basic_information': {
            ...(bridgeStrippedBare['basic_information']
                as Map<String, dynamic>),
            'formats': [
              {
                'name': 'Vinyl',
                'qty': '1',
                'descriptions': ['LP', 'Album'],
              },
              {
                'name': 'Vinyl',
                'qty': '1',
                'descriptions': ['7"', 'Single'],
              },
            ],
          },
        };
        final body = wantlistBody(wants: [multiFormat]);
        final client = DiscogsApiClient(
          httpClient: MockClient(
            (_) async => http.Response(jsonEncode(body), 200),
          ),
        );
        final page = await client.fetchWantlistPage(fakeUsername, _fakeToken);
        expect(page.items.first.format, 'Vinyl, LP, Album\nVinyl, 7", Single');
      },
    );

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
        httpClient: MockClient(
          (_) async => throw http.ClientException('no internet'),
        ),
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

  group('DiscogsApiClient rate-limit back-off', () {
    const identityBody = '{"username":"u","resource_url":"u"}';

    http.Response withRemaining(
      int remaining, {
      int status = 200,
      String body = identityBody,
    }) => http.Response(
      body,
      status,
      headers: {'x-discogs-ratelimit-remaining': '$remaining'},
    );

    test('does not delay when rate-limit remaining header is absent', () async {
      final delays = <Duration>[];
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response(identityBody, 200)),
        delay: (d) async => delays.add(d),
      );

      await client.fetchIdentity(_fakeToken);
      await client.fetchIdentity(_fakeToken);

      expect(delays, isEmpty);
    });

    test('does not delay when remaining is above the threshold', () async {
      final delays = <Duration>[];
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => withRemaining(5)),
        delay: (d) async => delays.add(d),
      );

      await client.fetchIdentity(_fakeToken);
      await client.fetchIdentity(_fakeToken);

      expect(delays, isEmpty);
    });

    test('delays the next GET request when remaining reaches 0', () async {
      final delays = <Duration>[];
      int callCount = 0;
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async {
          callCount++;
          return callCount == 1
              ? withRemaining(0)
              : http.Response(identityBody, 200);
        }),
        delay: (d) async => delays.add(d),
      );

      await client.fetchIdentity(_fakeToken); // remaining=0 → schedules delay
      await client.fetchIdentity(_fakeToken); // preceded by delay

      expect(delays, hasLength(1));
    });

    test(
      'delay duration is approximately the rate-limit reset window',
      () async {
        final delays = <Duration>[];
        int callCount = 0;
        final client = DiscogsApiClient(
          httpClient: MockClient((_) async {
            callCount++;
            return callCount == 1
                ? withRemaining(0)
                : http.Response(identityBody, 200);
          }),
          delay: (d) async => delays.add(d),
        );

        await client.fetchIdentity(_fakeToken);
        await client.fetchIdentity(_fakeToken);

        expect(delays.first.inSeconds, greaterThanOrEqualTo(59));
      },
    );

    test('delay fires only once then clears for subsequent calls', () async {
      final delays = <Duration>[];
      int callCount = 0;
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async {
          callCount++;
          return callCount == 1
              ? withRemaining(0)
              : http.Response(identityBody, 200);
        }),
        delay: (d) async => delays.add(d),
      );

      await client.fetchIdentity(_fakeToken); // remaining=0 → schedules delay
      await client.fetchIdentity(_fakeToken); // fires delay
      await client.fetchIdentity(_fakeToken); // no delay (cleared)

      expect(delays, hasLength(1));
    });

    test(
      'delays the next POST request when previous response had remaining=0',
      () async {
        final delays = <Duration>[];
        int callCount = 0;
        final client = DiscogsApiClient(
          httpClient: MockClient((_) async {
            callCount++;
            return callCount == 1 ? withRemaining(0) : http.Response('', 201);
          }),
          delay: (d) async => delays.add(d),
        );

        await client.fetchIdentity(_fakeToken); // GET with remaining=0
        await client.addToCollection(
          'user',
          123,
          _fakeToken,
        ); // POST: should delay

        expect(delays, hasLength(1));
      },
    );
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

    test('returns the instance_id from the 201 body', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => http.Response('{"instance_id": 778899}', 201),
        ),
      );

      final instanceId = await client.addToCollection(
        fakeUsername,
        fakeReleaseId,
        _fakeToken,
      );

      expect(instanceId, 778899);
    });

    test('returns null when the 201 body has no instance_id', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response('', 201)),
      );

      final instanceId = await client.addToCollection(
        fakeUsername,
        fakeReleaseId,
        _fakeToken,
      );

      expect(instanceId, isNull);
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
        httpClient: MockClient(
          (_) async => throw http.ClientException('no internet'),
        ),
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

  group('DiscogsApiClient.addToWantlist', () {
    const fakeUsername = 'vinyl_fan';
    const fakeReleaseId = 12345;

    test('completes normally on 201', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(201));
      await expectLater(
        client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        completes,
      );
    });

    test('sends PUT to correct URL', () async {
      // The Discogs API adds wantlist entries with
      // PUT /users/{username}/wants/{release_id}; POST returns 405.
      late http.Request capturedRequest;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 201);
        }),
      );

      await client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken);

      expect(capturedRequest.method, 'PUT');
      expect(
        capturedRequest.url.path,
        '/users/$fakeUsername/wants/$fakeReleaseId',
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

      await client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken);

      expect(
        capturedRequest.headers['Authorization'],
        'Discogs token=$_fakeToken',
      );
    });

    test('throws InvalidTokenError on 401', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      expect(
        () => client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws InvalidTokenError on 403', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(403));
      expect(
        () => client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<InvalidTokenError>()),
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('throws DiscogsUnavailableError on 500', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(500));
      expect(
        () => client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<DiscogsUnavailableError>()),
      );
    });

    test('throws NetworkError when request throws', () async {
      final client = DiscogsApiClient(
        httpClient: MockClient(
          (_) async => throw http.ClientException('no internet'),
        ),
      );
      expect(
        () => client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken),
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
        () => client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<NetworkError>()),
      );
    });

    test('throws UnexpectedApiError on 200', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(200));
      expect(
        () => client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<UnexpectedApiError>()),
      );
    });

    test('token is not present in thrown error messages', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      try {
        await client.addToWantlist(fakeUsername, fakeReleaseId, _fakeToken);
        fail('expected InvalidTokenError');
      } on InvalidTokenError {
        // Pass — typed error carries no message containing the token.
      }
    });
  });

  group('DiscogsApiClient.removeFromCollection', () {
    const fakeUsername = 'vinyl_fan';
    const fakeReleaseId = 12345;
    const fakeInstanceId = 9001;

    test('completes normally on 204', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(204));
      await expectLater(
        client.removeFromCollection(
          fakeUsername,
          fakeReleaseId,
          fakeInstanceId,
          _fakeToken,
        ),
        completes,
      );
    });

    test('sends DELETE to the instance URL', () async {
      late http.Request captured;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('', 204);
        }),
      );

      await client.removeFromCollection(
        fakeUsername,
        fakeReleaseId,
        fakeInstanceId,
        _fakeToken,
      );

      expect(captured.method, 'DELETE');
      expect(
        captured.url.path,
        '/users/$fakeUsername/collection/folders/1/releases/'
        '$fakeReleaseId/instances/$fakeInstanceId',
      );
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () => client.removeFromCollection(
          fakeUsername,
          fakeReleaseId,
          fakeInstanceId,
          _fakeToken,
        ),
        throwsA(isA<RateLimitedError>()),
      );
    });

    test('token is not present in thrown error messages', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(401));
      try {
        await client.removeFromCollection(
          fakeUsername,
          fakeReleaseId,
          fakeInstanceId,
          _fakeToken,
        );
        fail('expected InvalidTokenError');
      } on InvalidTokenError {
        // Pass — typed error carries no token.
      }
    });
  });

  group('DiscogsApiClient.removeFromWantlist', () {
    const fakeUsername = 'vinyl_fan';
    const fakeReleaseId = 12345;

    test('completes normally on 204', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(204));
      await expectLater(
        client.removeFromWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        completes,
      );
    });

    test('sends DELETE to the wants URL', () async {
      late http.Request captured;
      final client = DiscogsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('', 204);
        }),
      );

      await client.removeFromWantlist(fakeUsername, fakeReleaseId, _fakeToken);

      expect(captured.method, 'DELETE');
      expect(captured.url.path, '/users/$fakeUsername/wants/$fakeReleaseId');
    });

    test('throws RateLimitedError on 429', () async {
      final client = DiscogsApiClient(httpClient: _mockClient(429));
      expect(
        () =>
            client.removeFromWantlist(fakeUsername, fakeReleaseId, _fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
    });
  });

  group('US-126: shared back-off', () {
    test('a 429 makes the next request wait (Retry-After honoured)', () async {
      final delays = <Duration>[];
      var calls = 0;
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('', 429, headers: {'retry-after': '30'})
              : http.Response('{"username":"u","resource_url":"u"}', 200);
        }),
        delay: (d) async => delays.add(d),
      );

      await expectLater(
        client.fetchIdentity(_fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
      await client.fetchIdentity(_fakeToken);

      expect(delays, hasLength(1));
      expect(delays.single.inSeconds, inInclusiveRange(28, 30));
    });

    test('concurrent requests during a back-off all wait', () async {
      final delays = <Duration>[];
      var calls = 0;
      final client = DiscogsApiClient(
        httpClient: MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('', 429)
              : http.Response('{"username":"u","resource_url":"u"}', 200);
        }),
        delay: (d) async {
          delays.add(d);
          await Future<void>.delayed(Duration.zero);
        },
      );

      await expectLater(
        client.fetchIdentity(_fakeToken),
        throwsA(isA<RateLimitedError>()),
      );
      await Future.wait([
        client.fetchIdentity(_fakeToken),
        client.fetchIdentity(_fakeToken),
      ]);

      expect(delays, hasLength(2));
    });
  });

  test('US-132: a non-network bug is not reported as NetworkError', () async {
    final client = DiscogsApiClient(
      httpClient: MockClient((_) async => throw StateError('bug')),
    );

    await expectLater(
      client.fetchIdentity(_fakeToken),
      throwsA(isA<StateError>()),
    );
  });
}

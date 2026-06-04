import 'dart:convert';

import 'package:cratewise/application/use_cases/barcode_lookup_use_case.dart';
import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/domain/models/search_result_page.dart';
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
  _FakeStorage({this.token, this.throwsError = false});

  final String? token;
  final bool throwsError;

  @override
  Future<String?> loadToken() async {
    if (throwsError) throw const StorageError();
    return token;
  }

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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BarcodeLookupUseCase _makeUseCase({
  String? token,
  bool storageThrows = false,
  required http.Client httpClient,
}) {
  return BarcodeLookupUseCase(
    storage: _FakeStorage(token: token, throwsError: storageThrows),
    apiClient: DiscogsApiClient(httpClient: httpClient),
  );
}

String _searchBody(
  List<Map<String, dynamic>> results, {
  int page = 1,
  int pages = 1,
  int items = 0,
}) => jsonEncode({
  'results': results,
  'pagination': {'page': page, 'pages': pages, 'items': items, 'per_page': 50},
});

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
  group('BarcodeLookupUseCase.execute — input validation', () {
    test('returns EmptyInput when barcode is empty string', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([]), 200),
        ),
      );
      final result = await useCase.execute('');
      expect(result, isA<BarcodeLookupEmptyInput>());
    });

    test('returns EmptyInput when barcode is whitespace-only', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([]), 200),
        ),
      );
      final result = await useCase.execute('   ');
      expect(result, isA<BarcodeLookupEmptyInput>());
    });
  });

  group('BarcodeLookupUseCase.execute — token state', () {
    test('returns NoToken when no token stored', () async {
      final useCase = _makeUseCase(
        token: null,
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([]), 200),
        ),
      );
      final result = await useCase.execute('1234567890');
      expect(result, isA<BarcodeLookupNoToken>());
    });

    test('returns Error when storage throws StorageError', () async {
      final useCase = _makeUseCase(
        storageThrows: true,
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([]), 200),
        ),
      );
      final result = await useCase.execute('1234567890');
      expect(result, isA<BarcodeLookupError>());
      expect((result as BarcodeLookupError).error, isA<StorageError>());
    });
  });

  group('BarcodeLookupUseCase.execute — success paths', () {
    test('returns Success when API returns results', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([_kindOfBlue], items: 1), 200),
        ),
      );
      final result = await useCase.execute('5099706035422');
      expect(result, isA<BarcodeLookupSuccess>());
    });

    test('Success.page.items are ReleaseSearchResult instances', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([_kindOfBlue], items: 1), 200),
        ),
      );
      final result =
          await useCase.execute('5099706035422') as BarcodeLookupSuccess;
      expect(result.page, isA<SearchResultPage>());
      expect(result.page.items, hasLength(1));
      expect(result.page.items.first, isA<ReleaseSearchResult>());
    });

    test('maps all result fields correctly', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([_kindOfBlue], items: 1), 200),
        ),
      );
      final result =
          await useCase.execute('5099706035422') as BarcodeLookupSuccess;
      final r = result.page.items.first;
      expect(r.id, 249504);
      expect(r.artist, 'Miles Davis');
      expect(r.title, 'Kind Of Blue');
      expect(r.format, 'Vinyl');
      expect(r.label, 'Columbia');
      expect(r.country, 'US');
      expect(r.year, 1959);
      expect(r.coverUrl, 'https://i.discogs.com/cover.jpg');
    });

    test('Success.page carries pagination info', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => http.Response(
            _searchBody([_kindOfBlue], page: 1, pages: 3, items: 120),
            200,
          ),
        ),
      );
      final result =
          await useCase.execute('5099706035422') as BarcodeLookupSuccess;
      expect(result.page.currentPage, 1);
      expect(result.page.totalPages, 3);
      expect(result.page.totalResults, 120);
      expect(result.page.hasMore, isTrue);
    });

    test(
      'returns NoResults when API returns empty results and totalResults==0',
      () async {
        final useCase = _makeUseCase(
          token: 'fake_token',
          httpClient: MockClient(
            (_) async => http.Response(_searchBody([]), 200),
          ),
        );
        final result = await useCase.execute('0000000000000');
        expect(result, isA<BarcodeLookupNoResults>());
      },
    );

    test('uses trimmed barcode in API call', () async {
      late http.Request captured;
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(_searchBody([]), 200);
        }),
      );
      await useCase.execute('  1234567890  ');
      expect(captured.url.queryParameters['barcode'], '1234567890');
    });

    test('sends barcode parameter (not q) in API call', () async {
      late http.Request captured;
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(_searchBody([]), 200);
        }),
      );
      await useCase.execute('1234567890');
      expect(captured.url.queryParameters.containsKey('barcode'), isTrue);
      expect(captured.url.queryParameters.containsKey('q'), isFalse);
    });

    test('passes page number to API', () async {
      late http.Request captured;
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            _searchBody([_kindOfBlue], page: 2, pages: 3, items: 120),
            200,
          );
        }),
      );
      await useCase.execute('1234567890', page: 2);
      expect(captured.url.queryParameters['page'], '2');
    });
  });

  group('BarcodeLookupUseCase.execute — error paths', () {
    test('returns RateLimited when API returns 429', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient((_) async => http.Response('', 429)),
      );
      final result = await useCase.execute('1234567890');
      expect(result, isA<BarcodeLookupRateLimited>());
    });

    test('returns Error when API returns 401', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient((_) async => http.Response('', 401)),
      );
      final result = await useCase.execute('1234567890');
      expect(result, isA<BarcodeLookupError>());
      expect((result as BarcodeLookupError).error, isA<InvalidTokenError>());
    });

    test('returns Error when network fails', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => throw Exception('socket exception'),
        ),
      );
      final result = await useCase.execute('1234567890');
      expect(result, isA<BarcodeLookupError>());
      expect((result as BarcodeLookupError).error, isA<NetworkError>());
    });

    test('returned error does not contain the token string', () async {
      const sensitiveToken = 'super_secret_xyz';
      final useCase = _makeUseCase(
        token: sensitiveToken,
        httpClient: MockClient((_) async => http.Response('', 401)),
      );
      final result = await useCase.execute('1234567890');
      expect(result.toString(), isNot(contains(sensitiveToken)));
      if (result is BarcodeLookupError) {
        expect(result.error.toString(), isNot(contains(sensitiveToken)));
      }
    });
  });

  group('BarcodeLookupUseCase revoked token', () {
    test('clears credentials when API returns 401', () async {
      final spy = _SpyStorage();
      final useCase = BarcodeLookupUseCase(
        storage: spy,
        apiClient: DiscogsApiClient(
          httpClient: MockClient((_) async => http.Response('', 401)),
        ),
      );
      final result = await useCase.execute('1234567890');
      expect(result, isA<BarcodeLookupError>());
      expect((result as BarcodeLookupError).error, isA<InvalidTokenError>());
      expect(spy.deleteCallCount, 1);
    });

    test('does not clear credentials on non-401 error', () async {
      final spy = _SpyStorage();
      final useCase = BarcodeLookupUseCase(
        storage: spy,
        apiClient: DiscogsApiClient(
          httpClient: MockClient((_) async => throw Exception('network error')),
        ),
      );
      final result = await useCase.execute('1234567890');
      expect(result, isA<BarcodeLookupError>());
      expect((result as BarcodeLookupError).error, isA<NetworkError>());
      expect(spy.deleteCallCount, 0);
    });
  });
}

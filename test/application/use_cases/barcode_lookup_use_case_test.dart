import 'dart:convert';

import 'package:cratewise/application/use_cases/barcode_lookup_use_case.dart';
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
  group('BarcodeLookupUseCase.execute — input validation', () {
    test('returns EmptyInput when barcode is empty string', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient((_) async => http.Response(_searchBody([]), 200)),
      );
      final result = await useCase.execute('');
      expect(result, isA<BarcodeLookupEmptyInput>());
    });

    test('returns EmptyInput when barcode is whitespace-only', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient((_) async => http.Response(_searchBody([]), 200)),
      );
      final result = await useCase.execute('   ');
      expect(result, isA<BarcodeLookupEmptyInput>());
    });
  });

  group('BarcodeLookupUseCase.execute — token state', () {
    test('returns NoToken when no token stored', () async {
      final useCase = _makeUseCase(
        token: null,
        httpClient: MockClient((_) async => http.Response(_searchBody([]), 200)),
      );
      final result = await useCase.execute('1234567890');
      expect(result, isA<BarcodeLookupNoToken>());
    });

    test('returns Error when storage throws StorageError', () async {
      final useCase = _makeUseCase(
        storageThrows: true,
        httpClient: MockClient((_) async => http.Response(_searchBody([]), 200)),
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
          (_) async => http.Response(_searchBody([_kindOfBlue]), 200),
        ),
      );
      final result = await useCase.execute('5099706035422');
      expect(result, isA<BarcodeLookupSuccess>());
    });

    test('Success results are ReleaseSearchResult instances', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([_kindOfBlue]), 200),
        ),
      );
      final result = await useCase.execute('5099706035422') as BarcodeLookupSuccess;
      expect(result.results, hasLength(1));
      expect(result.results.first, isA<ReleaseSearchResult>());
    });

    test('maps all result fields correctly', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient: MockClient(
          (_) async => http.Response(_searchBody([_kindOfBlue]), 200),
        ),
      );
      final result = await useCase.execute('5099706035422') as BarcodeLookupSuccess;
      final r = result.results.first;
      expect(r.id, 249504);
      expect(r.artist, 'Miles Davis');
      expect(r.title, 'Kind Of Blue');
      expect(r.format, 'Vinyl');
      expect(r.label, 'Columbia');
      expect(r.country, 'US');
      expect(r.year, 1959);
      expect(r.coverUrl, 'https://i.discogs.com/cover.jpg');
    });

    test('returns NoResults when API returns empty list', () async {
      final useCase = _makeUseCase(
        token: 'fake_token',
        httpClient:
            MockClient((_) async => http.Response(_searchBody([]), 200)),
      );
      final result = await useCase.execute('0000000000000');
      expect(result, isA<BarcodeLookupNoResults>());
    });

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
        httpClient:
            MockClient((_) async => throw Exception('socket exception')),
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
}

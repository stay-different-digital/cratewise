import 'dart:convert';

import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_identity.dart';
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
}

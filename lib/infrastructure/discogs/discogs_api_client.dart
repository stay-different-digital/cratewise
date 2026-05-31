import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../shared/errors/app_error.dart';
import 'dto/discogs_identity.dart';

const _baseUrl = 'https://api.discogs.com';
const _userAgent = 'Cratewise/1.0';
const _accept = 'application/vnd.discogs.v2.discogs+json';

class DiscogsApiClient {
  DiscogsApiClient({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  /// Fetches the authenticated user's Discogs identity.
  /// Suitable for checking whether a token is valid.
  Future<DiscogsIdentity> fetchIdentity(String token) async {
    final response = await _get('/oauth/identity', token);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DiscogsIdentity.fromJson(json);
  }

  Future<http.Response> _get(String path, String token) async {
    final uri = Uri.parse('$_baseUrl$path');
    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers(token));
    } on SocketException {
      throw const NetworkError();
    } on Exception {
      throw const NetworkError();
    }
    _checkStatus(response);
    return response;
  }

  Map<String, String> _headers(String token) => {
        'User-Agent': _userAgent,
        'Authorization': 'Discogs token=$token',
        'Accept': _accept,
      };

  void _checkStatus(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return;
      case 401:
      case 403:
        throw const InvalidTokenError();
      case 429:
        throw const RateLimitedError();
      default:
        if (response.statusCode >= 500) throw const DiscogsUnavailableError();
        throw UnexpectedApiError(response.statusCode);
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../shared/errors/app_error.dart';
import 'dto/discogs_collection_item.dart';
import 'dto/discogs_identity.dart';
import 'dto/discogs_release.dart';
import 'dto/discogs_search_result.dart';
import 'dto/discogs_wantlist_item.dart';

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

  /// Fetches full details for a Discogs release by its [id].
  Future<DiscogsReleaseDto> fetchRelease(int id, String token) async {
    final response = await _get('/releases/$id', token);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DiscogsReleaseDto.fromJson(json);
  }

  /// Searches Discogs releases by [query] text.
  Future<List<DiscogsSearchResultDto>> searchReleases(
    String query,
    String token,
  ) async {
    final response = await _get(
      '/database/search',
      token,
      queryParameters: {'q': query, 'type': 'release'},
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => DiscogsSearchResultDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches one page of the authenticated user's Discogs collection.
  ///
  /// [username] must be the Discogs username returned by [fetchIdentity].
  /// Use folder `0` to read all items across all folders.
  Future<DiscogsCollectionPageDto> fetchCollectionPage(
    String username,
    String token, {
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _get(
      '/users/$username/collection/folders/0/releases',
      token,
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DiscogsCollectionPageDto.fromJson(json);
  }

  /// Fetches one page of the authenticated user's Discogs wantlist.
  ///
  /// [username] must be the Discogs username returned by [fetchIdentity].
  Future<DiscogsWantlistPageDto> fetchWantlistPage(
    String username,
    String token, {
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _get(
      '/users/$username/wants',
      token,
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DiscogsWantlistPageDto.fromJson(json);
  }

  /// Searches Discogs releases by [barcode] identifier.
  Future<List<DiscogsSearchResultDto>> searchByBarcode(
    String barcode,
    String token,
  ) async {
    final response = await _get(
      '/database/search',
      token,
      queryParameters: {'barcode': barcode, 'type': 'release'},
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => DiscogsSearchResultDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adds [releaseId] to the authenticated user's Discogs collection folder 1.
  ///
  /// Folder 1 is the default "Uncategorized" folder. Returns normally on
  /// success (HTTP 201); throws an [AppError] subtype on failure.
  Future<void> addToCollection(
    String username,
    int releaseId,
    String token,
  ) async {
    await _post(
      '/users/$username/collection/folders/1/releases/$releaseId',
      token,
    );
  }

  Future<http.Response> _get(
    String path,
    String token, {
    Map<String, String>? queryParameters,
  }) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }
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

  Future<http.Response> _post(String path, String token) async {
    final uri = Uri.parse('$_baseUrl$path');
    final http.Response response;
    try {
      response = await _client.post(uri, headers: _headers(token));
    } on SocketException {
      throw const NetworkError();
    } on Exception {
      throw const NetworkError();
    }
    _checkStatus(response, 201);
    return response;
  }

  Map<String, String> _headers(String token) => {
        'User-Agent': _userAgent,
        'Authorization': 'Discogs token=$token',
        'Accept': _accept,
      };

  void _checkStatus(http.Response response, [int expectedStatus = 200]) {
    if (response.statusCode == expectedStatus) return;
    switch (response.statusCode) {
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

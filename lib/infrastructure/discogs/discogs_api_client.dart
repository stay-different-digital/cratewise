import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/models/search_filter.dart';
import '../../shared/errors/app_error.dart';
import 'dto/discogs_collection_item.dart';
import 'dto/discogs_identity.dart';
import 'dto/discogs_release.dart';
import 'dto/discogs_search_result.dart';
import 'dto/discogs_wantlist_item.dart';

const _baseUrl = 'https://api.discogs.com';
const _userAgent = 'Cratewise/1.0';
const _accept = 'application/vnd.discogs.v2.discogs+json';
const _kDefaultTimeout = Duration(seconds: 15);

/// Discogs rate-limit reset window. Requests per window is typically 60.
const _kRateLimitWindow = Duration(seconds: 60);

/// Delay the next request when remaining allowance is at or below this value.
const _kRateLimitThreshold = 0;

class DiscogsApiClient {
  DiscogsApiClient({
    http.Client? httpClient,
    Duration? requestTimeout,
    Future<void> Function(Duration)? delay,
  }) : _client = httpClient ?? http.Client(),
       _timeout = requestTimeout ?? _kDefaultTimeout,
       _delay = delay ?? ((d) => Future.delayed(d));

  final http.Client _client;
  final Duration _timeout;
  final Future<void> Function(Duration) _delay;

  void close() => _client.close();

  /// Set when the last response had remaining ≤ [_kRateLimitThreshold].
  /// Cleared at the start of [_waitIfNeeded] so only the very next request waits.
  DateTime? _nextAllowedAt;

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
  ///
  /// [page] is 1-based. [perPage] defaults to 50. [filter] scopes the match to
  /// a single field (US-85): `all` uses the general `q` parameter (default,
  /// matches every field); `release`/`artist`/`label` use the field-scoped
  /// `release_title`/`artist`/`label` parameters. `type=release` is always sent
  /// so the response shape is unchanged.
  Future<DiscogsSearchPageDto> searchReleases(
    String query,
    String token, {
    int page = 1,
    int perPage = 50,
    SearchFilter filter = SearchFilter.all,
  }) async {
    final textParam = switch (filter) {
      SearchFilter.all => 'q',
      SearchFilter.release => 'release_title',
      SearchFilter.artist => 'artist',
      SearchFilter.label => 'label',
    };
    final response = await _get(
      '/database/search',
      token,
      queryParameters: {
        textParam: query,
        'type': 'release',
        'page': '$page',
        'per_page': '$perPage',
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DiscogsSearchPageDto.fromJson(json);
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
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
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
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DiscogsWantlistPageDto.fromJson(json);
  }

  /// Searches Discogs releases by [barcode] identifier.
  ///
  /// [page] is 1-based. [perPage] defaults to 50.
  Future<DiscogsSearchPageDto> searchByBarcode(
    String barcode,
    String token, {
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _get(
      '/database/search',
      token,
      queryParameters: {
        'barcode': barcode,
        'type': 'release',
        'page': '$page',
        'per_page': '$perPage',
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DiscogsSearchPageDto.fromJson(json);
  }

  /// Adds [releaseId] to the authenticated user's Discogs collection folder 1.
  ///
  /// Folder 1 is the default "Uncategorized" folder. Returns the new
  /// collection *instance* id from the 201 response (needed to remove this
  /// specific entry later), or null if the response had no parseable id.
  /// Throws an [AppError] subtype on failure.
  Future<int?> addToCollection(
    String username,
    int releaseId,
    String token,
  ) async {
    final response = await _post(
      '/users/$username/collection/folders/1/releases/$releaseId',
      token,
    );
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['instance_id'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// Adds [releaseId] to the authenticated user's Discogs wantlist.
  ///
  /// The Discogs API requires PUT for this endpoint; POST returns 405.
  /// Returns normally on success (HTTP 201); throws an [AppError] subtype on failure.
  Future<void> addToWantlist(
    String username,
    int releaseId,
    String token,
  ) async {
    await _put('/users/$username/wants/$releaseId', token);
  }

  /// Removes a specific collection entry (by [instanceId]) from folder 1 of
  /// the authenticated user's Discogs collection.
  ///
  /// Returns normally on success (HTTP 204); throws an [AppError] subtype on
  /// failure.
  Future<void> removeFromCollection(
    String username,
    int releaseId,
    int instanceId,
    String token,
  ) async {
    await _delete(
      '/users/$username/collection/folders/1/releases/$releaseId/instances/$instanceId',
      token,
    );
  }

  /// Removes [releaseId] from the authenticated user's Discogs wantlist.
  ///
  /// Returns normally on success (HTTP 204); throws an [AppError] subtype on
  /// failure.
  Future<void> removeFromWantlist(
    String username,
    int releaseId,
    String token,
  ) async {
    await _delete('/users/$username/wants/$releaseId', token);
  }

  Future<http.Response> _get(
    String path,
    String token, {
    Map<String, String>? queryParameters,
  }) async {
    await _waitIfNeeded();
    var uri = Uri.parse('$_baseUrl$path');
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers(token))
          .timeout(_timeout);
    } on TimeoutException {
      throw const NetworkError();
    } on SocketException {
      throw const NetworkError();
    } on Exception {
      throw const NetworkError();
    }
    _checkStatus(response);
    _updateRateLimitState(response);
    return response;
  }

  Future<http.Response> _post(String path, String token) => _write(
    (uri, headers) => _client.post(uri, headers: headers),
    path,
    token,
  );

  Future<http.Response> _put(String path, String token) =>
      _write((uri, headers) => _client.put(uri, headers: headers), path, token);

  Future<http.Response> _delete(String path, String token) => _write(
    (uri, headers) => _client.delete(uri, headers: headers),
    path,
    token,
    expectedStatus: 204,
  );

  Future<http.Response> _write(
    Future<http.Response> Function(Uri uri, Map<String, String> headers) send,
    String path,
    String token, {
    int expectedStatus = 201,
  }) async {
    await _waitIfNeeded();
    final uri = Uri.parse('$_baseUrl$path');
    final http.Response response;
    try {
      response = await send(uri, _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw const NetworkError();
    } on SocketException {
      throw const NetworkError();
    } on Exception {
      throw const NetworkError();
    }
    _checkStatus(response, expectedStatus);
    _updateRateLimitState(response);
    return response;
  }

  /// Waits out any proactive rate-limit back-off before sending the next request.
  /// Clears [_nextAllowedAt] before awaiting so only one concurrent caller waits.
  Future<void> _waitIfNeeded() async {
    final until = _nextAllowedAt;
    if (until == null) return;
    _nextAllowedAt = null;
    final wait = until.difference(DateTime.now());
    if (wait > Duration.zero) await _delay(wait);
  }

  /// Reads [X-Discogs-Ratelimit-Remaining] from a successful response and
  /// schedules a back-off delay if the allowance is at or below the threshold.
  void _updateRateLimitState(http.Response response) {
    final raw = response.headers['x-discogs-ratelimit-remaining'];
    if (raw == null) return;
    final remaining = int.tryParse(raw);
    if (remaining != null && remaining <= _kRateLimitThreshold) {
      _nextAllowedAt = DateTime.now().add(_kRateLimitWindow);
    }
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

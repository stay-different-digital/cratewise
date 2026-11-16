import '../../domain/models/collection_item.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/token_storage.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/discogs/discogs_api_client.dart';
import '../../infrastructure/secure_storage/discogs_token_storage.dart';
import '../../infrastructure/secure_storage/secure_key_value_store.dart';
import '../../shared/errors/app_error.dart';

// Same 429 policy as the manual export use cases (ADR-0011).
const _kRateLimitRetryDelay = Duration(seconds: 60);
const _kMaxRateLimitRetries = 3;

/// Automatic sync with Discogs (US-144): the on/off setting, and sending a
/// newly added collection or wishlist item to the user's Discogs account.
///
/// Off by default — the app never writes to someone's Discogs account until
/// they turn this on. Sending never throws: the item is already saved locally,
/// and a failure only leaves it `offline`/`failed` for a later export.
class DiscogsAutoSyncService {
  DiscogsAutoSyncService({
    TokenStorage? tokenStorage,
    DiscogsApiClient? apiClient,
    SecureKeyValueStore? preferences,
    Future<void> Function(Duration)? delay,
  }) : _tokenStorage = tokenStorage ?? DiscogsTokenStorage(),
       _apiClient = apiClient ?? DiscogsApiClient.shared,
       _preferences = preferences ?? const FlutterSecureKeyValueStore(),
       _delay = delay ?? Future<void>.delayed;

  /// App-wide instance, sharing the API client's rate-limit back-off.
  static final shared = DiscogsAutoSyncService();

  static const _enabledKey = 'discogs_auto_sync';
  static const _revokedKey = 'discogs_auto_sync_revoked';

  final TokenStorage _tokenStorage;
  final DiscogsApiClient _apiClient;
  final SecureKeyValueStore _preferences;
  final Future<void> Function(Duration) _delay;

  Future<bool> isEnabled() => _readFlag(_enabledKey);

  /// True when Discogs rejected the token and auto-sync switched itself off;
  /// cleared when the user turns it on again.
  Future<bool> wasTurnedOffByDiscogs() => _readFlag(_revokedKey);

  Future<void> setEnabled(bool enabled) async {
    await _preferences.write(key: _enabledKey, value: '$enabled');
    if (enabled) await _preferences.delete(key: _revokedKey);
  }

  /// Sends [item] to the Discogs collection when auto-sync is on. A release
  /// already in the Discogs collection is linked, not added again — Discogs
  /// allows several copies, so a blind add would create a duplicate.
  Future<void> pushCollectionItem(
    CollectionItem item,
    CollectionRepository repository,
  ) async {
    final credentials = await _credentialsIfEnabled();
    if (credentials == null) return;
    final (:token, :username) = credentials;
    final status = await _send(() async {
      final existing = await _apiClient.fetchCollectionInstanceIds(
        username,
        item.discogsReleaseId,
        token,
      );
      final instanceId = existing.isNotEmpty
          ? existing.first
          : await _withRateLimitRetry(
              () => _apiClient.addToCollection(
                username,
                item.discogsReleaseId,
                token,
              ),
            );
      await _update(
        () => repository.getById(item.id),
        (current) => repository.update(
          current.copyWith(
            syncStatus: SyncStatus.synced,
            discogsInstanceId: instanceId,
            updatedAt: DateTime.now(),
          ),
        ),
      );
    });
    if (status != null) {
      await _update(
        () => repository.getById(item.id),
        (current) => repository.update(
          current.copyWith(syncStatus: status, updatedAt: DateTime.now()),
        ),
      );
    }
  }

  /// Sends [item] to the Discogs wantlist when auto-sync is on. Adding to the
  /// wantlist is idempotent on Discogs, so no duplicate check is needed.
  Future<void> pushWishlistItem(
    WishlistItem item,
    WishlistRepository repository,
  ) async {
    final credentials = await _credentialsIfEnabled();
    if (credentials == null) return;
    final (:token, :username) = credentials;
    final status = await _send(() async {
      await _withRateLimitRetry(
        () => _apiClient.addToWantlist(username, item.discogsReleaseId, token),
      );
      await _update(
        () => repository.getById(item.id),
        (current) => repository.update(
          current.copyWith(
            syncStatus: SyncStatus.synced,
            updatedAt: DateTime.now(),
          ),
        ),
      );
    });
    if (status != null) {
      await _update(
        () => repository.getById(item.id),
        (current) => repository.update(
          current.copyWith(syncStatus: status, updatedAt: DateTime.now()),
        ),
      );
    }
  }

  Future<({String token, String username})?> _credentialsIfEnabled() async {
    try {
      if (!await isEnabled()) return null;
      final token = await _tokenStorage.loadToken();
      final username = await _tokenStorage.loadUsername();
      if (token == null || token.isEmpty) return null;
      if (username == null || username.isEmpty) return null;
      return (token: token, username: username);
    } catch (e, st) {
      logSwallowed(e, st, 'DiscogsAutoSyncService');
      return null;
    }
  }

  /// Runs [send]; returns null on success, otherwise the status the item
  /// should get: `offline` when the device had no connection, else `failed`.
  Future<SyncStatus?> _send(Future<void> Function() send) async {
    try {
      await send();
      return null;
    } on InvalidTokenError catch (e) {
      // Discogs rejected the token: stop writing until the user reconnects
      // and turns auto-sync on again; Settings explains why it is off.
      await _tokenStorage.clearIfRevoked(e);
      try {
        await _preferences.write(key: _enabledKey, value: 'false');
        await _preferences.write(key: _revokedKey, value: 'true');
      } catch (e, st) {
        logSwallowed(e, st, 'DiscogsAutoSyncService');
      }
      return SyncStatus.failed;
    } on NetworkError {
      return SyncStatus.offline;
    } catch (e, st) {
      logSwallowed(e, st, 'DiscogsAutoSyncService');
      return SyncStatus.failed;
    }
  }

  Future<T> _withRateLimitRetry<T>(Future<T> Function() call) async {
    var attempts = 0;
    while (true) {
      try {
        return await call();
      } on RateLimitedError {
        if (attempts >= _kMaxRateLimitRetries) rethrow;
        attempts++;
        await _delay(_kRateLimitRetryDelay);
      }
    }
  }

  /// Re-reads the item before writing so a concurrent local edit (notes,
  /// condition) made while the request was in flight is not overwritten.
  Future<void> _update<T>(
    Future<T?> Function() load,
    Future<void> Function(T current) write,
  ) async {
    try {
      final current = await load();
      if (current != null) await write(current);
    } catch (e, st) {
      logSwallowed(e, st, 'DiscogsAutoSyncService');
    }
  }

  Future<bool> _readFlag(String key) async {
    try {
      return await _preferences.read(key: key) == 'true';
    } catch (e, st) {
      logSwallowed(e, st, 'DiscogsAutoSyncService');
      return false;
    }
  }
}

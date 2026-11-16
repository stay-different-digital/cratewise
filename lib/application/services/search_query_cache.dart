import '../../domain/models/search_filter.dart';
import '../../domain/models/search_result_page.dart';
import '../../domain/models/search_sort.dart';

/// In-memory LRU cache for search result pages.
///
/// Keyed by a normalised query string (see [normalizeKey]). Entries expire
/// after [ttl] and the cache holds at most [maxEntries] items (oldest
/// evicted first, with recency updated on every [get]).
class SearchQueryCache {
  SearchQueryCache({
    this._maxEntries = 20,
    this._ttl = const Duration(hours: 24),
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now());

  final int _maxEntries;
  final Duration _ttl;
  final DateTime Function() _clock;
  // Insertion-order map; reinserting on access gives LRU semantics.
  final _store = <String, _CacheEntry>{};

  /// Normalises a raw query to a stable cache key, scoped by [filter]
  /// (US-85), [sort] (US-133) and [vinylOnly] (US-142) so results for the same
  /// text under another scope, order or format never show up as a cache hit.
  /// Defaults to All / relevance / any format.
  static String normalizeKey(
    String query, [
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  ]) =>
      '${filter.name}:${sort.name}:${vinylOnly ? 'vinyl' : 'any'}:'
      '${query.trim().toLowerCase()}';

  /// Returns the cached page for [key], or `null` if absent or expired.
  SearchResultPage? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (_clock().isAfter(entry.expiresAt)) {
      _store.remove(key);
      return null;
    }
    // Move to end so this entry is the least-recently-evicted candidate.
    _store.remove(key);
    _store[key] = entry;
    return entry.page;
  }

  /// Stores [page] under [key], evicting the oldest entry if needed.
  void put(String key, SearchResultPage page) {
    _store.remove(key);
    _store[key] = _CacheEntry(page: page, expiresAt: _clock().add(_ttl));
    while (_store.length > _maxEntries) {
      _store.remove(_store.keys.first);
    }
  }
}

class _CacheEntry {
  const _CacheEntry({required this.page, required this.expiresAt});
  final SearchResultPage page;
  final DateTime expiresAt;
}

import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:cratewise/application/services/discogs_search_service.dart';
import 'package:cratewise/domain/models/release_detail.dart';
import 'package:cratewise/application/use_cases/add_to_collection_use_case.dart';
import 'package:cratewise/application/services/discogs_release_detail_service.dart';
import 'package:cratewise/application/services/search_query_cache.dart';
import 'package:cratewise/presentation/screens/release_detail_screen.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/domain/models/search_filter.dart';
import 'package:cratewise/domain/models/search_sort.dart';
import 'package:cratewise/domain/models/search_result_page.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/l10n/app_localizations.dart';
import 'package:cratewise/presentation/screens/search_screen.dart';
import 'package:cratewise/presentation/widgets/search_filter_sheet.dart';
import 'package:cratewise/presentation/widgets/release_search_result_card.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:cratewise/shared/route_observer.dart';
import 'package:cratewise/shared/tab_reselect_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cratewise/app/localization_delegates.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => null;
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

SearchResultPage _singlePage(List<ReleaseSearchResult> items) {
  return SearchResultPage(
    items: items,
    currentPage: 1,
    totalPages: 1,
    totalResults: items.length,
  );
}

class _FakeSearchService extends DiscogsSearchService {
  _FakeSearchService({this.results, this.throws})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final List<ReleaseSearchResult>? results;
  final AppError? throws;

  @override
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  }) async {
    if (throws != null) throw throws!;
    return _singlePage(results ?? []);
  }
}

class _CountingSearchService extends DiscogsSearchService {
  _CountingSearchService({required this.results})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final List<ReleaseSearchResult> results;
  int callCount = 0;

  @override
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  }) async {
    callCount++;
    return _singlePage(results);
  }
}

/// Records the filter (and page) of every search call so US-85 tests can assert
/// the filter is plumbed through and preserved across pagination.
class _DetailService extends DiscogsReleaseDetailService {
  _DetailService(this.detail)
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());
  final ReleaseDetail detail;

  @override
  Future<ReleaseDetail> fetchDetail(int _) async => detail;
}

class _RecordingSearchService extends DiscogsSearchService {
  _RecordingSearchService({required this.page1, required this.page2})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final List<ReleaseSearchResult> page1;
  final List<ReleaseSearchResult> page2;
  final List<SearchFilter> filters = [];
  final List<SearchSort> sorts = [];
  final List<bool> vinylOnlys = [];
  final List<int> pages = [];

  @override
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  }) async {
    filters.add(filter);
    sorts.add(sort);
    vinylOnlys.add(vinylOnly);
    pages.add(page);
    final items = page == 1 ? page1 : page2;
    // Only advertise a second page when one exists, so tests that don't want
    // the auto-prefetch of page 2 stay single-call.
    final totalPages = page2.isEmpty ? 1 : 2;
    return SearchResultPage(
      items: items,
      currentPage: page,
      totalPages: totalPages,
      totalResults: page1.length + page2.length,
    );
  }
}

class _FlippingSearchService extends DiscogsSearchService {
  _FlippingSearchService({required this.firstError, required this.results})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final AppError firstError;
  final List<ReleaseSearchResult> results;
  int _callCount = 0;

  @override
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  }) async {
    _callCount++;
    if (_callCount == 1) throw firstError;
    return _singlePage(results);
  }
}

class _DelayedSearchService extends DiscogsSearchService {
  _DelayedSearchService(this._completer)
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final Completer<SearchResultPage> _completer;

  @override
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  }) => _completer.future;
}

class _SequencedDelayedSearchService extends DiscogsSearchService {
  _SequencedDelayedSearchService(this._completers)
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final List<Completer<SearchResultPage>> _completers;
  int _callIndex = 0;

  @override
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  }) => _completers[_callIndex++].future;
}

/// Returns page 1 with [page1Items] (hasMore = true), then page 2 with
/// [page2Items] on subsequent calls.
class _PaginatingSearchService extends DiscogsSearchService {
  _PaginatingSearchService({required this.page1Items, required this.page2Items})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final List<ReleaseSearchResult> page1Items;
  final List<ReleaseSearchResult> page2Items;
  final AppError? page2Error = null;

  @override
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  }) async {
    if (page == 1) {
      return SearchResultPage(
        items: page1Items,
        currentPage: 1,
        totalPages: 2,
        totalResults: page1Items.length + page2Items.length,
      );
    }
    if (page2Error != null) throw page2Error!;
    return SearchResultPage(
      items: page2Items,
      currentPage: 2,
      totalPages: 2,
      totalResults: page1Items.length + page2Items.length,
    );
  }
}

// ---------------------------------------------------------------------------
// Membership fakes (US-80)
// ---------------------------------------------------------------------------

CollectionItem _collectionItem(int releaseId) => CollectionItem(
  id: 'c$releaseId',
  discogsReleaseId: releaseId,
  artist: 'Artist',
  title: 'Title',
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: const [],
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

WishlistItem _wishlistItem(int releaseId) => WishlistItem(
  id: 'w$releaseId',
  discogsReleaseId: releaseId,
  artist: 'Artist',
  title: 'Title',
  priority: WishlistPriority.medium,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

/// Fake collection repo whose membership ids can change between loads (to
/// exercise the refresh-on-return path) and that counts getAll calls.
class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeCollectionRepository({
    Set<int> ids = const {},
    this.throwOnGetAll = false,
  }) : ids = {...ids};

  Set<int> ids;
  final bool throwOnGetAll;
  int getAllCount = 0;

  @override
  Future<List<CollectionItem>> getAll() async {
    getAllCount++;
    if (throwOnGetAll) throw const StorageError();
    return ids.map(_collectionItem).toList();
  }

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      ids.contains(discogsReleaseId);

  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<void> add(CollectionItem item) async => ids.add(item.discogsReleaseId);
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeWishlistRepository({Set<int> ids = const {}, this.throwOnGetAll = false})
    : ids = {...ids};

  Set<int> ids;
  final bool throwOnGetAll;
  int getAllCount = 0;

  @override
  Future<List<WishlistItem>> getAll() async {
    getAllCount++;
    if (throwOnGetAll) throw const StorageError();
    return ids.map(_wishlistItem).toList();
  }

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      ids.contains(discogsReleaseId);

  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildScreen(
  DiscogsSearchService service, {
  SearchQueryCache? queryCache,
  CollectionRepository? collectionRepository,
  WishlistRepository? wishlistRepository,
}) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SearchScreen(
        searchService: service,
        queryCache: queryCache,
        collectionRepository: collectionRepository,
        wishlistRepository: wishlistRepository,
      ),
    ),
  );
}

Widget _buildScreenNl(DiscogsSearchService service) => MaterialApp(
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('nl'),
  home: Scaffold(body: SearchScreen(searchService: service)),
);

Widget _buildScreenWithRouter(DiscogsSearchService service) {
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      GoRoute(
        path: '/search',
        builder: (_, _) => Scaffold(body: SearchScreen(searchService: service)),
        routes: [
          GoRoute(
            path: 'release/:releaseId',
            builder: (_, state) => ReleaseDetailScreen(
              releaseId: int.parse(state.pathParameters['releaseId']!),
              initialArtist: state.uri.queryParameters['artist'],
              initialTitle: state.uri.queryParameters['title'],
            ),
          ),
        ],
      ),
    ],
  );
  return MaterialApp.router(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

const _kindOfBlue = ReleaseSearchResult(
  id: 249504,
  title: 'Kind Of Blue',
  artist: 'Miles Davis',
  format: 'Vinyl',
  label: 'Columbia',
  country: 'US',
  year: 1959,
);

const _abbeyRoad = ReleaseSearchResult(
  id: 14524953,
  title: 'Abbey Road',
  artist: 'The Beatles',
  format: 'LP',
  label: 'Apple Records',
  country: 'UK',
  year: 1969,
);

const _nevermind = ReleaseSearchResult(
  id: 555555,
  title: 'Nevermind',
  artist: 'Nirvana',
  format: 'Vinyl',
  label: 'DGC',
  country: 'US',
  year: 1991,
);

Future<void> submitSearch(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Filter sheet helpers (US-161 / US-162)
// ---------------------------------------------------------------------------

// pump + a fixed step instead of pumpAndSettle: a running search shows a
// spinner that never settles.
Future<void> _settleSheet(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// State of the open filter sheet.
SearchFilterSettings _openSheetState(WidgetTester tester) {
  bool chipOn(String key) =>
      tester.widget<ChoiceChip>(find.byKey(Key(key))).selected;
  final filter = [
    SearchFilter.release,
    SearchFilter.artist,
    SearchFilter.label,
  ].where((f) => chipOn('search-filter-chip-${f.name}')).firstOrNull;
  final sort = SearchSort.values.firstWhere(
    (s) => chipOn('sort-option-${s.name}'),
  );
  return SearchFilterSettings(
    filter: filter ?? SearchFilter.all,
    vinylOnly: tester
        .widget<SwitchListTile>(
          find.byKey(const Key('search-vinyl-only-switch')),
        )
        .value,
    sort: sort,
  );
}

/// Opens the filter sheet, sets the given options and taps Apply.
Future<void> applySearchFilters(
  WidgetTester tester, {
  SearchFilter? scope,
  bool? vinylOnly,
  SearchSort? sort,
}) async {
  await tester.tap(find.byKey(const Key('search-filter-button')));
  await _settleSheet(tester);
  final now = _openSheetState(tester);
  if (sort != null && sort != now.sort) {
    await tester.tap(find.byKey(Key('sort-option-${sort.name}')));
    await tester.pump();
  }
  if (scope != null && scope != now.filter) {
    // Tapping the active scope chip clears it back to "everything".
    final target = scope == SearchFilter.all ? now.filter : scope;
    await tester.tap(find.byKey(Key('search-filter-chip-${target.name}')));
    await tester.pump();
  }
  if (vinylOnly != null && vinylOnly != now.vinylOnly) {
    await tester.tap(find.byKey(const Key('search-vinyl-only-switch')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('apply-filter-button')));
  await _settleSheet(tester);
}

/// Opens the filter sheet, reads its state and closes it without applying.
Future<SearchFilterSettings> readSearchFilters(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('search-filter-button')));
  await _settleSheet(tester);
  final state = _openSheetState(tester);
  Navigator.of(tester.element(find.byType(SearchFilterSheet))).pop();
  await _settleSheet(tester);
  return state;
}

int _badgeCount(WidgetTester tester) {
  final badge = tester.widget<Badge>(
    find.descendant(
      of: find.byKey(const Key('search-filter-button')),
      matching: find.byType(Badge),
    ),
  );
  return badge.isLabelVisible ? int.parse((badge.label! as Text).data!) : 0;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SearchScreen empty state', () {
    testWidgets('shows heading and prompt when query is empty', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      expect(find.text('Search Discogs'), findsOneWidget);
      expect(find.textContaining('Type an artist'), findsOneWidget);
    });

    testWidgets('shows search icons when query is empty', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      // Both the TextField prefix and the empty-state illustration use Icons.search.
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('does not show result cards when query is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('shows empty state with text entered but before submitting', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Search Discogs'), findsOneWidget);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
      // drain debounce timer so the test exits cleanly
      await tester.pumpAndSettle();
    });
  });

  group('SearchScreen search', () {
    testWidgets('shows loading indicator while search is in progress', (
      tester,
    ) async {
      final completer = Completer<SearchResultPage>();
      await tester.pumpWidget(_buildScreen(_DelayedSearchService(completer)));

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_singlePage([_kindOfBlue]));
      await tester.pumpAndSettle();
    });

    testWidgets('shows result cards after successful search', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue, _abbeyRoad]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'vinyl');
      expect(find.byType(ReleaseSearchResultCard), findsNWidgets(2));
    });

    testWidgets('hides empty state after successful search', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.text('Search Discogs'), findsNothing);
    });

    testWidgets('result card shows artist name', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('result card shows title', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.text('Kind Of Blue'), findsOneWidget);
    });

    testWidgets('result card shows label · year · format meta row', (
      tester,
    ) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.text('Columbia · 1959 · Vinyl'), findsOneWidget);
    });

    testWidgets('result card shows country on a separate row', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.text('US'), findsOneWidget);
    });

    testWidgets('result card shows Discogs release ID', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.text('#249504'), findsOneWidget);
    });

    testWidgets('result card shows cover placeholder icon when no coverUrl', (
      tester,
    ) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.byIcon(Icons.album), findsWidgets);
    });

    testWidgets('shows no-results message when search returns empty', (
      tester,
    ) async {
      final service = _FakeSearchService(results: []);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'xyzzy');
      expect(find.text('No results'), findsOneWidget);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('shows no-token message when no token is saved', (
      tester,
    ) async {
      final service = _FakeSearchService(throws: const NoTokenError());
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(
        find.textContaining('Connect a Discogs token in Settings'),
        findsOneWidget,
      );
    });

    testWidgets('shows network error message on network failure', (
      tester,
    ) async {
      final service = _FakeSearchService(throws: const NetworkError());
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.textContaining('No internet'), findsOneWidget);
    });

    testWidgets('shows rate limit message when rate limited', (tester) async {
      final service = _FakeSearchService(throws: const RateLimitedError());
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.textContaining('Too many requests'), findsOneWidget);
    });

    testWidgets(
      'shows countdown Retry button when search returns rate limit error',
      (tester) async {
        final service = _FakeSearchService(throws: const RateLimitedError());
        await tester.pumpWidget(_buildScreen(service));
        await submitSearch(tester, 'miles');
        // No fake time advance — countdown has not fired yet.
        expect(find.textContaining('Retry in'), findsOneWidget);
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'shows active Retry button when search returns non-rate-limit error',
      (tester) async {
        final service = _FakeSearchService(throws: const NetworkError());
        await tester.pumpWidget(_buildScreen(service));
        await submitSearch(tester, 'miles');
        expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets('shows invalid token message on 401 error', (tester) async {
      final service = _FakeSearchService(throws: const InvalidTokenError());
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.textContaining('not valid'), findsOneWidget);
    });
  });

  group('SearchScreen result count', () {
    testWidgets('shows result count when results are present', (tester) async {
      // _singlePage: totalPages=1 → hasMore=false → no auto-pagination
      final service = _FakeSearchService(results: [_kindOfBlue, _abbeyRoad]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'vinyl');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('result-count')), findsOneWidget);
      expect(find.textContaining('1–2 of 2'), findsOneWidget);
    });

    testWidgets('count reflects all loaded items after auto-pagination', (
      tester,
    ) async {
      // The post-frame trigger auto-loads page 2 because page 1 fits in view.
      final service = _PaginatingSearchService(
        page1Items: [_kindOfBlue],
        page2Items: [_abbeyRoad, _nevermind],
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'vinyl');
      await tester.pumpAndSettle();
      expect(find.textContaining('1–3 of 3'), findsOneWidget);
    });
  });

  group('SearchScreen pagination', () {
    testWidgets('shows pagination loading indicator when loading more', (
      tester,
    ) async {
      final completer = Completer<SearchResultPage>();

      // Page 2 blocks; the post-frame trigger fires _loadMore automatically.
      final service = _BlockingPaginationService(
        page1Items: [_kindOfBlue],
        page2Completer: completer,
      );

      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'vinyl');
      // One more pump fires the post-frame callback → isLoadingMore=true
      await tester.pump();

      expect(find.byKey(const Key('pagination-loading')), findsOneWidget);

      completer.complete(_singlePage([_abbeyRoad]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pagination-loading')), findsNothing);
      expect(find.byType(ReleaseSearchResultCard), findsNWidgets(2));
    });

    testWidgets(
      'shows inline countdown retry button when page 2 returns rate-limit error',
      (tester) async {
        // The post-frame trigger fires _loadMore → RateLimitedError → countdown shown.
        final service = _BlockingPaginationService(
          page1Items: [_kindOfBlue],
          page2Error: const RateLimitedError(),
        );

        await tester.pumpWidget(_buildScreen(service));
        await submitSearch(tester, 'vinyl');
        // Limited pumps: process page-2 error without advancing fake time so the
        // 60-second countdown has not elapsed.
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const Key('pagination-retry')), findsOneWidget);
        expect(find.textContaining('Retry in'), findsOneWidget);
        // Original page 1 results still visible
        expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
      },
    );

    testWidgets(
      'page 1 results remain visible after rate-limit pagination error',
      (tester) async {
        final service = _BlockingPaginationService(
          page1Items: [_kindOfBlue, _abbeyRoad],
          page2Error: const RateLimitedError(),
        );
        await tester.pumpWidget(_buildScreen(service));
        await submitSearch(tester, 'vinyl');
        await tester.pump();
        await tester.pump();

        expect(find.byType(ReleaseSearchResultCard), findsNWidgets(2));
        expect(find.byKey(const Key('pagination-retry')), findsOneWidget);
      },
    );
  });

  group('SearchScreen clear', () {
    testWidgets('clear button appears when query is entered', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      expect(find.byTooltip('Clear search'), findsNothing);
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsOneWidget);
      // drain debounce timer so the test exits cleanly
      await tester.pumpAndSettle();
    });

    testWidgets('tapping clear shows empty state', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.text('Search Discogs'), findsOneWidget);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('tapping clear after results shows empty state', (
      tester,
    ) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.text('Search Discogs'), findsOneWidget);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('clear button disappears after clearing', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });

  group('SearchScreen debounce', () {
    testWidgets('does not search before debounce delay elapses', (
      tester,
    ) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);

      // drain timer
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    });

    testWidgets('searches automatically after debounce delay', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(const Duration(milliseconds: 200)); // before timer
      expect(find.byType(ReleaseSearchResultCard), findsNothing);

      await tester.pump(const Duration(milliseconds: 200)); // fires at 300ms
      await tester.pumpAndSettle();
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
    });

    testWidgets('resets debounce when query changes mid-wait', (tester) async {
      final service = _CountingSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));

      await tester.enterText(find.byType(TextField), 'mil');
      await tester.pump(const Duration(milliseconds: 200));
      // change query before timer fires — resets the 300ms window
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(const Duration(milliseconds: 200));
      // 400ms elapsed but the second timer is only at 200ms — no search yet
      expect(service.callCount, 0);

      await tester.pump(
        const Duration(milliseconds: 200),
      ); // second timer fires
      await tester.pumpAndSettle();
      expect(service.callCount, 1); // only one search, for the final query
    });

    testWidgets('clearing text cancels pending debounce', (tester) async {
      final service = _CountingSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(service.callCount, 0);
      expect(find.text('Search Discogs'), findsOneWidget);
    });
  });

  group('SearchScreen dedup', () {
    testWidgets('does not fire a duplicate request when results are showing', (
      tester,
    ) async {
      final service = _CountingSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));

      await submitSearch(tester, 'miles');
      expect(service.callCount, 1);
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);

      await submitSearch(tester, 'miles'); // same query, results already shown
      expect(service.callCount, 1);
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
    });

    testWidgets('allows retry after an error for the same query', (
      tester,
    ) async {
      final service = _FlippingSearchService(
        firstError: const NetworkError(),
        results: [_kindOfBlue],
      );
      await tester.pumpWidget(_buildScreen(service));

      await submitSearch(tester, 'miles'); // first call: throws NetworkError
      expect(find.textContaining('No internet'), findsOneWidget);

      // state is _SearchError → dedup allows same query to retry
      await submitSearch(tester, 'miles'); // second call: returns results
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
    });

    testWidgets('fires again after clearing and retyping same query', (
      tester,
    ) async {
      final service = _CountingSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));

      await submitSearch(tester, 'miles');
      expect(service.callCount, 1);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      await submitSearch(tester, 'miles'); // same query, but cleared first
      expect(service.callCount, 2);
    });
  });

  group('SearchScreen navigation', () {
    testWidgets('tapping a result card opens release detail screen', (
      tester,
    ) async {
      // Default test surface is 800×600 dp (wide layout) — result is shown
      // inline in the right pane rather than pushed as a new route.
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');

      await tester.tap(find.byType(ReleaseSearchResultCard).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReleaseDetailScreen), findsOneWidget);
      expect(find.byKey(const Key('release-detail-loading')), findsOneWidget);
    });

    testWidgets(
      'on narrow layout, back from detail screen returns to results',
      (tester) async {
        // Force narrow viewport (< 700 dp) so tapping uses context.push.
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final service = _FakeSearchService(results: [_kindOfBlue]);
        await tester.pumpWidget(_buildScreenWithRouter(service));
        await submitSearch(tester, 'miles');

        await tester.tap(find.byType(ReleaseSearchResultCard).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ReleaseDetailScreen), findsOneWidget);

        await tester.pageBack();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ReleaseDetailScreen), findsNothing);
        expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
      },
    );
  });

  group('SearchScreen wide layout', () {
    testWidgets('shows no-selection placeholder before any result is tapped', (
      tester,
    ) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');

      expect(find.text('Select a result'), findsOneWidget);
      expect(find.byType(ReleaseDetailScreen), findsNothing);
    });

    testWidgets('shows placeholder when query is empty', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      expect(find.text('Select a result'), findsOneWidget);
    });

    testWidgets(
      'tapping a result shows its details in the right pane without pushing a route',
      (tester) async {
        final service = _FakeSearchService(results: [_kindOfBlue]);
        await tester.pumpWidget(_buildScreen(service));
        await submitSearch(tester, 'miles');

        await tester.tap(find.byType(ReleaseSearchResultCard).first);
        await tester.pump();

        // Detail is embedded — no Navigator route was pushed, no Back button.
        expect(find.byType(ReleaseDetailScreen), findsOneWidget);
        expect(find.text('Select a result'), findsNothing);
        // ReleaseDetailScreen AppBar title reflects the tapped result.
        expect(find.text('Miles Davis — Kind Of Blue'), findsOneWidget);
      },
    );

    testWidgets('selecting a different result updates the detail pane', (
      tester,
    ) async {
      final service = _FakeSearchService(results: [_kindOfBlue, _abbeyRoad]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'vinyl');

      // Tap first result.
      await tester.tap(find.byType(ReleaseSearchResultCard).first);
      await tester.pump();
      expect(find.text('Miles Davis — Kind Of Blue'), findsOneWidget);

      // Tap second result.
      await tester.tap(find.byType(ReleaseSearchResultCard).at(1));
      await tester.pump();
      expect(find.text('The Beatles — Abbey Road'), findsOneWidget);
      expect(find.text('Miles Davis — Kind Of Blue'), findsNothing);
    });

    testWidgets('clearing search clears the detail pane', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');

      await tester.tap(find.byType(ReleaseSearchResultCard).first);
      await tester.pump();
      expect(find.byType(ReleaseDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.byType(ReleaseDetailScreen), findsNothing);
      expect(find.text('Select a result'), findsOneWidget);
    });

    testWidgets('new search clears the detail pane', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');

      await tester.tap(find.byType(ReleaseSearchResultCard).first);
      await tester.pump();
      expect(find.byType(ReleaseDetailScreen), findsOneWidget);

      await submitSearch(tester, 'beatles');

      // While loading the new search, detail pane is cleared.
      expect(find.byType(ReleaseDetailScreen), findsNothing);
      expect(find.text('Select a result'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('SearchScreen security', () {
    testWidgets('token value is not visible in any rendered Text widget', (
      tester,
    ) async {
      const sensitiveToken = 'super_secret_token_xyz_123';
      final service = _FakeSearchService(throws: const InvalidTokenError());
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      final tokenInText = tester
          .widgetList<Text>(find.byType(Text))
          .where((w) => w.data?.contains(sensitiveToken) == true);
      expect(tokenInText, isEmpty);
    });
  });

  group('SearchScreen — search caching', () {
    testWidgets(
      'cache hit shows results immediately without a loading indicator',
      (tester) async {
        // Pre-populate cache with a "miles" result.
        final cache = SearchQueryCache();
        cache.put(
          SearchQueryCache.normalizeKey('miles'),
          _singlePage([_kindOfBlue]),
        );

        // The service blocks forever — it should NOT be awaited before results
        // are shown.
        final c = Completer<SearchResultPage>();
        final service = _DelayedSearchService(c);
        await tester.pumpWidget(_buildScreen(service, queryCache: cache));

        await submitSearch(tester, 'miles');

        // Cached result visible immediately, no spinner.
        expect(find.text('Kind Of Blue'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byKey(const Key('cached-results-banner')), findsOneWidget);

        // Complete the background refresh with different data.
        c.complete(_singlePage([_abbeyRoad]));
        await tester.pumpAndSettle();

        // Fresh result replaces the cached one; banner disappears.
        expect(find.text('Abbey Road'), findsOneWidget);
        expect(find.text('Kind Of Blue'), findsNothing);
        expect(find.byKey(const Key('cached-results-banner')), findsNothing);
      },
    );

    testWidgets(
      'banner persists when background refresh fails with a network error',
      (tester) async {
        final cache = SearchQueryCache();
        cache.put(
          SearchQueryCache.normalizeKey('miles'),
          _singlePage([_kindOfBlue]),
        );

        final service = _FakeSearchService(throws: const NetworkError());
        await tester.pumpWidget(_buildScreen(service, queryCache: cache));

        await submitSearch(tester, 'miles');
        await tester.pumpAndSettle();

        // Cached result and banner remain; no error state shown.
        expect(find.byKey(const Key('cached-results-banner')), findsOneWidget);
        expect(find.text('Kind Of Blue'), findsOneWidget);
        expect(find.textContaining('No internet'), findsNothing);
      },
    );

    testWidgets(
      'no-cache path still shows loading indicator then fresh results',
      (tester) async {
        // Empty cache — normal flow should be unchanged.
        final service = _FakeSearchService(results: [_abbeyRoad]);
        await tester.pumpWidget(_buildScreen(service));

        await submitSearch(tester, 'beatles');

        expect(find.text('Abbey Road'), findsOneWidget);
        expect(find.byKey(const Key('cached-results-banner')), findsNothing);
      },
    );
  });

  group('SearchScreen — in-flight cancellation', () {
    testWidgets('stale result is discarded when a new query fires mid-flight', (
      tester,
    ) async {
      final c1 = Completer<SearchResultPage>();
      final c2 = Completer<SearchResultPage>();
      final service = _SequencedDelayedSearchService([c1, c2]);
      await tester.pumpWidget(_buildScreen(service));

      await submitSearch(tester, 'miles');
      await submitSearch(tester, 'beatles');

      // First (stale) request completes — result must be silently discarded.
      c1.complete(_singlePage([_kindOfBlue]));
      await tester.pump();
      expect(find.text('Kind Of Blue'), findsNothing);

      // Second (current) request completes — result must be shown.
      c2.complete(_singlePage([_abbeyRoad]));
      await tester.pumpAndSettle();
      expect(find.text('Abbey Road'), findsOneWidget);
    });

    testWidgets('stale error is discarded when a new query fires mid-flight', (
      tester,
    ) async {
      final c1 = Completer<SearchResultPage>();
      final c2 = Completer<SearchResultPage>();
      final service = _SequencedDelayedSearchService([c1, c2]);
      await tester.pumpWidget(_buildScreen(service));

      await submitSearch(tester, 'miles');
      await submitSearch(tester, 'beatles');

      // First (stale) request errors — error state must NOT be shown.
      c1.completeError(const NetworkError());
      await tester.pump();
      expect(find.textContaining('No internet'), findsNothing);

      // Second (current) request completes — result must be shown.
      c2.complete(_singlePage([_abbeyRoad]));
      await tester.pumpAndSettle();
      expect(find.text('Abbey Road'), findsOneWidget);
    });
  });

  // Regression for US-55: an unexpected glyph was observed at the right end of
  // the search bar in dark mode with no query entered (finding #4). The suffix
  // is driven entirely by Flutter code (null when empty, clear IconButton when
  // hasQuery). These tests confirm no suffix icon leaks in through the widget
  // tree in either theme — ruling out the Flutter layer as the source.
  group('SearchScreen — search bar suffix icon (US-55)', () {
    InputDecoration searchBarDecoration(WidgetTester tester) {
      final tf = tester.widget<TextField>(find.byType(TextField));
      return tf.decoration!;
    }

    testWidgets('no suffix icon in light mode with empty query', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          home: Scaffold(
            body: SearchScreen(searchService: _FakeSearchService()),
          ),
        ),
      );
      await tester.pump();

      expect(searchBarDecoration(tester).suffixIcon, isNull);
    });

    testWidgets('no suffix icon in dark mode with empty query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: Scaffold(
            body: SearchScreen(searchService: _FakeSearchService()),
          ),
        ),
      );
      await tester.pump();

      expect(searchBarDecoration(tester).suffixIcon, isNull);
    });

    testWidgets('clear IconButton appears in dark mode once query is entered', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: Scaffold(
            body: SearchScreen(searchService: _FakeSearchService()),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump();

      expect(searchBarDecoration(tester).suffixIcon, isNotNull);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });

  group('SearchScreen membership icons (US-80)', () {
    testWidgets('shows the collection icon for a release already collected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          _FakeSearchService(results: [_kindOfBlue, _abbeyRoad]),
          collectionRepository: _FakeCollectionRepository(
            ids: {_kindOfBlue.id},
          ),
          wishlistRepository: _FakeWishlistRepository(),
        ),
      );
      await submitSearch(tester, 'vinyl');

      expect(find.byKey(const Key('in-collection-icon')), findsOneWidget);
      expect(find.byKey(const Key('on-wishlist-icon')), findsNothing);
    });

    testWidgets('shows the wishlist icon for a release already wishlisted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          _FakeSearchService(results: [_kindOfBlue]),
          collectionRepository: _FakeCollectionRepository(),
          wishlistRepository: _FakeWishlistRepository(ids: {_kindOfBlue.id}),
        ),
      );
      await submitSearch(tester, 'vinyl');

      expect(find.byKey(const Key('on-wishlist-icon')), findsOneWidget);
      expect(find.byKey(const Key('in-collection-icon')), findsNothing);
    });

    testWidgets('shows both icons when a release is collected and wishlisted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          _FakeSearchService(results: [_kindOfBlue]),
          collectionRepository: _FakeCollectionRepository(
            ids: {_kindOfBlue.id},
          ),
          wishlistRepository: _FakeWishlistRepository(ids: {_kindOfBlue.id}),
        ),
      );
      await submitSearch(tester, 'vinyl');

      expect(find.byKey(const Key('in-collection-icon')), findsOneWidget);
      expect(find.byKey(const Key('on-wishlist-icon')), findsOneWidget);
    });

    testWidgets('shows no membership icons for an unknown release', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          _FakeSearchService(results: [_kindOfBlue]),
          collectionRepository: _FakeCollectionRepository(),
          wishlistRepository: _FakeWishlistRepository(),
        ),
      );
      await submitSearch(tester, 'vinyl');

      expect(find.byKey(const Key('in-collection-icon')), findsNothing);
      expect(find.byKey(const Key('on-wishlist-icon')), findsNothing);
    });

    testWidgets('resolves membership once per result set, not per card', (
      tester,
    ) async {
      final collection = _FakeCollectionRepository(ids: {_kindOfBlue.id});
      final wishlist = _FakeWishlistRepository();
      await tester.pumpWidget(
        _buildScreen(
          _FakeSearchService(results: [_kindOfBlue, _abbeyRoad, _nevermind]),
          collectionRepository: collection,
          wishlistRepository: wishlist,
        ),
      );
      await submitSearch(tester, 'vinyl');
      await tester.pumpAndSettle();

      expect(find.byType(ReleaseSearchResultCard), findsNWidgets(3));
      // One load on init — not one per card, and the result set did not
      // trigger additional loads.
      expect(collection.getAllCount, 1);
      expect(wishlist.getAllCount, 1);
    });

    testWidgets('degrades to no icons when membership storage fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          _FakeSearchService(results: [_kindOfBlue]),
          collectionRepository: _FakeCollectionRepository(throwOnGetAll: true),
          wishlistRepository: _FakeWishlistRepository(throwOnGetAll: true),
        ),
      );
      await submitSearch(tester, 'vinyl');

      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
      expect(find.byKey(const Key('in-collection-icon')), findsNothing);
      expect(find.byKey(const Key('on-wishlist-icon')), findsNothing);
    });

    testWidgets('re-resolves membership when returning from a detail screen', (
      tester,
    ) async {
      // Force the narrow layout so tapping a result pushes a detail route
      // (the wide layout shows an inline detail pane and never pops).
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final collection = _FakeCollectionRepository();
      final wishlist = _FakeWishlistRepository();
      final router = GoRouter(
        initialLocation: '/search',
        observers: [searchRouteObserver],
        routes: [
          GoRoute(
            path: '/search',
            builder: (_, _) => Scaffold(
              body: SearchScreen(
                searchService: _FakeSearchService(results: [_kindOfBlue]),
                collectionRepository: collection,
                wishlistRepository: wishlist,
              ),
            ),
            routes: [
              GoRoute(
                path: 'release/:releaseId',
                builder: (context, _) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('back'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await submitSearch(tester, 'vinyl');
      expect(find.byKey(const Key('in-collection-icon')), findsNothing);

      // Open the detail screen, "add" the release while away, then return.
      await tester.tap(find.byType(ReleaseSearchResultCard));
      await tester.pumpAndSettle();
      collection.ids = {_kindOfBlue.id};
      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('in-collection-icon')), findsOneWidget);
    });
  });

  group('SearchScreen — filter button and sheet (US-161)', () {
    testWidgets('one filter button, no chip row or sort menu on the screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService(results: [])));
      await tester.pump();

      expect(find.byKey(const Key('search-filter-button')), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byKey(const Key('search-sort-button')), findsNothing);
      expect(_badgeCount(tester), 0);
    });

    testWidgets('the sheet offers scope, vinyl only and sort; defaults', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService(results: [])));
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-filter-button')));
      await _settleSheet(tester);

      expect(find.text('Release'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
      expect(find.text('Label'), findsOneWidget);
      expect(find.text('Vinyl only'), findsOneWidget);
      final state = _openSheetState(tester);
      expect(state.filter, SearchFilter.all);
      expect(state.vinylOnly, isFalse);
      expect(state.sort, SearchSort.relevance);
    });

    testWidgets('one scope at a time; tapping the active one returns to All', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService(results: [])));
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-filter-button')));
      await _settleSheet(tester);

      await tester.tap(find.byKey(const Key('search-filter-chip-artist')));
      await tester.pump();
      expect(_openSheetState(tester).filter, SearchFilter.artist);
      await tester.tap(find.byKey(const Key('search-filter-chip-label')));
      await tester.pump();
      expect(_openSheetState(tester).filter, SearchFilter.label);
      await tester.tap(find.byKey(const Key('search-filter-chip-label')));
      await tester.pump();
      expect(_openSheetState(tester).filter, SearchFilter.all);
    });

    testWidgets('Apply updates the badge; closing without Apply changes '
        'nothing', (tester) async {
      final service = _CountingSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await tester.pump();

      // Choose a scope but close the sheet without applying.
      await tester.tap(find.byKey(const Key('search-filter-button')));
      await _settleSheet(tester);
      await tester.tap(find.byKey(const Key('search-filter-chip-artist')));
      Navigator.of(tester.element(find.byType(SearchFilterSheet))).pop();
      await _settleSheet(tester);
      expect(_badgeCount(tester), 0);
      expect((await readSearchFilters(tester)).filter, SearchFilter.all);

      await applySearchFilters(tester, scope: SearchFilter.artist);
      expect(_badgeCount(tester), 1);
      // An empty search box runs no search.
      expect(service.callCount, 0);
    });

    testWidgets('Clear all resets scope, vinyl only and sort', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService(results: [])));
      await tester.pump();
      await applySearchFilters(
        tester,
        scope: SearchFilter.label,
        vinylOnly: true,
        sort: SearchSort.oldestFirst,
      );
      expect(_badgeCount(tester), 3);

      await tester.tap(find.byKey(const Key('search-filter-button')));
      await _settleSheet(tester);
      await tester.tap(find.byKey(const Key('clear-all-button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('apply-filter-button')));
      await _settleSheet(tester);

      expect(_badgeCount(tester), 0);
    });

    testWidgets('fits the narrow phone layout', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildScreen(_FakeSearchService(results: [])));
      await tester.pump();

      await tester.tap(find.byKey(const Key('search-filter-button')));
      await _settleSheet(tester);
      expect(find.byKey(const Key('apply-filter-button')), findsOneWidget);
    });
  });

  group('SearchScreen — filter scoping (US-85)', () {
    testWidgets('the initial search runs under the All filter by default', (
      tester,
    ) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'blue');

      expect(service.filters, [SearchFilter.all]);
    });

    testWidgets(
      'applying another scope re-issues the search under the new filter',
      (tester) async {
        final service = _RecordingSearchService(
          page1: [_kindOfBlue],
          page2: const [],
        );
        await tester.pumpWidget(_buildScreen(service));
        await submitSearch(tester, 'blue');
        expect(service.filters, [SearchFilter.all]);

        await applySearchFilters(tester, scope: SearchFilter.artist);
        await tester.pumpAndSettle();

        // A second call was made, scoped to Artist, with the same text.
        expect(service.filters, [SearchFilter.all, SearchFilter.artist]);
      },
    );

    testWidgets('pagination preserves the originating filter', (tester) async {
      // page2 is non-empty, so _ResultsList auto-prefetches page 2 (the first
      // page fits the viewport). Each search therefore fetches page 1 then
      // page 2 under the same filter.
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: [_abbeyRoad],
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'blue');
      await tester.pumpAndSettle();

      // Page 1 + auto-prefetched page 2, both under All.
      expect(service.pages, contains(2));
      final firstPage2 = service.pages.indexOf(2);
      expect(service.filters[firstPage2], SearchFilter.all);

      // Switch to Artist — re-runs page 1, then page 2 is prefetched again,
      // still scoped to Artist.
      await applySearchFilters(tester, scope: SearchFilter.artist);
      await tester.pumpAndSettle();

      expect(service.pages.last, 2);
      expect(service.filters.last, SearchFilter.artist);
    });

    testWidgets('an All search and an Artist search for the same text do not '
        'collide in the cache', (tester) async {
      final cache = SearchQueryCache();
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service, queryCache: cache));
      await submitSearch(tester, 'blue');
      await applySearchFilters(tester, scope: SearchFilter.artist);
      await tester.pumpAndSettle();

      // Distinct cache keys were written for the two scopes.
      expect(cache.get(SearchQueryCache.normalizeKey('blue')), isNotNull);
      expect(
        cache.get(SearchQueryCache.normalizeKey('blue', SearchFilter.artist)),
        isNotNull,
      );
    });
  });

  group('SearchScreen easter egg — shake (US-109)', () {
    Widget buildWithShake(Stream<AccelerometerEvent> stream) {
      final router = GoRouter(
        initialLocation: '/search',
        routes: [
          GoRoute(
            path: '/search',
            builder: (_, _) => Scaffold(
              body: SearchScreen(
                searchService: _FakeSearchService(),
                accelerometerStream: stream,
              ),
            ),
            routes: [
              GoRoute(
                path: 'release/:releaseId',
                builder: (_, state) => ReleaseDetailScreen(
                  releaseId: int.parse(state.pathParameters['releaseId']!),
                  initialArtist: state.uri.queryParameters['artist'],
                  initialTitle: state.uri.queryParameters['title'],
                ),
              ),
            ],
          ),
        ],
      );
      return MaterialApp.router(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      );
    }

    testWidgets(
      'shake above threshold navigates to Rick Astley release 1758356',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ctrl = StreamController<AccelerometerEvent>(sync: true);
        addTearDown(ctrl.close);

        await tester.pumpWidget(buildWithShake(ctrl.stream));
        await tester.pump();

        ctrl.add(AccelerometerEvent(25.0, 0.0, 0.0, DateTime.now()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ReleaseDetailScreen), findsOneWidget);
        final screen = tester.widget<ReleaseDetailScreen>(
          find.byType(ReleaseDetailScreen),
        );
        expect(screen.releaseId, 1758356);
      },
    );

    testWidgets('shake below threshold does not navigate', (tester) async {
      final ctrl = StreamController<AccelerometerEvent>(sync: true);
      addTearDown(ctrl.close);

      await tester.pumpWidget(buildWithShake(ctrl.stream));
      await tester.pump();

      ctrl.add(AccelerometerEvent(5.0, 0.0, 0.0, DateTime.now()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReleaseDetailScreen), findsNothing);
    });
  });

  group('SearchScreen — NL locale (US-113)', () {
    testWidgets('shows Dutch labels when locale is nl', (tester) async {
      await tester.pumpWidget(_buildScreenNl(_FakeSearchService()));
      await tester.pump();

      expect(find.text('Zoek op Discogs'), findsOneWidget);
    });
  });

  group('SearchScreen — vinyl only (US-142)', () {
    Future<bool> isOn(WidgetTester tester) async =>
        (await readSearchFilters(tester)).vinylOnly;

    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    testWidgets('is off by default and searches all formats', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await tester.pumpAndSettle();
      await submitSearch(tester, 'blue note');

      expect(await isOn(tester), isFalse);
      expect(service.vinylOnlys, [false]);
    });

    testWidgets('toggling re-runs the search from page 1 with the filter', (
      tester,
    ) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await tester.pumpAndSettle();
      await submitSearch(tester, 'blue note');

      await applySearchFilters(tester, vinylOnly: true);
      await tester.pumpAndSettle();

      expect(service.vinylOnlys, [false, true]);
      expect(await isOn(tester), isTrue);
      expect(service.pages.last, 1);
    });

    testWidgets('combines with a scope; pagination keeps it', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: [_abbeyRoad],
      );
      await tester.pumpWidget(_buildScreen(service));
      await tester.pumpAndSettle();
      await applySearchFilters(
        tester,
        scope: SearchFilter.label,
        vinylOnly: true,
      );
      await submitSearch(tester, 'blue note');
      await tester.pumpAndSettle();

      // Page 1 then the auto-prefetched page 2, both vinyl-only + Label.
      expect(service.pages.last, 2);
      expect(service.vinylOnlys.last, isTrue);
      expect(service.filters.last, SearchFilter.label);
    });

    testWidgets('no vinyl results: names the filter and offers to drop it', (
      tester,
    ) async {
      final service = _RecordingSearchService(page1: const [], page2: const []);
      await tester.pumpWidget(_buildScreen(service));
      await tester.pumpAndSettle();
      await applySearchFilters(tester, vinylOnly: true);
      await submitSearch(tester, 'obscure');
      await tester.pumpAndSettle();

      expect(find.text('No vinyl releases match this search.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('search-show-all-formats-button')));
      await tester.pumpAndSettle();

      expect(await isOn(tester), isFalse);
      expect(service.vinylOnlys.last, isFalse);
    });

    testWidgets('a plain empty result does not mention vinyl', (tester) async {
      final service = _RecordingSearchService(page1: const [], page2: const []);
      await tester.pumpWidget(_buildScreen(service));
      await tester.pumpAndSettle();
      await submitSearch(tester, 'obscure');
      await tester.pumpAndSettle();

      expect(find.text('Try a different search term.'), findsOneWidget);
      expect(
        find.byKey(const Key('search-show-all-formats-button')),
        findsNothing,
      );
    });

    testWidgets('the choice is remembered for the next session', (
      tester,
    ) async {
      final first = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(first));
      await tester.pumpAndSettle();
      await applySearchFilters(tester, vinylOnly: true);
      await tester.pumpAndSettle();

      // "Restart: tear the screen down and build a fresh one.
      await tester.pumpWidget(const SizedBox());
      final second = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(second));
      await tester.pumpAndSettle();
      await submitSearch(tester, 'blue note');

      expect(await isOn(tester), isTrue);
      expect(second.vinylOnlys, [true]);
    });

    testWidgets('results cached without the filter are not shown with it', (
      tester,
    ) async {
      final cache = SearchQueryCache();
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service, queryCache: cache));
      await tester.pumpAndSettle();
      await submitSearch(tester, 'blue note');
      final callsBefore = service.vinylOnlys.length;

      await applySearchFilters(tester, vinylOnly: true);
      await tester.pumpAndSettle();

      expect(service.vinylOnlys.length, callsBefore + 1);
      expect(
        cache.get(
          SearchQueryCache.normalizeKey(
            'blue note',
            SearchFilter.all,
            SearchSort.relevance,
            true,
          ),
        ),
        isNotNull,
      );
    });

    testWidgets('label is translated (nl)', (tester) async {
      await tester.pumpWidget(
        _buildScreenNl(
          _RecordingSearchService(page1: const [], page2: const []),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('search-filter-button')));
      await _settleSheet(tester);
      expect(find.text('Alleen vinyl'), findsOneWidget);
      expect(find.text('Zoekfilters'), findsOneWidget);
    });
  });

  group('SearchScreen — open a label from a release (US-134)', () {
    const columbiaRelease = ReleaseDetail(
      id: 249504,
      title: 'Kind Of Blue',
      artist: 'Miles Davis',
      label: 'Columbia',
      catno: 'CL 1355',
      format: 'Vinyl, LP, Album',
      country: 'US',
      year: 1959,
      genres: ['Jazz'],
      styles: [],
      tracklist: [],
      identifiers: [],
    );

    ({GoRouter router, Widget app}) buildApp({
      required DiscogsSearchService service,
      required _FakeCollectionRepository collection,
      String initialLocation = '/search/release/249504',
    }) {
      // Phone layout: the detail is its own route on top of the search screen.
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(390, 844);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);
      final wishlist = _FakeWishlistRepository();
      final router = GoRouter(
        initialLocation: initialLocation,
        // As in the app's search branch: lets the screen refresh membership
        // icons when a detail is popped.
        observers: [searchRouteObserver],
        routes: [
          GoRoute(
            path: '/search',
            builder: (_, state) => Scaffold(
              body: SearchScreen(
                request: state.extra as SearchRequest?,
                searchService: service,
                collectionRepository: collection,
                wishlistRepository: wishlist,
                loadVinylOnly: () async => false,
                saveVinylOnly: (_) async {},
              ),
            ),
            routes: [
              GoRoute(
                path: 'release/:releaseId',
                builder: (_, state) => ReleaseDetailScreen(
                  releaseId: int.parse(state.pathParameters['releaseId']!),
                  detailService: _DetailService(columbiaRelease),
                  collectionRepository: collection,
                  wishlistRepository: wishlist,
                  addToCollectionUseCase: AddToCollectionUseCase(collection),
                ),
              ),
            ],
          ),
        ],
      );
      return (
        router: router,
        app: MaterialApp.router(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    testWidgets('tapping the label opens its releases, newest first, with '
        'the Label filter, and pops the detail', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      final (:router, :app) = buildApp(
        service: service,
        collection: _FakeCollectionRepository(),
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('release-label-link')));
      await tester.tap(find.byKey(const Key('release-label-link')));
      await tester.pumpAndSettle();

      expect(find.byType(ReleaseDetailScreen), findsNothing);
      expect(router.canPop(), isFalse, reason: 'no stack of detail screens');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Columbia');
      final sheet = await readSearchFilters(tester);
      expect(sheet.filter, SearchFilter.label);
      expect(sheet.sort, SearchSort.newestFirst);
      expect(service.filters.last, SearchFilter.label);
      expect(service.sorts.last, SearchSort.newestFirst);
    });

    testWidgets('label results show collection membership, and adding from '
        'there updates it on return', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      final collection = _FakeCollectionRepository();
      final (:router, :app) = buildApp(
        service: service,
        collection: collection,
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('release-label-link')));
      await tester.tap(find.byKey(const Key('release-label-link')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('in-collection-icon')), findsNothing);

      // Open the release from the label results, add it, go back.
      await tester.tap(find.byType(ReleaseSearchResultCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Collection'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('in-collection-icon')), findsOneWidget);
    });

    testWidgets('an unrelated rebuild does not re-apply the request', (
      tester,
    ) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      final (:router, :app) = buildApp(
        service: service,
        collection: _FakeCollectionRepository(),
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('release-label-link')));
      await tester.tap(find.byKey(const Key('release-label-link')));
      await tester.pumpAndSettle();

      // The user types a new search; opening and closing a release rebuilds
      // the /search route with the same extra — that must not undo it.
      await submitSearch(tester, 'impulse');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ReleaseSearchResultCard).first);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'impulse');
    });
  });

  group('SearchScreen — re-tapping the Search tab clears it (US-139)', () {
    void reselectSearchTab() => searchTabReselectedNotifier.value++;
    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('on the results: empties the box, idles, focuses the field', (
      tester,
    ) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'blue note');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(find.byType(ReleaseSearchResultCard), findsWidgets);

      reselectSearchTab();
      await tester.pumpAndSettle();

      expect(fieldText(tester), isEmpty);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('keeps the scope chip and the sort', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await applySearchFilters(
        tester,
        scope: SearchFilter.label,
        sort: SearchSort.oldestFirst,
      );
      await submitSearch(tester, 'blue note');
      await tester.pumpAndSettle();

      reselectSearchTab();
      await tester.pumpAndSettle();
      await submitSearch(tester, 'impulse');

      expect(service.filters.last, SearchFilter.label);
      expect(service.sorts.last, SearchSort.oldestFirst);
    });

    testWidgets('a search still in flight cannot bring results back', (
      tester,
    ) async {
      final completer = Completer<SearchResultPage>();
      await tester.pumpWidget(_buildScreen(_DelayedSearchService(completer)));
      await submitSearch(tester, 'blue note');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      reselectSearchTab();
      await tester.pump();
      completer.complete(
        const SearchResultPage(
          items: [_kindOfBlue],
          currentPage: 1,
          totalPages: 1,
          totalResults: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(fieldText(tester), isEmpty);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('with a release open, the tap clears nothing', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      final router = GoRouter(
        initialLocation: '/search',
        routes: [
          GoRoute(
            path: '/search',
            builder: (_, _) =>
                Scaffold(body: SearchScreen(searchService: service)),
            routes: [
              GoRoute(
                path: 'release/:id',
                builder: (_, _) => const Scaffold(body: Text('detail')),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await submitSearch(tester, 'blue note');
      await tester.pumpAndSettle();
      router.push('/search/release/249504');
      await tester.pumpAndSettle();

      // The shell's first tap pops back to the results; the screen must not
      // clear anything while the detail is still on top.
      reselectSearchTab();
      router.pop();
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'blue note');
      expect(find.byType(ReleaseSearchResultCard), findsWidgets);
    });
  });

  group('SearchScreen — sort in the filter sheet (US-133 / US-162)', () {
    Future<void> pickSort(WidgetTester tester, SearchSort sort) async {
      await applySearchFilters(tester, sort: sort);
      await tester.pumpAndSettle();
    }

    testWidgets('defaults to relevance and offers three orders', (
      tester,
    ) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'blue note');
      expect(service.sorts, [SearchSort.relevance]);

      await tester.tap(find.byKey(const Key('search-filter-button')));
      await _settleSheet(tester);
      expect(find.text('Relevance'), findsOneWidget);
      expect(find.text('Newest first'), findsOneWidget);
      expect(find.text('Oldest first'), findsOneWidget);
      expect(_openSheetState(tester).sort, SearchSort.relevance);
    });

    testWidgets('changing the sort re-runs the search from page 1', (
      tester,
    ) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'blue note');

      await pickSort(tester, SearchSort.newestFirst);

      expect(service.sorts, [SearchSort.relevance, SearchSort.newestFirst]);
      expect(service.pages.last, 1);
      // A non-default sort counts in the filter badge.
      expect(_badgeCount(tester), 1);
    });

    testWidgets('a chip picked before typing survives focusing the field', (
      tester,
    ) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await applySearchFilters(tester, scope: SearchFilter.label);
      // Tapping the empty field moves the cursor but changes no text.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await submitSearch(tester, 'blue note');

      expect(service.filters, [SearchFilter.label]);
    });

    testWidgets('combines with the Label filter', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await applySearchFilters(tester, scope: SearchFilter.label);
      await submitSearch(tester, 'blue note');
      await pickSort(tester, SearchSort.oldestFirst);

      expect(service.filters.last, SearchFilter.label);
      expect(service.sorts.last, SearchSort.oldestFirst);
    });

    testWidgets('pagination keeps the sort of the originating search', (
      tester,
    ) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: [_abbeyRoad],
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'blue note');
      await tester.pumpAndSettle();
      await pickSort(tester, SearchSort.newestFirst);

      // Page 1 then the auto-prefetched page 2, both newest-first.
      expect(service.pages.last, 2);
      expect(service.sorts.last, SearchSort.newestFirst);
    });

    testWidgets('results cached under another sort are not shown', (
      tester,
    ) async {
      final cache = SearchQueryCache();
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service, queryCache: cache));
      await submitSearch(tester, 'blue note');
      final callsBefore = service.sorts.length;

      await pickSort(tester, SearchSort.newestFirst);

      // No cache hit for the new order: a real search ran for it, and each
      // order now has its own entry.
      expect(service.sorts.length, callsBefore + 1);
      expect(cache.get(SearchQueryCache.normalizeKey('blue note')), isNotNull);
      expect(
        cache.get(
          SearchQueryCache.normalizeKey(
            'blue note',
            SearchFilter.all,
            SearchSort.newestFirst,
          ),
        ),
        isNotNull,
      );
    });

    testWidgets('clearing the field keeps the chosen sort', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'blue note');
      await pickSort(tester, SearchSort.oldestFirst);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await submitSearch(tester, 'impulse');

      expect(service.sorts.last, SearchSort.oldestFirst);
    });

    testWidgets('sort labels are translated (nl)', (tester) async {
      final service = _RecordingSearchService(
        page1: [_kindOfBlue],
        page2: const [],
      );
      await tester.pumpWidget(_buildScreenNl(service));
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-filter-button')));
      await _settleSheet(tester);
      expect(find.text('Relevantie'), findsOneWidget);
      expect(find.text('Nieuwste eerst'), findsOneWidget);
      expect(find.text('Sorteren'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper fakes for pagination tests
// ---------------------------------------------------------------------------

/// Page 1 returns [page1Items] immediately (totalPages = 2).
/// Page 2 returns [page2Items] immediately, throws [page2Error] if set,
/// or blocks on [page2Completer] if provided.
class _BlockingPaginationService extends DiscogsSearchService {
  _BlockingPaginationService({
    required this.page1Items,
    this.page2Completer,
    this.page2Error,
  }) : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final List<ReleaseSearchResult> page1Items;
  final List<ReleaseSearchResult> page2Items = const [];
  final Completer<SearchResultPage>? page2Completer;
  final AppError? page2Error;

  @override
  Future<SearchResultPage> search(
    String query, {
    int page = 1,
    SearchFilter filter = SearchFilter.all,
    SearchSort sort = SearchSort.relevance,
    bool vinylOnly = false,
  }) async {
    if (page == 1) {
      return SearchResultPage(
        items: page1Items,
        currentPage: 1,
        totalPages: 2,
        totalResults: page1Items.length + page2Items.length,
      );
    }
    if (page2Error != null) throw page2Error!;
    if (page2Completer != null) return page2Completer!.future;
    return SearchResultPage(
      items: page2Items,
      currentPage: 2,
      totalPages: 2,
      totalResults: page1Items.length + page2Items.length,
    );
  }
}

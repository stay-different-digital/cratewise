import 'dart:async';

import 'package:cratewise/application/services/discogs_search_service.dart';
import 'package:cratewise/presentation/screens/release_detail_screen.dart';
import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/domain/models/search_result_page.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/presentation/screens/search_screen.dart';
import 'package:cratewise/presentation/widgets/release_search_result_card.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<SearchResultPage> search(String query, {int page = 1}) async {
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
  Future<SearchResultPage> search(String query, {int page = 1}) async {
    callCount++;
    return _singlePage(results);
  }
}

class _FlippingSearchService extends DiscogsSearchService {
  _FlippingSearchService({required this.firstError, required this.results})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final AppError firstError;
  final List<ReleaseSearchResult> results;
  int _callCount = 0;

  @override
  Future<SearchResultPage> search(String query, {int page = 1}) async {
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
  Future<SearchResultPage> search(String query, {int page = 1}) =>
      _completer.future;
}

/// Returns page 1 with [page1Items] (hasMore = true), then page 2 with
/// [page2Items] on subsequent calls.
class _PaginatingSearchService extends DiscogsSearchService {
  _PaginatingSearchService({
    required this.page1Items,
    required this.page2Items,
    this.page2Error,
  }) : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final List<ReleaseSearchResult> page1Items;
  final List<ReleaseSearchResult> page2Items;
  final AppError? page2Error;

  @override
  Future<SearchResultPage> search(String query, {int page = 1}) async {
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
// Helpers
// ---------------------------------------------------------------------------

Widget _buildScreen(DiscogsSearchService service) {
  return MaterialApp(
    home: Scaffold(body: SearchScreen(searchService: service)),
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

    testWidgets('result card shows format and label', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.text('Vinyl · Columbia'), findsOneWidget);
    });

    testWidgets('result card shows year and country', (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.text('1959 · US'), findsOneWidget);
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
      'shows inline retry button when page 2 returns rate-limit error',
      (tester) async {
        // The post-frame trigger fires _loadMore → RateLimitedError → retry shown.
        final service = _BlockingPaginationService(
          page1Items: [_kindOfBlue],
          page2Error: const RateLimitedError(),
        );

        await tester.pumpWidget(_buildScreen(service));
        await submitSearch(tester, 'vinyl');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('pagination-retry')), findsOneWidget);
        expect(find.textContaining('Rate limited'), findsOneWidget);
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
        await tester.pumpAndSettle();

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
        // Force narrow viewport (< 700 dp) so tapping uses Navigator.push.
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final service = _FakeSearchService(results: [_kindOfBlue]);
        await tester.pumpWidget(_buildScreen(service));
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
    this.page2Items = const [],
    this.page2Completer,
    this.page2Error,
  }) : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final List<ReleaseSearchResult> page1Items;
  final List<ReleaseSearchResult> page2Items;
  final Completer<SearchResultPage>? page2Completer;
  final AppError? page2Error;

  @override
  Future<SearchResultPage> search(String query, {int page = 1}) async {
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

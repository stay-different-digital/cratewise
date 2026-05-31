import 'dart:async';

import 'package:cratewise/application/services/discogs_search_service.dart';
import 'package:cratewise/presentation/screens/release_detail_screen.dart';
import 'package:cratewise/domain/models/release_search_result.dart';
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

class _FakeSearchService extends DiscogsSearchService {
  _FakeSearchService({this.results, this.throws})
      : super(
          storage: _FakeTokenStorage(),
          apiClient: DiscogsApiClient(),
        );

  final List<ReleaseSearchResult>? results;
  final AppError? throws;

  @override
  Future<List<ReleaseSearchResult>> search(String query) async {
    if (throws != null) throw throws!;
    return results ?? [];
  }
}

class _CountingSearchService extends DiscogsSearchService {
  _CountingSearchService({required this.results})
      : super(
          storage: _FakeTokenStorage(),
          apiClient: DiscogsApiClient(),
        );

  final List<ReleaseSearchResult> results;
  int callCount = 0;

  @override
  Future<List<ReleaseSearchResult>> search(String query) async {
    callCount++;
    return results;
  }
}

class _FlippingSearchService extends DiscogsSearchService {
  _FlippingSearchService({required this.firstError, required this.results})
      : super(
          storage: _FakeTokenStorage(),
          apiClient: DiscogsApiClient(),
        );

  final AppError firstError;
  final List<ReleaseSearchResult> results;
  int _callCount = 0;

  @override
  Future<List<ReleaseSearchResult>> search(String query) async {
    _callCount++;
    if (_callCount == 1) throw firstError;
    return results;
  }
}

class _DelayedSearchService extends DiscogsSearchService {
  _DelayedSearchService(this._completer)
      : super(
          storage: _FakeTokenStorage(),
          apiClient: DiscogsApiClient(),
        );

  final Completer<List<ReleaseSearchResult>> _completer;

  @override
  Future<List<ReleaseSearchResult>> search(String query) =>
      _completer.future;
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
      expect(
        find.textContaining('Type an artist'),
        findsOneWidget,
      );
    });

    testWidgets('shows search icons when query is empty', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      // Both the TextField prefix and the empty-state illustration use Icons.search.
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('does not show result cards when query is empty', (tester) async {
      await tester.pumpWidget(_buildScreen(_FakeSearchService()));
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('shows empty state with text entered but before submitting',
        (tester) async {
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
    testWidgets('shows loading indicator while search is in progress',
        (tester) async {
      final completer = Completer<List<ReleaseSearchResult>>();
      await tester.pumpWidget(
          _buildScreen(_DelayedSearchService(completer)));

      await tester.enterText(find.byType(TextField), 'miles');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([_kindOfBlue]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows result cards after successful search', (tester) async {
      final service =
          _FakeSearchService(results: [_kindOfBlue, _abbeyRoad]);
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

    testWidgets('result card shows cover placeholder icon when no coverUrl',
        (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.byIcon(Icons.album), findsWidgets);
    });

    testWidgets('shows no-results message when search returns empty',
        (tester) async {
      final service = _FakeSearchService(results: []);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'xyzzy');
      expect(find.text('No results'), findsOneWidget);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('shows no-token message when no token is saved', (tester) async {
      final service =
          _FakeSearchService(throws: const NoTokenError());
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(
        find.textContaining('Connect a Discogs token in Settings'),
        findsOneWidget,
      );
    });

    testWidgets('shows network error message on network failure', (tester) async {
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
      final service =
          _FakeSearchService(throws: const InvalidTokenError());
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      expect(find.textContaining('not valid'), findsOneWidget);
    });
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

    testWidgets('tapping clear after results shows empty state', (tester) async {
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
    testWidgets('does not search before debounce delay elapses', (tester) async {
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

      await tester.pump(const Duration(milliseconds: 200)); // second timer fires
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
    testWidgets('does not fire a duplicate request when results are showing',
        (tester) async {
      final service = _CountingSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));

      await submitSearch(tester, 'miles');
      expect(service.callCount, 1);
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);

      await submitSearch(tester, 'miles'); // same query, results already shown
      expect(service.callCount, 1);
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
    });

    testWidgets('allows retry after an error for the same query', (tester) async {
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

    testWidgets('fires again after clearing and retyping same query',
        (tester) async {
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
    testWidgets('tapping a result card opens release detail screen',
        (tester) async {
      final service = _FakeSearchService(results: [_kindOfBlue]);
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');

      await tester.tap(find.byType(ReleaseSearchResultCard).first);
      // Advance past the navigation animation without waiting for the detail
      // fetch (which would try to call FlutterSecureStorage in tests).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReleaseDetailScreen), findsOneWidget);
      expect(find.byKey(const Key('release-detail-loading')), findsOneWidget);
    });

    testWidgets('back from detail screen returns to search results',
        (tester) async {
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
    });
  });

  group('SearchScreen security', () {
    testWidgets('token value is not visible in any rendered Text widget',
        (tester) async {
      const sensitiveToken = 'super_secret_token_xyz_123';
      final service = _FakeSearchService(
        throws: const InvalidTokenError(),
      );
      await tester.pumpWidget(_buildScreen(service));
      await submitSearch(tester, 'miles');
      final tokenInText = tester
          .widgetList<Text>(find.byType(Text))
          .where((w) => w.data?.contains(sensitiveToken) == true);
      expect(tokenInText, isEmpty);
    });
  });
}

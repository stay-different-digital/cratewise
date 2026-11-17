// Live end-to-end check against the real Discogs API with a real account.
//
// Needs the test token from the gitignored `.env` (DISCOGS_TEST_TOKEN):
//
//   flutter test integration_test/discogs_live_test.dart \
//     -d <device> --dart-define-from-file=.env
//
// Without the token the test is skipped, so CI and machines without `.env`
// are unaffected. READ-ONLY towards Discogs: it links the account, walks the
// tabs and searches, but never adds anything (auto-sync stays off), so the
// account's collection and wantlist are not changed.

import 'package:cratewise/app/app.dart';
import 'package:cratewise/infrastructure/secure_storage/discogs_token_storage.dart';
import 'package:cratewise/presentation/widgets/release_search_result_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _token = String.fromEnvironment('DISCOGS_TEST_TOKEN');

/// Pumps until [finder] matches or [timeout] passes — network calls make
/// pumpAndSettle unreliable (spinners keep scheduling frames).
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live: link account, walk the tabs, search vinyl on a label', (
    tester,
  ) async {
    // Start disconnected so onboarding shows the token field.
    await DiscogsTokenStorage().deleteCredentials();

    await tester.pumpWidget(const CratewiseApp(showOnboarding: true));
    await tester.pumpAndSettle();

    // Onboarding: welcome → token → skip import.
    await tester.tap(find.text('Aan de slag'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Personal access token'),
      _token,
    );
    // Let the field's listener enable the button before tapping it.
    await tester.pump();
    await tester.tap(find.text('Validate token'));
    final next = find.byKey(const Key('onboarding-next-token'));
    await _pumpUntil(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w.key == const Key('onboarding-next-token') &&
            w is FilledButton &&
            w.onPressed != null,
      ),
    );
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-skip')));
    // Finishing onboarding is saved first, then the app navigates.
    await _pumpUntil(
      tester,
      find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail),
    );

    // All five tabs open, by position (selected tabs swap their icon, so
    // icons are not a stable handle). Bar on phones, rail on wide screens.
    final bar = find.byType(NavigationBar);
    final tabs = bar.evaluate().isNotEmpty
        ? find.descendant(of: bar, matching: find.byType(NavigationDestination))
        : find.descendant(
            of: find.byType(NavigationRail),
            matching: find.byType(InkResponse),
          );
    expect(tabs, findsNWidgets(5));
    for (final index in [1, 2, 3, 4, 0]) {
      await tester.tap(tabs.at(index));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byKey(const Key('search-filter-button')), findsOneWidget);

    // Search: Label scope, vinyl only, newest first via the filter sheet
    // (US-161 / US-162) — real results.
    await tester.tap(find.byKey(const Key('search-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort-option-newestFirst')));
    await tester.tap(find.byKey(const Key('search-filter-chip-label')));
    final vinyl = find.byKey(const Key('search-vinyl-only-switch'));
    if (!tester.widget<SwitchListTile>(vinyl).value) {
      await tester.tap(vinyl);
    }
    await tester.pump();
    await tester.tap(find.byKey(const Key('apply-filter-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Blue Note');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntil(tester, find.byType(ReleaseSearchResultCard));
    expect(find.byType(ReleaseSearchResultCard), findsWidgets);

    // A release detail offers the label link (US-134).
    await tester.tap(find.byType(ReleaseSearchResultCard).first);
    await _pumpUntil(tester, find.byKey(const Key('release-label-link')));
  }, skip: _token.isEmpty);
}

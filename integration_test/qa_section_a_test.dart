import 'package:cratewise/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drives Section A (First launch and setup) of
/// docs/qa/PHASE_10_DEVICE_VALIDATION.md on a real device or simulator.
///
/// Not part of `flutter test` — run with:
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/qa_section_a_test.dart -d `<device>`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('Section A: tabs, state retention, and token field', (
    tester,
  ) async {
    runApp(const CratewiseApp());
    await tester.pumpAndSettle();

    // A4 — all five tabs are reachable.
    expect(find.text('Search'), findsWidgets);
    await tester.tap(find.text('Collection'));
    await tester.pumpAndSettle();
    await shoot(tester, 'a4_collection_tab');

    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();
    await shoot(tester, 'a4_wishlist_tab');

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    await shoot(tester, 'a4_statistics_tab');

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await shoot(tester, 'a4_settings_tab');

    // A4 — navigation state survives tab switches: type a query on Search,
    // switch away and back, the query must still be there.
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Aphex Twin');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    final searchField = tester.widget<TextField>(find.byType(TextField).first);
    expect(searchField.controller?.text, equals('Aphex Twin'));
    await shoot(tester, 'a4_search_state_retained');

    // A6 — token field masks input by default; show/hide toggle works.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final tokenField = find.widgetWithText(TextField, 'Personal access token');
    final anyTokenField = tokenField.evaluate().isNotEmpty
        ? tokenField
        : find.byType(TextField).first;
    await tester.enterText(
      anyTokenField,
      'not-a-real-token-just-qa-input-40-chars!',
    );
    await tester.pumpAndSettle();
    TextField fieldWidget = tester.widget<TextField>(anyTokenField);
    expect(fieldWidget.obscureText, isTrue, reason: 'token must be masked');
    await shoot(tester, 'a6_token_masked');

    await tester.tap(find.byTooltip('Show token'));
    await tester.pumpAndSettle();
    fieldWidget = tester.widget<TextField>(anyTokenField);
    expect(fieldWidget.obscureText, isFalse, reason: 'show toggle reveals');
    await shoot(tester, 'a6_token_shown');

    await tester.tap(find.byTooltip('Hide token'));
    await tester.pumpAndSettle();
    fieldWidget = tester.widget<TextField>(anyTokenField);
    expect(fieldWidget.obscureText, isTrue, reason: 'hide toggle masks again');

    // A7 — help link to discogs.com is present (not tapped: would leave app).
    expect(
      find.textContaining('discogs.com', findRichText: true),
      findsWidgets,
    );

    // A8 — validating an invalid token shows a friendly error and never
    // echoes the token. Real network call to api.discogs.com (401).
    await tester.tap(find.text('Validate token'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    // The token may legitimately exist inside the (masked) input field's
    // EditableText; it must never appear in any other Text widget such as
    // labels or error messages.
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains('not-a-real-token'),
      ),
      findsNothing,
      reason: 'token value must never be echoed in the UI',
    );
    await shoot(tester, 'a8_invalid_token_error');

    // A10 — remove token clears the field.
    await tester.tap(find.text('Remove token'));
    await tester.pumpAndSettle();
    fieldWidget = tester.widget<TextField>(anyTokenField);
    expect(fieldWidget.controller?.text ?? '', isEmpty);
    await shoot(tester, 'a10_token_removed');
  });
}

import 'package:cratewise/presentation/widgets/about_section_tile.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('AboutSectionTile', () {
    testWidgets('shows the About tile with the runtime version', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(AboutSectionTile(appVersionLoader: () async => '1.0.0.2')),
      );
      await tester.pump();

      expect(find.text('About Cratewise'), findsOneWidget);
      expect(find.text('Version 1.0.0.2'), findsOneWidget);
    });

    testWidgets('tapping opens the about dialog with name and version', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(AboutSectionTile(appVersionLoader: () async => '1.0.0.2')),
      );
      await tester.pump();

      await tester.tap(find.text('About Cratewise'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutDialog), findsOneWidget);
      expect(find.text('Cratewise'), findsOneWidget);
      expect(find.text('1.0.0.2'), findsOneWidget);
      expect(
        find.text(
          'Free software under the GNU GPL v3.0. '
          'Uses the Discogs API. Not affiliated with Discogs.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('licences page is reachable from the about dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(AboutSectionTile(appVersionLoader: () async => '1.0.0.2')),
      );
      await tester.pump();

      await tester.tap(find.text('About Cratewise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View licenses'));
      // LicensePage loads licence entries asynchronously; pump a few frames
      // instead of pumpAndSettle to avoid waiting on its progress indicator.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('shows "unknown" when the version loader fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          AboutSectionTile(
            appVersionLoader: () async => throw Exception('no platform'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Version unknown'), findsOneWidget);
    });
  });
}

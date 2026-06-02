import 'package:cratewise/presentation/screens/import_export_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildSubject() => const MaterialApp(home: ImportExportScreen());

// Sets a tall narrow screen so all 8 cards fit without scrolling.
void _setNarrowTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 2.0;
}

// Sets a wide tall screen for iPad-style layout.
void _setWideTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(2800, 2000);
  tester.view.devicePixelRatio = 2.0;
}

void main() {
  group('ImportExportScreen', () {
    group('structure', () {
      testWidgets('shows Import & Export in AppBar', (tester) async {
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Import & Export'), findsOneWidget);
      });

      testWidgets('shows Discogs section header', (tester) async {
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Discogs'), findsOneWidget);
      });

      testWidgets('shows CSV files section header', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        expect(find.text('CSV files'), findsOneWidget);
      });

      testWidgets('shows all 8 action card titles', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());

        expect(find.text('Import Collection from Discogs'), findsOneWidget);
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
        expect(find.text('Export Wishlist to Discogs'), findsOneWidget);
        expect(find.text('Export Collection to CSV'), findsOneWidget);
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
        expect(find.text('Import Collection from CSV'), findsOneWidget);
        expect(find.text('Import Wishlist from CSV'), findsOneWidget);
      });

      testWidgets('each card shows a Coming soon badge', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());

        expect(find.text('Coming soon'), findsNWidgets(8));
      });
    });

    group('action card interactions', () {
      testWidgets('tapping a Discogs card shows Coming soon snackbar',
          (tester) async {
        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Import Collection from Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('snackbar text is Coming soon', (tester) async {
        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Import Collection from Discogs'));
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text('Coming soon'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('tapping Export Wishlist to Discogs shows snackbar',
          (tester) async {
        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Export Wishlist to Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('tapping a CSV card shows Coming soon snackbar',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Export Collection to CSV'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('tapping Import Wishlist from CSV shows snackbar',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Import Wishlist from CSV'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('no network requests are made when cards are tapped',
          (tester) async {
        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Import Collection from Discogs'));
        await tester.pump();
        // Screen renders and shows snackbar without any network setup — no
        // Discogs client or repository is present.
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('wide layout', () {
      testWidgets('renders without error on wide screen', (tester) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());

        expect(find.text('Import & Export'), findsOneWidget);
        expect(find.text('Discogs'), findsOneWidget);
        expect(find.text('CSV files'), findsOneWidget);
      });

      testWidgets('shows all 8 action cards on wide tall screen', (tester) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());

        expect(find.text('Import Collection from Discogs'), findsOneWidget);
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
        expect(find.text('Export Wishlist to Discogs'), findsOneWidget);
        expect(find.text('Export Collection to CSV'), findsOneWidget);
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
        expect(find.text('Import Collection from CSV'), findsOneWidget);
        expect(find.text('Import Wishlist from CSV'), findsOneWidget);
      });

      testWidgets('tapping a card on wide screen shows snackbar', (tester) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Export Collection to Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('each card shows Coming soon badge on wide screen',
          (tester) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        expect(find.text('Coming soon'), findsNWidgets(8));
      });
    });
  });
}

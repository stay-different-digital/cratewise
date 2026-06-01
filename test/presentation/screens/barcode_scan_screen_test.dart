import 'package:cratewise/presentation/screens/barcode_scan_screen.dart';
import 'package:cratewise/presentation/widgets/release_search_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BarcodeScanScreen — layout', () {
    testWidgets('shows scan area placeholder', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('scan-area-placeholder')), findsOneWidget);
    });

    testWidgets('shows barcode input field', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('barcode-input')), findsOneWidget);
    });

    testWidgets('shows Scan barcode button', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('scan-barcode-button')), findsOneWidget);
    });

    testWidgets('shows Search barcode button', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('search-barcode-button')), findsOneWidget);
    });

    testWidgets('scan area shows scanner icon', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      final placeholder = find.byKey(const Key('scan-area-placeholder'));
      final icons = find.descendant(
        of: placeholder,
        matching: find.byIcon(Icons.qr_code_scanner),
      );
      expect(icons, findsOneWidget);
    });
  });

  group('BarcodeScanScreen — idle state', () {
    testWidgets('shows empty state title initially', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.text('Scan or enter a barcode'), findsOneWidget);
    });

    testWidgets('shows empty state description', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(
        find.text('Point your camera at a barcode or type one above.'),
        findsOneWidget,
      );
    });

    testWidgets('does not show result cards while idle', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });
  });

  group('BarcodeScanScreen — search', () {
    testWidgets('entering barcode and tapping Search shows result cards',
        (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.byType(ReleaseSearchResultCard), findsWidgets);
    });

    testWidgets('tapping Search with empty field stays idle', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Scan or enter a barcode'), findsOneWidget);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('result cards show artist', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '1234567890',
      );
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Miles Davis'), findsWidgets);
    });

    testWidgets('result cards show title', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '1234567890',
      );
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Kind Of Blue'), findsWidgets);
    });

    testWidgets('result cards show Discogs release ID', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '1234567890',
      );
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('#249504'), findsOneWidget);
    });

    testWidgets('submitting text field keyboard triggers search', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(find.byType(ReleaseSearchResultCard), findsWidgets);
    });

    testWidgets('Scan barcode button tap does not crash', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.tap(find.byKey(const Key('scan-barcode-button')));
      await tester.pump();
      expect(find.text('Scan or enter a barcode'), findsOneWidget);
    });

    testWidgets('whitespace-only barcode keeps idle state', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(find.byKey(const Key('barcode-input')), '   ');
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Scan or enter a barcode'), findsOneWidget);
    });
  });
}

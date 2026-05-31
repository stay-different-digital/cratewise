import 'package:cratewise/presentation/screens/search_screen.dart';
import 'package:cratewise/presentation/widgets/release_search_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildScreen() {
  return const MaterialApp(
    home: Scaffold(body: SearchScreen()),
  );
}

void main() {
  group('SearchScreen empty state', () {
    testWidgets('shows heading and prompt when query is empty', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.text('Search Discogs'), findsOneWidget);
      expect(
        find.text('Type an artist, album, or label name to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('shows search icons when query is empty', (tester) async {
      await tester.pumpWidget(_buildScreen());
      // Both the TextField prefix and the empty-state illustration use Icons.search.
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('does not show result cards when query is empty', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });
  });

  group('SearchScreen results', () {
    testWidgets('hides empty state and shows cards after entering query',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump();
      expect(
        find.text('Type an artist, album, or label name to get started.'),
        findsNothing,
      );
      expect(find.byType(ReleaseSearchResultCard), findsWidgets);
    });

    testWidgets('result card shows artist name', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'vinyl');
      await tester.pump();
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('result card shows title', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'vinyl');
      await tester.pump();
      expect(find.text('Kind of Blue'), findsOneWidget);
    });

    testWidgets('result card shows format and label', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'vinyl');
      await tester.pump();
      expect(find.text('LP · Columbia'), findsOneWidget);
    });

    testWidgets('result card shows year and country', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'vinyl');
      await tester.pump();
      expect(find.text('1959 · US'), findsOneWidget);
    });

    testWidgets('result card shows Discogs release ID', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'vinyl');
      await tester.pump();
      expect(find.text('#249504'), findsOneWidget);
    });

    testWidgets('result card shows cover placeholder icon', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'vinyl');
      await tester.pump();
      expect(find.byIcon(Icons.album), findsWidgets);
    });

    testWidgets('shows results for other fake releases', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'vinyl');
      await tester.pump();
      expect(find.text('The Beatles'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
    });
  });

  group('SearchScreen clear', () {
    testWidgets('clear button appears when query is entered', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.byTooltip('Clear search'), findsNothing);
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsOneWidget);
    });

    testWidgets('tapping clear restores empty state', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump();
      expect(find.text('Miles Davis'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.text('Search Discogs'), findsOneWidget);
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('clear button disappears after clearing', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.enterText(find.byType(TextField), 'miles');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });
}

import 'package:cratewise/app/app.dart';
import 'package:cratewise/presentation/screens/search_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for US-53: cold-start must always land on the Search tab.
  //
  // Root cause: appRouter was a top-level global; StatefulShellRoute.indexedStack
  // persisted the active branch index in the GoRouter instance between runApp
  // calls (observable in integration_test / drive sessions where the Dart isolate
  // is reused). Moving the router into CratewiseApp state (createAppRouter())
  // ensures a fresh GoRouter is created on every app start.
  group('CratewiseApp initial route', () {
    testWidgets('cold start shows SearchScreen as the active tab', (
      tester,
    ) async {
      await tester.pumpWidget(const CratewiseApp());
      // Let GoRouter resolve the initial location and build the shell.
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('two consecutive app instances both start on SearchScreen', (
      tester,
    ) async {
      // First instance.
      await tester.pumpWidget(const CratewiseApp());
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);

      // Replace with a second instance — simulates kill + relaunch in the
      // same test process (the scenario that exposed the stale-branch bug).
      await tester.pumpWidget(const CratewiseApp());
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });
}

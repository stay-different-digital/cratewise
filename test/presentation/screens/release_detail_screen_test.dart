import 'package:cratewise/presentation/screens/release_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReleaseDetailScreen', () {
    testWidgets('shows the release ID', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReleaseDetailScreen(releaseId: 249504)),
      );
      expect(find.textContaining('249504'), findsOneWidget);
    });

    testWidgets('shows a title in the app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReleaseDetailScreen(releaseId: 1)),
      );
      expect(find.text('Release Detail'), findsOneWidget);
    });

    testWidgets('shows placeholder message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReleaseDetailScreen(releaseId: 1)),
      );
      expect(find.textContaining('coming soon'), findsOneWidget);
    });

    testWidgets('shows a back button when pushed onto the stack', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReleaseDetailScreen(releaseId: 1),
                  ),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('back button returns to previous screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReleaseDetailScreen(releaseId: 1),
                  ),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byType(ReleaseDetailScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ReleaseDetailScreen), findsNothing);
      expect(find.text('Go'), findsOneWidget);
    });
  });
}

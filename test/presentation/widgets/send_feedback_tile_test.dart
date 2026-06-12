import 'package:cratewise/presentation/widgets/send_feedback_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('SendFeedbackTile', () {
    testWidgets('shows the feedback tile', (tester) async {
      await tester.pumpWidget(_buildApp(const SendFeedbackTile()));

      expect(find.text('Send feedback'), findsOneWidget);
      expect(
        find.text('Report a problem or share an idea by email'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.feedback_outlined), findsOneWidget);
    });

    testWidgets('tapping launches a mailto URI with address, subject, '
        'version and platform', (tester) async {
      Uri? launchedUri;
      await tester.pumpWidget(
        _buildApp(
          SendFeedbackTile(
            appVersionLoader: () async => '1.0.0+2',
            urlLauncher: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Send feedback'));
      await tester.pump();

      expect(launchedUri, isNotNull);
      expect(launchedUri!.scheme, 'mailto');
      expect(launchedUri!.path, feedbackEmailAddress);
      final query = Uri.decodeComponent(launchedUri!.query);
      expect(query, contains('Cratewise beta feedback (1.0.0+2)'));
      expect(query, contains('App: Cratewise 1.0.0+2'));
      expect(query, contains('Platform:'));
      expect(query, contains('Describe what happened'));
    });

    testWidgets('subject and body use %20 encoding, not +', (tester) async {
      Uri? launchedUri;
      await tester.pumpWidget(
        _buildApp(
          SendFeedbackTile(
            appVersionLoader: () async => '1.0.0+2',
            urlLauncher: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Send feedback'));
      await tester.pump();

      // 'beta feedback' in the subject must be %20-separated; a literal '+'
      // would render as a plus sign in most mail apps.
      expect(launchedUri!.query, contains('beta%20feedback'));
    });

    testWidgets('shows snackbar with the address when no mail app opens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          SendFeedbackTile(
            appVersionLoader: () async => '1.0.0+2',
            urlLauncher: (_) async => false,
          ),
        ),
      );

      await tester.tap(find.text('Send feedback'));
      await tester.pump();

      expect(
        find.text(
          'Could not open a mail app. '
          'Email $feedbackEmailAddress instead.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows snackbar when launching throws', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          SendFeedbackTile(
            appVersionLoader: () async => '1.0.0+2',
            urlLauncher: (_) async => throw Exception('no handler'),
          ),
        ),
      );

      await tester.tap(find.text('Send feedback'));
      await tester.pump();

      expect(find.textContaining('Could not open a mail app'), findsOneWidget);
    });

    testWidgets('token or secrets never appear in the prefilled email', (
      tester,
    ) async {
      Uri? launchedUri;
      await tester.pumpWidget(
        _buildApp(
          SendFeedbackTile(
            appVersionLoader: () async => '1.0.0+2',
            urlLauncher: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Send feedback'));
      await tester.pump();

      final query = Uri.decodeComponent(launchedUri!.query).toLowerCase();
      expect(query, isNot(contains('token')));
    });
  });
}

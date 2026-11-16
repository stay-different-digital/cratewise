import 'package:cratewise/presentation/widgets/rate_limit_retry_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('RateLimitRetryButton', () {
    testWidgets('shows active Retry button when not rate limited', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          RateLimitRetryButton(
            onRetry: () => tapped = true,
            isRateLimited: false,
          ),
        ),
      );
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byType(FilledButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows disabled countdown button when rate limited', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RateLimitRetryButton(
            onRetry: () {},
            isRateLimited: true,
            countdownSeconds: 10,
          ),
        ),
      );
      expect(find.textContaining('Retry in'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('countdown decrements each second', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RateLimitRetryButton(
            onRetry: () {},
            isRateLimited: true,
            countdownSeconds: 5,
          ),
        ),
      );
      expect(find.text('Retry in 5 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Retry in 4 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Retry in 3 s'), findsOneWidget);
    });

    testWidgets('button becomes active and tappable after countdown', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          RateLimitRetryButton(
            onRetry: () => tapped = true,
            isRateLimited: true,
            countdownSeconds: 3,
          ),
        ),
      );
      // Still disabled mid-countdown
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('Retry in'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      // Active after countdown completes
      await tester.pump(const Duration(seconds: 1));
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byType(FilledButton));
      expect(tapped, isTrue);
    });
  });
}

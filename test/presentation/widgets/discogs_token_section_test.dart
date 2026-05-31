import 'package:cratewise/presentation/widgets/discogs_token_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('DiscogsTokenSection', () {
    testWidgets('token field is masked by default', (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('show/hide toggle reveals and re-masks token', (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));

      // Initially hidden — icon shows visibility_off.
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Revealed — obscureText is false and icon flips.
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap again to re-mask.
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
    });

    testWidgets('help text mentions the Discogs developer settings URL',
        (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));

      expect(
        find.textContaining('discogs.com/settings/developers'),
        findsOneWidget,
      );
    });

    testWidgets('Validate and Remove buttons are disabled when field is empty',
        (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));

      final validateButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Validate token'),
      );
      final removeButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Remove token'),
      );

      expect(validateButton.onPressed, isNull);
      expect(removeButton.onPressed, isNull);
    });

    testWidgets('Validate and Remove buttons are enabled when field has text',
        (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));

      await tester.enterText(find.byType(TextField), 'some_token_value');
      await tester.pump();

      final validateButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Validate token'),
      );
      final removeButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Remove token'),
      );

      expect(validateButton.onPressed, isNotNull);
      expect(removeButton.onPressed, isNotNull);
    });

    testWidgets('Remove token clears the text field', (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));

      await tester.enterText(find.byType(TextField), 'some_token_value');
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Remove token'));
      await tester.pump();

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.controller.text, isEmpty);
    });

    testWidgets('section heading and description are present', (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));

      expect(find.text('Discogs'), findsOneWidget);
      expect(
        find.text(
          'Connect your Discogs account using a personal access token.',
        ),
        findsOneWidget,
      );
    });
  });
}

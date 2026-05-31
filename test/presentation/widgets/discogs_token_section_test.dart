import 'dart:async';
import 'dart:convert';

import 'package:cratewise/application/services/token_validation_service.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/presentation/widgets/discogs_token_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  group('DiscogsTokenSection validation', () {
    TokenValidationService makeService(http.Client httpClient) {
      return TokenValidationService(
        apiClient: DiscogsApiClient(httpClient: httpClient),
      );
    }

    const identity = {
      'username': 'vinyl_fan',
      'resource_url': 'https://api.discogs.com/users/vinyl_fan',
    };

    testWidgets('shows loading indicator while awaiting response',
        (tester) async {
      final completer = Completer<http.Response>();
      final service = makeService(MockClient((_) => completer.future));

      await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(validationService: service)));
      await tester.enterText(find.byType(TextField), 'some_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Validating…'), findsOneWidget);

      completer.complete(http.Response(jsonEncode(identity), 200));
      await tester.pumpAndSettle();
    });

    testWidgets('shows success message with username on valid token',
        (tester) async {
      final service = makeService(
        MockClient((_) async => http.Response(jsonEncode(identity), 200)),
      );

      await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(validationService: service)));
      await tester.enterText(find.byType(TextField), 'valid_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.text('Connected as @vinyl_fan'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error message when token is rejected', (tester) async {
      final service =
          makeService(MockClient((_) async => http.Response('', 401)));

      await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(validationService: service)));
      await tester.enterText(find.byType(TextField), 'bad_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Token not recognised'), findsOneWidget);
    });

    testWidgets('shows rate limit message on 429', (tester) async {
      final service =
          makeService(MockClient((_) async => http.Response('', 429)));

      await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(validationService: service)));
      await tester.enterText(find.byType(TextField), 'some_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Too many requests'), findsOneWidget);
    });

    testWidgets('shows network error message when request fails',
        (tester) async {
      final service = makeService(
        MockClient((_) async => throw Exception('no internet')),
      );

      await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(validationService: service)));
      await tester.enterText(find.byType(TextField), 'some_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No internet'), findsOneWidget);
    });

    testWidgets('Validate button is disabled while loading', (tester) async {
      final completer = Completer<http.Response>();
      final service = makeService(MockClient((_) => completer.future));

      await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(validationService: service)));
      await tester.enterText(find.byType(TextField), 'some_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Validate token'),
      );
      expect(button.onPressed, isNull);

      completer.complete(http.Response('', 401));
      await tester.pumpAndSettle();
    });

    testWidgets('success status clears when Remove token is tapped',
        (tester) async {
      final service = makeService(
        MockClient((_) async => http.Response(jsonEncode(identity), 200)),
      );

      await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(validationService: service)));
      await tester.enterText(find.byType(TextField), 'valid_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.text('Connected as @vinyl_fan'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Remove token'));
      await tester.pump();

      expect(find.text('Connected as @vinyl_fan'), findsNothing);
    });

    testWidgets('error message does not contain the token value',
        (tester) async {
      const sensitiveToken = 'super_secret_token_xyz_123';
      final service =
          makeService(MockClient((_) async => http.Response('', 401)));

      await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(validationService: service)));
      await tester.enterText(find.byType(TextField), sensitiveToken);
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      // Check rendered Text widgets only — EditableText stores the raw value
      // even when obscured, but Text widgets carry only what is visible to users.
      final tokenInRenderedText = tester
          .widgetList<Text>(find.byType(Text))
          .where((w) => w.data?.contains(sensitiveToken) == true);
      expect(tokenInRenderedText, isEmpty);
    });
  });
}

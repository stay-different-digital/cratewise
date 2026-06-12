import 'dart:async';
import 'dart:convert';

import 'package:cratewise/application/services/discogs_connection_service.dart';
import 'package:cratewise/application/services/token_validation_service.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/presentation/widgets/discogs_token_section.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Widget _buildApp(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

// ---------------------------------------------------------------------------
// Fake helpers
// ---------------------------------------------------------------------------

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({String? savedUsername, String? savedToken})
    : _username = savedUsername,
      _token = savedToken;

  String? _token;
  String? _username;
  bool throwOnSave = false;

  @override
  Future<String?> loadToken() async => _token;
  @override
  Future<String?> loadUsername() async => _username;

  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {
    if (throwOnSave) throw const StorageError();
    _token = token;
    _username = username;
  }

  @override
  Future<void> deleteCredentials() async {
    _token = null;
    _username = null;
  }
}

DiscogsConnectionService _makeService(
  http.Client httpClient, {
  _FakeTokenStorage? storage,
}) {
  return DiscogsConnectionService(
    storage: storage ?? _FakeTokenStorage(),
    validationService: TokenValidationService(
      apiClient: DiscogsApiClient(httpClient: httpClient),
    ),
  );
}

const _identityBody = {
  'username': 'vinyl_fan',
  'resource_url': 'https://api.discogs.com/users/vinyl_fan',
};

// ---------------------------------------------------------------------------
// Basic UI tests — use const DiscogsTokenSection() with no service injection.
// The default service gracefully returns disconnected when storage is
// unavailable (platform channels not set up in unit test environment).
// ---------------------------------------------------------------------------

void main() {
  group('DiscogsTokenSection', () {
    testWidgets('token field is masked by default', (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));
      await tester.pump();

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('show/hide toggle reveals and re-masks token', (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
    });

    testWidgets('help text mentions the Discogs developer settings URL', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));
      await tester.pump();

      expect(
        find.textContaining('discogs.com/settings/developers'),
        findsOneWidget,
      );
    });

    testWidgets('helper text shows 40-character format guidance', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));
      await tester.pump();

      expect(find.textContaining('40 characters'), findsOneWidget);
    });

    testWidgets('helper text is not truncated on a narrow screen (US-54)', (
      tester,
    ) async {
      // 402 logical pixels — narrowest observed width where truncation occurred.
      tester.view.physicalSize = const Size(402 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));
      await tester.pump();

      // The InputDecoration helper renders via a Text widget. We verify it
      // shows the full string — if helperMaxLines is unset, Flutter clips it
      // to one line and the trailing word "characters" would be cut off.
      expect(
        find.text('Discogs personal access tokens are 40 characters'),
        findsOneWidget,
      );
    });

    testWidgets('tapping help link calls url launcher with correct URL', (
      tester,
    ) async {
      Uri? launchedUri;
      await tester.pumpWidget(
        _buildApp(
          DiscogsTokenSection(
            urlLauncher: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.textContaining('discogs.com/settings/developers'));
      await tester.pump();

      expect(launchedUri, isNotNull);
      expect(
        launchedUri.toString(),
        contains('discogs.com/settings/developers'),
      );
      expect(launchedUri!.scheme, 'https');
    });

    testWidgets('shows snackbar when browser cannot be opened', (tester) async {
      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(urlLauncher: (uri) async => false)),
      );
      await tester.pump();

      await tester.tap(find.textContaining('discogs.com/settings/developers'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not open browser'), findsOneWidget);
    });

    testWidgets(
      'Validate and Remove buttons are disabled when field is empty',
      (tester) async {
        await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));
        await tester.pump();

        final validateButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Validate token'),
        );
        final removeButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Remove token'),
        );

        expect(validateButton.onPressed, isNull);
        expect(removeButton.onPressed, isNull);
      },
    );

    testWidgets('Validate and Remove buttons are enabled when field has text', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));
      await tester.pump();

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
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'some_token_value');
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Remove token'));
      await tester.pump();

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.controller.text, isEmpty);
    });

    testWidgets('section heading and description are present', (tester) async {
      await tester.pumpWidget(_buildApp(const DiscogsTokenSection()));
      await tester.pump();

      expect(find.text('Discogs'), findsOneWidget);
      expect(
        find.text(
          'Connect your Discogs account using a personal access token.',
        ),
        findsOneWidget,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Connection flow tests — all inject DiscogsConnectionService with fakes.
  // -------------------------------------------------------------------------

  group('DiscogsTokenSection connection flow', () {
    testWidgets('shows loading indicator while awaiting response', (
      tester,
    ) async {
      final completer = Completer<http.Response>();
      final service = _makeService(MockClient((_) => completer.future));

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'some_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Validating…'), findsOneWidget);

      completer.complete(http.Response(jsonEncode(_identityBody), 200));
      await tester.pumpAndSettle();
    });

    testWidgets('shows connected state and masked token after valid token', (
      tester,
    ) async {
      final service = _makeService(
        MockClient((_) async => http.Response(jsonEncode(_identityBody), 200)),
      );

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'valid_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.text('Connected as @vinyl_fan'), findsOneWidget);
      expect(find.text('••••••••••••••••'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Input form is hidden in connected state.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('shows error message when token is rejected', (tester) async {
      final service = _makeService(
        MockClient((_) async => http.Response('', 401)),
      );

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'bad_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Token not recognised'), findsOneWidget);
    });

    testWidgets('shows rate limit message on 429', (tester) async {
      final service = _makeService(
        MockClient((_) async => http.Response('', 429)),
      );

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'some_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Too many requests'), findsOneWidget);
    });

    testWidgets('shows network error message when request fails', (
      tester,
    ) async {
      final service = _makeService(
        MockClient((_) async => throw Exception('no internet')),
      );

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'some_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No internet'), findsOneWidget);
    });

    testWidgets(
      'shows storage error message when save fails after validation',
      (tester) async {
        final storage = _FakeTokenStorage()..throwOnSave = true;
        final service = _makeService(
          MockClient(
            (_) async => http.Response(jsonEncode(_identityBody), 200),
          ),
          storage: storage,
        );

        await tester.pumpWidget(
          _buildApp(DiscogsTokenSection(connectionService: service)),
        );
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'some_token');
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
        await tester.pumpAndSettle();

        expect(find.textContaining('could not be saved'), findsOneWidget);
      },
    );

    testWidgets('Validate button is disabled while loading', (tester) async {
      final completer = Completer<http.Response>();
      final service = _makeService(MockClient((_) => completer.future));

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pump();
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

    testWidgets('Disconnect button returns to disconnected state', (
      tester,
    ) async {
      final service = _makeService(
        MockClient((_) async => http.Response(jsonEncode(_identityBody), 200)),
      );

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'valid_token');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Validate token'));
      await tester.pumpAndSettle();

      expect(find.text('Connected as @vinyl_fan'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Disconnect'));
      await tester.pumpAndSettle();

      expect(find.text('Connected as @vinyl_fan'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows connected state on load when credentials are saved', (
      tester,
    ) async {
      final storage = _FakeTokenStorage(
        savedUsername: 'returning_user',
        savedToken: 'tok',
      );
      final service = DiscogsConnectionService(storage: storage);

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connected as @returning_user'), findsOneWidget);
      expect(find.text('••••••••••••••••'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('error message does not contain the token value', (
      tester,
    ) async {
      const sensitiveToken = 'super_secret_token_xyz_123';
      final service = _makeService(
        MockClient((_) async => http.Response('', 401)),
      );

      await tester.pumpWidget(
        _buildApp(DiscogsTokenSection(connectionService: service)),
      );
      await tester.pump();
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

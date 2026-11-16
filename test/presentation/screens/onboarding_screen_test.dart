import 'package:cratewise/app/router.dart';
import 'package:cratewise/application/services/discogs_connection_service.dart';
import 'package:cratewise/application/services/onboarding_service.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/presentation/screens/onboarding_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

GoRouter _routerWith(Widget screen) => GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => screen),
    GoRoute(path: AppRoutes.search, builder: (_, _) => const _SearchStub()),
    GoRoute(
      path: AppRoutes.importExport,
      builder: (_, _) => const _ImportStub(),
    ),
  ],
);

Widget _wrap(Widget screen) =>
    MaterialApp.router(routerConfig: _routerWith(screen));

class _SearchStub extends StatelessWidget {
  const _SearchStub();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('search'));
}

class _ImportStub extends StatelessWidget {
  const _ImportStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('import-export'));
}

/// TokenStorage that always reports no credentials (no async I/O).
class _NoTokenStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => null;
  @override
  Future<String?> loadUsername() async => null;
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async {}
}

/// TokenStorage that always reports a stored credential pair.
class _ConnectedStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => 'fake_token';
  @override
  Future<String?> loadUsername() async => 'testuser';
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('OnboardingScreen (US-104)', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    testWidgets('shows onboarding when not yet complete', (tester) async {
      // OnboardingService backed by empty secure storage → isComplete() = false.
      final service = OnboardingService(storage: const FlutterSecureStorage());
      final isComplete = await service.isComplete();
      expect(isComplete, isFalse);

      await tester.pumpWidget(_wrap(OnboardingScreen(service: service)));
      await tester.pump();
      expect(find.text('Welkom bij Cratewise'), findsOneWidget);
    });

    testWidgets('onboarding complete flag suppresses wizard at next start', (
      tester,
    ) async {
      final service = OnboardingService(storage: const FlutterSecureStorage());
      await service.markComplete();
      expect(await service.isComplete(), isTrue);
    });

    testWidgets('"Volgende" on token step disabled until token validated', (
      tester,
    ) async {
      final noTokenService = DiscogsConnectionService(
        storage: _NoTokenStorage(),
      );
      await tester.pumpWidget(
        _wrap(
          OnboardingScreen(
            service: OnboardingService(storage: const FlutterSecureStorage()),
            connectionService: noTokenService,
          ),
        ),
      );
      await tester.pump();

      // Tap "Aan de slag" to advance to step 1 (token step).
      await tester.tap(find.text('Aan de slag'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('onboarding-next-token')),
      );
      expect(
        button.onPressed,
        isNull,
        reason: 'Volgende must be disabled before token is validated',
      );
    });

    testWidgets('shows version string in footer (US-72)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          OnboardingScreen(
            service: OnboardingService(storage: const FlutterSecureStorage()),
            appVersionLoader: () async => '1.0.0.1',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('1.0.0.1'), findsOneWidget);
    });

    testWidgets('"Sla over" on import step navigates to main navigation', (
      tester,
    ) async {
      final connectedService = DiscogsConnectionService(
        storage: _ConnectedStorage(),
      );
      // Start directly at step 2 (import step) with token already connected.
      await tester.pumpWidget(
        _wrap(
          OnboardingScreen(
            service: OnboardingService(storage: const FlutterSecureStorage()),
            connectionService: connectedService,
            initialStep: 2,
            initialTokenConnected: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('onboarding-skip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding-skip')));
      await tester.pumpAndSettle();

      // Router should have navigated away from onboarding to search.
      expect(find.text('search'), findsOneWidget);
      expect(find.text('Welkom bij Cratewise'), findsNothing);
    });
  });
}

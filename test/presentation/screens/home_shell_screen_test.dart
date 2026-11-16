import 'package:cratewise/l10n/app_localizations.dart';
import 'package:cratewise/presentation/screens/home_shell_screen.dart';
import 'package:cratewise/shared/tab_reselect_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Shell with five lightweight branches in the app's tab order, so tab taps
/// can be tested without the real screens (US-139).
Widget _app() {
  StatefulShellBranch branch(String path) => StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, _) => Text(path))],
  );
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShellScreen(navigationShell: shell),
        branches: [
          branch('/search'),
          branch('/collection'),
          branch('/wishlist'),
          branch('/statistics'),
          branch('/settings'),
        ],
      ),
    ],
  );
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  group('HomeShellScreen — Search tab reselect (US-139)', () {
    for (final (name, size) in [
      ('bottom bar', const Size(390, 844)),
      ('nav rail', const Size(1024, 768)),
    ]) {
      testWidgets('$name: tapping the active Search tab notifies', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        final before = searchTabReselectedNotifier.value;

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();

        expect(searchTabReselectedNotifier.value, before + 1);
      });

      testWidgets('$name: arriving from another tab does not notify', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Collection'));
        await tester.pumpAndSettle();
        final before = searchTabReselectedNotifier.value;

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        // Re-tapping another active tab doesn't notify either.
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        expect(searchTabReselectedNotifier.value, before);
      });
    }
  });
}

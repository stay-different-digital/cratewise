import 'package:cratewise/app/app.dart';
import 'package:cratewise/presentation/widgets/app_bottom_nav.dart';
import 'package:cratewise/presentation/widgets/app_nav_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('no static Cratewise header; content claims the top inset', (
    tester,
  ) async {
    await tester.pumpWidget(const CratewiseApp());
    // US-83: the persistent "Cratewise" title bar is removed from the shell.
    expect(find.text('Cratewise'), findsNothing);
    // The freed space is reclaimed, but the body must still respect the status
    // bar — the shell wraps the tab content in a SafeArea.
    expect(find.byType(SafeArea), findsWidgets);
  });

  testWidgets('wide layout shows NavigationRail and no NavigationBar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CratewiseApp());

    expect(find.byType(AppNavRail), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
  });

  // US-135 / US-140: Statistics replaced Scan in the main menu; bar and rail
  // list the same tabs in the same order, so the index → branch mapping stays
  // aligned.
  for (final (name, size) in [
    ('bottom bar', const Size(375, 812)),
    ('nav rail', const Size(1024, 768)),
  ]) {
    testWidgets(
      '$name shows Search, Collection, Wishlist, Statistics, Settings',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const CratewiseApp());

        final labels = size.width < 700
            ? tester
                  .widget<NavigationBar>(find.byType(NavigationBar))
                  .destinations
                  .cast<NavigationDestination>()
                  .map((d) => d.label)
                  .toList()
            : tester
                  .widget<NavigationRail>(find.byType(NavigationRail))
                  .destinations
                  .map((d) => (d.label as Text).data)
                  .toList();
        expect(labels, [
          'Search',
          'Collection',
          'Wishlist',
          'Statistics',
          'Settings',
        ]);
        expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
      },
    );
  }

  testWidgets('narrow layout shows NavigationBar and no NavigationRail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CratewiseApp());

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(AppNavRail), findsNothing);
  });

  testWidgets('all five nav sections are reachable on narrow layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CratewiseApp());

    for (final label in [
      'Search',
      'Collection',
      'Wishlist',
      'Statistics',
      'Settings',
    ]) {
      await tester.tap(find.text(label).first);
      // pump() rather than pumpAndSettle(): the collection tab opens a
      // NativeDatabase in a background isolate that never resolves in the
      // widget-test environment, so pumpAndSettle would time out.
      await tester.pump();
    }

    // After navigating to Settings the Discogs connection section is visible.
    expect(find.text('Discogs'), findsOneWidget);
  });

  testWidgets('tapping Collection shows collection screen on narrow layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CratewiseApp());
    await tester.tap(find.text('Collection').first);
    // Single pump: NativeDatabase opens in a background isolate that never
    // resolves in the widget-test environment, so pumpAndSettle would time out.
    // After one pump the collection screen is visible in its loading state.
    await tester.pump();

    // The search field is always present, even in the loading state.
    expect(find.byType(TextField), findsWidgets);
  });
}

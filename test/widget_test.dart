import 'package:cratewise/app/app.dart';
import 'package:cratewise/presentation/widgets/app_bottom_nav.dart';
import 'package:cratewise/presentation/widgets/app_nav_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app bar shows Cratewise title', (tester) async {
    await tester.pumpWidget(const CratewiseApp());
    expect(find.text('Cratewise'), findsOneWidget);
  });

  testWidgets('wide layout shows NavigationRail and no NavigationBar',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CratewiseApp());

    expect(find.byType(AppNavRail), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('narrow layout shows NavigationBar and no NavigationRail',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CratewiseApp());

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(AppNavRail), findsNothing);
  });

  testWidgets('all five nav sections are reachable on narrow layout',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CratewiseApp());

    for (final label in ['Search', 'Collection', 'Wishlist', 'Scan', 'Settings']) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
    }

    // After navigating to Settings the Discogs connection section is visible.
    expect(find.text('Discogs'), findsOneWidget);
  });

  testWidgets('tapping Collection shows collection list on narrow layout',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CratewiseApp());
    await tester.tap(find.text('Collection').first);
    await tester.pumpAndSettle();

    expect(find.text('Miles Davis'), findsOneWidget);
  });
}

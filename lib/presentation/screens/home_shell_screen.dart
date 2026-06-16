import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/app_nav_rail.dart';

const _kWideBreakpoint = 700.0;

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _kWideBreakpoint;

    if (isWide) {
      return Scaffold(
        // No static title bar (US-83): the freed ~56dp goes to tab content.
        // With the AppBar gone the top inset is no longer handled for us, so
        // the content must claim the status-bar area via SafeArea(top: true).
        body: Row(
          children: [
            AppNavRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTabSelected,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: SafeArea(child: navigationShell)),
          ],
        ),
      );
    }

    return Scaffold(
      // No static title bar (US-83); SafeArea now handles the top inset that
      // the removed AppBar used to cover.
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabSelected,
      ),
    );
  }
}

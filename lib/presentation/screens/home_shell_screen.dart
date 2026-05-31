import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/app_nav_rail.dart';
import 'barcode_scan_screen.dart';
import 'collection_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'wishlist_screen.dart';

const _kWideBreakpoint = 700.0;

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    SearchScreen(),
    CollectionScreen(),
    WishlistScreen(),
    BarcodeScanScreen(),
    SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _kWideBreakpoint;

    if (isWide) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cratewise')),
        body: Row(
          children: [
            AppNavRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTabSelected,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cratewise')),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
      ),
    );
  }
}

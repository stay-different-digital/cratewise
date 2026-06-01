import 'package:flutter/material.dart';

import '../../application/use_cases/add_to_collection_use_case.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';
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
  late final AppDatabase _db;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase(openAppDatabase());
    final repo = LocalCollectionRepository(_db);
    final addUseCase = AddToCollectionUseCase(repo);
    _screens = [
      SearchScreen(addToCollectionUseCase: addUseCase),
      CollectionScreen(repository: repo),
      const WishlistScreen(),
      const BarcodeScanScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

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

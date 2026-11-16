import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search),
          label: l10n.navSearch,
        ),
        NavigationDestination(
          icon: const Icon(Icons.album_outlined),
          selectedIcon: const Icon(Icons.album),
          label: l10n.navCollection,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bookmark_border),
          selectedIcon: const Icon(Icons.bookmark),
          label: l10n.navWishlist,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: l10n.navStatistics,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.navSettings,
        ),
      ],
    );
  }
}

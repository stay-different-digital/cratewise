import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search),
          label: Text(l10n.navSearch),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.album_outlined),
          selectedIcon: const Icon(Icons.album),
          label: Text(l10n.navCollection),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.bookmark_border),
          selectedIcon: const Icon(Icons.bookmark),
          label: Text(l10n.navWishlist),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: Text(l10n.navStatistics),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(l10n.navSettings),
        ),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../../domain/models/search_filter.dart';
import '../../domain/models/search_sort.dart';
import '../../l10n/app_localizations.dart';
import 'filter_sheet_parts.dart';

/// What the search filter sheet edits (US-161 / US-162).
class SearchFilterSettings {
  const SearchFilterSettings({
    this.filter = SearchFilter.all,
    this.vinylOnly = false,
    this.sort = SearchSort.relevance,
  });

  final SearchFilter filter;
  final bool vinylOnly;
  final SearchSort sort;

  /// Shown as the badge on the filter button. A non-default sort counts, so
  /// a sorted result list is visible without a separate sort control.
  int get activeCount =>
      (filter != SearchFilter.all ? 1 : 0) +
      (vinylOnly ? 1 : 0) +
      (sort != SearchSort.relevance ? 1 : 0);
}

/// Bottom sheet behind the search screen's single filter button: sort at the
/// top, then the search scope and "vinyl only". Pops the new settings on
/// Apply; closing it any other way changes nothing.
class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({super.key, required this.current});

  final SearchFilterSettings current;

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilter _filter = widget.current.filter;
  late bool _vinylOnly = widget.current.vinylOnly;
  late SearchSort _sort = widget.current.sort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FilterSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.searchFilterSheetTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  key: const Key('clear-all-button'),
                  onPressed: () => setState(() {
                    _filter = SearchFilter.all;
                    _vinylOnly = false;
                    _sort = SearchSort.relevance;
                  }),
                  child: Text(l10n.filtersClearAll),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                SortSection<SearchSort>(
                  title: l10n.sortTitle,
                  options: [
                    (
                      value: SearchSort.relevance,
                      label: l10n.searchSortRelevance,
                    ),
                    (
                      value: SearchSort.newestFirst,
                      label: l10n.sortNewestFirst,
                    ),
                    (
                      value: SearchSort.oldestFirst,
                      label: l10n.sortOldestFirst,
                    ),
                  ],
                  selected: _sort,
                  onChanged: (s) => setState(() => _sort = s),
                ),
                FilterSheetSection(
                  title: l10n.searchScopeTitle,
                  children: [
                    for (final (filter, label) in [
                      (SearchFilter.release, l10n.searchFilterRelease),
                      (SearchFilter.artist, l10n.searchFilterArtist),
                      (SearchFilter.label, l10n.searchFilterLabel),
                    ])
                      ChoiceChip(
                        key: Key('search-filter-chip-${filter.name}'),
                        label: Text(label),
                        selected: _filter == filter,
                        // Tapping the active scope returns to "everything".
                        onSelected: (selected) => setState(
                          () => _filter = selected ? filter : SearchFilter.all,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('search-vinyl-only-switch'),
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.album),
                  title: Text(l10n.searchVinylOnly),
                  value: _vinylOnly,
                  onChanged: (v) => setState(() => _vinylOnly = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('apply-filter-button'),
                onPressed: () => Navigator.of(context).pop(
                  SearchFilterSettings(
                    filter: _filter,
                    vinylOnly: _vinylOnly,
                    sort: _sort,
                  ),
                ),
                child: Text(l10n.filtersApply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

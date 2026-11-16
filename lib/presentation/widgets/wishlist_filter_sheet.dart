import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/format_types.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_filter_set.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/saved_search_repository.dart';

class WishlistFilterSheet extends StatefulWidget {
  const WishlistFilterSheet({
    super.key,
    required this.current,
    required this.items,
    required this.metadata,
    this.savedSearchRepository,
  });

  final WishlistFilterSet current;
  final List<WishlistItem> items;
  final List<CachedReleaseMetadata> metadata;
  final SavedSearchRepository? savedSearchRepository;

  @override
  State<WishlistFilterSheet> createState() => _WishlistFilterSheetState();
}

// ---------------------------------------------------------------------------
// Shared sheet helpers (duplicated from collection_filter_sheet to keep private)
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.chips});
  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge),
      ),
      Wrap(spacing: 8, runSpacing: 4, children: chips),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}

// ---------------------------------------------------------------------------

class _WishlistFilterSheetState extends State<WishlistFilterSheet> {
  late Set<int> _decades;
  late Set<String> _formats;
  late Set<String> _labels;
  late Set<String> _genres;
  late Set<String> _styles;
  late Set<WishlistPriority> _priorities;
  late Set<SyncStatus> _syncStatuses;
  late bool? _hasTargetPrice;
  late bool? _hasCover;

  late List<int> _availableDecades;
  late List<String> _availableFormats;
  late List<String> _availableLabels;
  late List<String> _availableGenres;
  late List<String> _availableStyles;

  @override
  void initState() {
    super.initState();
    final f = widget.current;
    _decades = Set.from(f.decades);
    _formats = Set.from(f.formats);
    _labels = Set.from(f.labels);
    _genres = Set.from(f.genres);
    _styles = Set.from(f.styles);
    _priorities = Set.from(f.priorities);
    _syncStatuses = Set.from(f.syncStatuses);
    _hasTargetPrice = f.hasTargetPrice;
    _hasCover = f.hasCover;

    _availableDecades =
        widget.items
            .where((i) => i.year != null)
            .map((i) => (i.year! ~/ 10) * 10)
            .toSet()
            .toList()
          ..sort();
    // One chip per format type (US-147), as in the collection filter.
    _availableFormats =
        widget.items.expand((i) => formatTypes(i.format)).toSet().toList()
          ..sort();
    _availableLabels =
        widget.items
            .where((i) => i.label != null)
            .map((i) => i.label!)
            .toSet()
            .toList()
          ..sort();
    final metaMap = {for (final m in widget.metadata) m.discogsReleaseId: m};
    final releaseIds = widget.items.map((i) => i.discogsReleaseId).toSet();
    _availableGenres =
        releaseIds
            .expand((id) => metaMap[id]?.genres ?? const <String>[])
            .toSet()
            .toList()
          ..sort();
    _availableStyles =
        releaseIds
            .expand((id) => metaMap[id]?.styles ?? const <String>[])
            .toSet()
            .toList()
          ..sort();
  }

  WishlistFilterSet get _current => WishlistFilterSet(
    decades: Set.unmodifiable(_decades),
    formats: Set.unmodifiable(_formats),
    labels: Set.unmodifiable(_labels),
    genres: Set.unmodifiable(_genres),
    styles: Set.unmodifiable(_styles),
    priorities: Set.unmodifiable(_priorities),
    syncStatuses: Set.unmodifiable(_syncStatuses),
    hasTargetPrice: _hasTargetPrice,
    hasCover: _hasCover,
  );

  Future<void> _saveFilter() async {
    final repo = widget.savedSearchRepository;
    if (repo == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save filter'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Filter name'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await repo.save(
      SavedSearch(
        id: const Uuid().v4(),
        name: name,
        type: SavedSearchType.wishlistFilter,
        payloadJson: _current.toJsonString(),
        schemaVersion: 1,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Filter "$name" saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter wishlist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.savedSearchRepository != null)
                  IconButton(
                    key: const Key('save-filter-button'),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    tooltip: 'Save filter',
                    onPressed: _saveFilter,
                  ),
                TextButton(
                  key: const Key('clear-all-button'),
                  onPressed: () => setState(() {
                    _decades.clear();
                    _formats.clear();
                    _labels.clear();
                    _genres.clear();
                    _styles.clear();
                    _priorities.clear();
                    _syncStatuses.clear();
                    _hasTargetPrice = null;
                    _hasCover = null;
                  }),
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (_availableDecades.isNotEmpty)
                  _Section(
                    title: 'Decade',
                    chips: _availableDecades
                        .map(
                          (d) => _Chip(
                            label: '${d}s',
                            selected: _decades.contains(d),
                            onTap: () => setState(
                              () => _decades.contains(d)
                                  ? _decades.remove(d)
                                  : _decades.add(d),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (_availableFormats.isNotEmpty)
                  _Section(
                    title: 'Format',
                    chips: _availableFormats
                        .map(
                          (f) => _Chip(
                            label: f,
                            selected: _formats.contains(f),
                            onTap: () => setState(
                              () => _formats.contains(f)
                                  ? _formats.remove(f)
                                  : _formats.add(f),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (_availableLabels.isNotEmpty)
                  _Section(
                    title: 'Label',
                    chips: _availableLabels
                        .map(
                          (l) => _Chip(
                            label: l,
                            selected: _labels.contains(l),
                            onTap: () => setState(
                              () => _labels.contains(l)
                                  ? _labels.remove(l)
                                  : _labels.add(l),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (_availableGenres.isNotEmpty)
                  _Section(
                    title: 'Genre',
                    chips: _availableGenres
                        .map(
                          (g) => _Chip(
                            label: g,
                            selected: _genres.contains(g),
                            onTap: () => setState(
                              () => _genres.contains(g)
                                  ? _genres.remove(g)
                                  : _genres.add(g),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (_availableStyles.isNotEmpty)
                  _Section(
                    title: 'Style',
                    chips: _availableStyles
                        .map(
                          (s) => _Chip(
                            label: s,
                            selected: _styles.contains(s),
                            onTap: () => setState(
                              () => _styles.contains(s)
                                  ? _styles.remove(s)
                                  : _styles.add(s),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                _Section(
                  title: 'Priority',
                  chips: WishlistPriority.values
                      .map(
                        (p) => _Chip(
                          label: p.label,
                          selected: _priorities.contains(p),
                          onTap: () => setState(
                            () => _priorities.contains(p)
                                ? _priorities.remove(p)
                                : _priorities.add(p),
                          ),
                        ),
                      )
                      .toList(),
                ),
                _Section(
                  title: 'Sync status',
                  chips: SyncStatus.values
                      .map(
                        (s) => _Chip(
                          label: s.name,
                          selected: _syncStatuses.contains(s),
                          onTap: () => setState(
                            () => _syncStatuses.contains(s)
                                ? _syncStatuses.remove(s)
                                : _syncStatuses.add(s),
                          ),
                        ),
                      )
                      .toList(),
                ),
                _Section(
                  title: 'Target price',
                  chips: [
                    _Chip(
                      label: 'Has target price',
                      selected: _hasTargetPrice == true,
                      onTap: () => setState(
                        () => _hasTargetPrice = _hasTargetPrice == true
                            ? null
                            : true,
                      ),
                    ),
                    _Chip(
                      label: 'No target price',
                      selected: _hasTargetPrice == false,
                      onTap: () => setState(
                        () => _hasTargetPrice = _hasTargetPrice == false
                            ? null
                            : false,
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: 'Cover image',
                  chips: [
                    _Chip(
                      label: 'Has cover',
                      selected: _hasCover == true,
                      onTap: () => setState(
                        () => _hasCover = _hasCover == true ? null : true,
                      ),
                    ),
                    _Chip(
                      label: 'No cover',
                      selected: _hasCover == false,
                      onTap: () => setState(
                        () => _hasCover = _hasCover == false ? null : false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('apply-filter-button'),
                onPressed: () => Navigator.of(context).pop(_current),
                child: const Text('Apply'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

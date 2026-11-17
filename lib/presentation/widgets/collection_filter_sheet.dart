import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/collection_filter_set.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/models/format_types.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/saved_search_repository.dart';

class CollectionFilterSheet extends StatefulWidget {
  const CollectionFilterSheet({
    super.key,
    required this.current,
    required this.items,
    required this.metadata,
    this.savedSearchRepository,
  });

  final CollectionFilterSet current;
  final List<CollectionItem> items;
  final List<CachedReleaseMetadata> metadata;
  final SavedSearchRepository? savedSearchRepository;

  @override
  State<CollectionFilterSheet> createState() => _CollectionFilterSheetState();
}

class _CollectionFilterSheetState extends State<CollectionFilterSheet> {
  late Set<int> _decades;
  late Set<String> _formats;
  late Set<String> _labels;
  late Set<String> _genres;
  late Set<String> _styles;
  late Set<RecordCondition> _mediaConditions;
  late Set<RecordCondition> _sleeveConditions;
  late Set<String> _tags;
  late String? _storageLocation;
  late Set<SyncStatus> _syncStatuses;
  late bool? _hasCover;

  // Facets derived from items/metadata
  late List<int> _availableDecades;
  late List<String> _availableFormats;
  late List<String> _availableLabels;
  late List<String> _availableGenres;
  late List<String> _availableStyles;
  late List<String> _availableTags;
  late List<String> _availableLocations;

  @override
  void initState() {
    super.initState();
    final f = widget.current;
    _decades = Set.from(f.decades);
    _formats = Set.from(f.formats);
    _labels = Set.from(f.labels);
    _genres = Set.from(f.genres);
    _styles = Set.from(f.styles);
    _mediaConditions = Set.from(f.mediaConditions);
    _sleeveConditions = Set.from(f.sleeveConditions);
    _tags = Set.from(f.tags);
    _storageLocation = f.storageLocation;
    _syncStatuses = Set.from(f.syncStatuses);
    _hasCover = f.hasCover;

    _availableDecades =
        widget.items
            .where((i) => i.year != null)
            .map((i) => (i.year! ~/ 10) * 10)
            .toSet()
            .toList()
          ..sort();
    // One chip per format type (Vinyl, CD, File…), not per full format
    // string (US-143).
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
    _availableTags = widget.items.expand((i) => i.tags).toSet().toList()
      ..sort();
    _availableLocations =
        widget.items
            .where((i) => i.storageLocation != null)
            .map((i) => i.storageLocation!)
            .toSet()
            .toList()
          ..sort();
  }

  CollectionFilterSet get _current => CollectionFilterSet(
    decades: Set.unmodifiable(_decades),
    formats: Set.unmodifiable(_formats),
    labels: Set.unmodifiable(_labels),
    genres: Set.unmodifiable(_genres),
    styles: Set.unmodifiable(_styles),
    mediaConditions: Set.unmodifiable(_mediaConditions),
    sleeveConditions: Set.unmodifiable(_sleeveConditions),
    tags: Set.unmodifiable(_tags),
    storageLocation: _storageLocation,
    syncStatuses: Set.unmodifiable(_syncStatuses),
    hasCover: _hasCover,
  );

  Future<void> _saveFilter() async {
    final repo = widget.savedSearchRepository;
    if (repo == null) return;
    final name = await _askName(context);
    if (name == null || name.isEmpty) return;
    final filter = _current;
    await repo.save(
      SavedSearch(
        id: const Uuid().v4(),
        name: name,
        type: SavedSearchType.collectionFilter,
        payloadJson: filter.toJsonString(),
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
                    'Filter collection',
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
                    _mediaConditions.clear();
                    _sleeveConditions.clear();
                    _tags.clear();
                    _storageLocation = null;
                    _syncStatuses.clear();
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
                    chips: _availableDecades.map((d) {
                      final label = '${d}s';
                      return _Chip(
                        label: label,
                        selected: _decades.contains(d),
                        onTap: () => setState(
                          () => _decades.contains(d)
                              ? _decades.remove(d)
                              : _decades.add(d),
                        ),
                      );
                    }).toList(),
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
                  title: 'Media condition',
                  chips: RecordCondition.values
                      .where((c) => c != RecordCondition.notSet)
                      .map(
                        (c) => _Chip(
                          label: c.abbreviation,
                          selected: _mediaConditions.contains(c),
                          onTap: () => setState(
                            () => _mediaConditions.contains(c)
                                ? _mediaConditions.remove(c)
                                : _mediaConditions.add(c),
                          ),
                        ),
                      )
                      .toList(),
                ),
                _Section(
                  title: 'Sleeve condition',
                  chips: RecordCondition.values
                      .where((c) => c != RecordCondition.notSet)
                      .map(
                        (c) => _Chip(
                          label: c.abbreviation,
                          selected: _sleeveConditions.contains(c),
                          onTap: () => setState(
                            () => _sleeveConditions.contains(c)
                                ? _sleeveConditions.remove(c)
                                : _sleeveConditions.add(c),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (_availableTags.isNotEmpty)
                  _Section(
                    title: 'Tag',
                    chips: _availableTags
                        .map(
                          (t) => _Chip(
                            label: t,
                            selected: _tags.contains(t),
                            onTap: () => setState(
                              () => _tags.contains(t)
                                  ? _tags.remove(t)
                                  : _tags.add(t),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (_availableLocations.isNotEmpty)
                  _Section(
                    title: 'Storage location',
                    chips: _availableLocations
                        .map(
                          (loc) => _Chip(
                            label: loc,
                            selected: _storageLocation == loc,
                            onTap: () => setState(
                              () => _storageLocation == loc
                                  ? _storageLocation = null
                                  : _storageLocation = loc,
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

Future<String?> _askName(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
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
}

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

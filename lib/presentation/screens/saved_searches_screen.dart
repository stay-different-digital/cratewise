import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../app/app_repositories.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/repositories/saved_search_repository.dart';

final _dateFmt = DateFormat.yMMMd();

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key, this.filterType, this.repository});

  /// When set, only shows saved searches of this type.
  final SavedSearchType? filterType;
  final SavedSearchRepository? repository;

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  late final SavedSearchRepository _repository;
  List<SavedSearch> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? AppRepositoriesScope.of(context).savedSearch;
    _load();
  }

  Future<void> _load() async {
    final type = widget.filterType;
    final items = type == null
        ? await _repository.getAll()
        : await _repository.getByType(type);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _rename(SavedSearch item) async {
    final controller = TextEditingController(text: item.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
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
    if (name == null || name.isEmpty || !mounted) return;
    await _repository.updateName(item.id, name);
    _load();
  }

  Future<void> _delete(SavedSearch item) async {
    await _repository.remove(item.id);
    if (!mounted) return;
    setState(() => _items = _items.where((i) => i.id != item.id).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _repository.save(item);
            _load();
          },
        ),
      ),
    );
  }

  void _open(SavedSearch item) {
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.filterType == null
        ? 'Saved searches'
        : switch (widget.filterType!) {
            SavedSearchType.discogsSearch => 'Saved searches',
            SavedSearchType.collectionFilter => 'Saved filters',
            SavedSearchType.wishlistFilter => 'Saved filters',
          };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? _EmptyState(filterType: widget.filterType)
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  onDismissed: (_) => _delete(item),
                  child: ListTile(
                    leading: _TypeIcon(type: item.type),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.type.displayName} · last used ${_dateFmt.format(item.lastUsedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: PopupMenuButton<_Action>(
                      onSelected: (action) {
                        if (action == _Action.rename) _rename(item);
                        if (action == _Action.delete) _delete(item);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: _Action.rename,
                          child: Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: _Action.delete,
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () => _open(item),
                  ),
                );
              },
            ),
    );
  }
}

enum _Action { rename, delete }

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});
  final SavedSearchType type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      SavedSearchType.discogsSearch => Icons.search,
      SavedSearchType.collectionFilter => Icons.filter_list,
      SavedSearchType.wishlistFilter => Icons.favorite_outline,
    };
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filterType});
  final SavedSearchType? filterType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmarks_outlined,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              filterType == null
                  ? 'No saved searches yet'
                  : switch (filterType!) {
                      SavedSearchType.discogsSearch => 'No saved searches yet',
                      _ => 'No saved filters yet',
                    },
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              filterType == null || filterType == SavedSearchType.discogsSearch
                  ? 'Tap the bookmark icon while searching to save a query.'
                  : 'Tap the bookmark icon in the filter sheet to save a filter.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

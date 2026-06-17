import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../application/services/thumbnail_cache_service.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../shared/import_notifier.dart';
import '../../shared/route_observer.dart';
import '../widgets/collection_item_card.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _CollectionState {
  const _CollectionState();
}

class _Loading extends _CollectionState {
  const _Loading();
}

class _Loaded extends _CollectionState {
  const _Loaded(this.items);
  final List<CollectionItem> items;
}

class _CollectionError extends _CollectionState {
  const _CollectionError();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    this.repository,
    this.thumbnailRepository,
    this.thumbnailCacheService,
  });

  final CollectionRepository? repository;
  final ThumbnailRepository? thumbnailRepository;
  final ThumbnailCacheService? thumbnailCacheService;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with RouteAware {
  late final CollectionRepository _repository;
  late final ThumbnailRepository _thumbnailRepository;
  late final ThumbnailCacheService _thumbnailCacheService;
  AppDatabase? _ownedDb;
  _CollectionState _state = const _Loading();
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _debouncedQuery = '';

  @override
  void initState() {
    super.initState();
    _thumbnailRepository =
        widget.thumbnailRepository ?? LocalThumbnailRepository();
    _thumbnailCacheService =
        widget.thumbnailCacheService ??
        ThumbnailCacheService(repository: _thumbnailRepository);
    if (widget.repository != null) {
      _repository = widget.repository!;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _repository = LocalCollectionRepository(db);
    }
    _load();
    collectionImportNotifier.addListener(_onImportNotification);
  }

  void _onImportNotification() {
    if (mounted) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => _refresh();

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final items = await _repository.getAll();
      if (!mounted) return;
      setState(() => _state = _Loaded(items));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _CollectionError());
    }
  }

  Future<void> _refresh() async {
    try {
      final items = await _repository.getAll();
      if (!mounted) return;
      setState(() => _state = _Loaded(items));
    } catch (_) {
      if (!mounted) return;
      if (_state is _Loaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not refresh your collection. Please try again.',
            ),
          ),
        );
      } else {
        setState(() => _state = const _CollectionError());
      }
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    collectionImportNotifier.removeListener(_onImportNotification);
    _debounce?.cancel();
    _ownedDb?.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.search,
            onChanged: (_) {
              setState(() {}); // immediate: clear-button visibility
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() => _debouncedQuery = _searchController.text);
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Search your collection…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _debounce?.cancel();
                        _searchController.clear();
                        setState(() => _debouncedQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 20,
              ),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _Loading() => const Center(child: CircularProgressIndicator()),
      _Loaded(:final items) when items.isEmpty => RefreshIndicator(
        onRefresh: _refresh,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _EmptyCollectionState())],
        ),
      ),
      _Loaded(:final items) => _buildLoadedList(items),
      _CollectionError() => _CollectionErrorState(onRetry: _load),
    };
  }

  Widget _buildLoadedList(List<CollectionItem> items) {
    final q = _debouncedQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? items
        : items
              .where(
                (i) =>
                    i.artist.toLowerCase().contains(q) ||
                    i.title.toLowerCase().contains(q),
              )
              .toList();

    if (filtered.isEmpty) {
      return _NoSearchResults(query: _debouncedQuery.trim());
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _CollectionList(
        items: filtered,
        thumbnailCacheService: _thumbnailCacheService,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _CollectionList extends StatelessWidget {
  const _CollectionList({
    required this.items,
    required this.thumbnailCacheService,
  });

  final List<CollectionItem> items;
  final ThumbnailCacheService thumbnailCacheService;

  static const _kWideBreakpoint = 700.0;
  static const _kGridItemExtent = 124.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= _kWideBreakpoint
          ? _buildGrid(context)
          : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => CollectionItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailCacheService: thumbnailCacheService,
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: _kGridItemExtent,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => CollectionItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailCacheService: thumbnailCacheService,
      ),
    );
  }

  void _openDetail(BuildContext context, int index) {
    context.push(AppRoutes.collectionDetail(items[index].id));
  }
}

class _EmptyCollectionState extends StatelessWidget {
  const _EmptyCollectionState();

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
              Icons.album_outlined,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Your collection is empty',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your collection is saved on this device and works without internet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use the Search tab to find releases and add them.',
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

class _CollectionErrorState extends StatelessWidget {
  const _CollectionErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load your collection from device storage.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

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
              Icons.search_off,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different artist or title.',
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

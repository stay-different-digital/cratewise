import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/app_repositories.dart';
import '../../app/router.dart';
import '../../application/services/thumbnail_cache_service.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../shared/import_notifier.dart';
import '../../shared/route_observer.dart';
import '../widgets/wishlist_item_card.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _WishlistState {
  const _WishlistState();
}

class _Loading extends _WishlistState {
  const _Loading();
}

class _Loaded extends _WishlistState {
  const _Loaded(this.items);
  final List<WishlistItem> items;
}

class _WishlistError extends _WishlistState {
  const _WishlistError();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({
    super.key,
    this.repository,
    this.thumbnailRepository,
    this.thumbnailCacheService,
    this.accelerometerStream,
  });

  final WishlistRepository? repository;
  final ThumbnailRepository? thumbnailRepository;
  final ThumbnailCacheService? thumbnailCacheService;
  final Stream<AccelerometerEvent>? accelerometerStream;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with RouteAware {
  late final WishlistRepository _repository;
  late final ThumbnailRepository _thumbnailRepository;
  late final ThumbnailCacheService _thumbnailCacheService;
  bool _ownsThumbService = false;
  _WishlistState _state = const _Loading();
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _debouncedQuery = '';
  static const _kShakeThreshold = 20.0;
  static const _kShakeCooldown = Duration(seconds: 2);
  StreamSubscription<AccelerometerEvent>? _shakeSub;
  DateTime _lastShake = DateTime(0);
  bool _shakeActive = true;

  @override
  void initState() {
    super.initState();
    _thumbnailRepository =
        widget.thumbnailRepository ?? LocalThumbnailRepository();
    _ownsThumbService = widget.thumbnailCacheService == null;
    _thumbnailCacheService =
        widget.thumbnailCacheService ??
        ThumbnailCacheService(repository: _thumbnailRepository);
    _repository =
        widget.repository ?? AppRepositoriesScope.of(context).wishlist;
    _load();
    wishlistImportNotifier.addListener(_onImportNotification);
    _shakeSub = (widget.accelerometerStream ?? accelerometerEventStream())
        .listen(_onAccelerometer);
  }

  void _onImportNotification() {
    if (mounted) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) wishlistRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => _shakeActive = false;

  @override
  void didPopNext() {
    _shakeActive = true;
    _refresh();
  }

  Future<void> _load() async {
    setState(() => _state = const _Loading());
    try {
      final items = await _repository.getAll();
      if (!mounted) return;
      setState(() => _state = _Loaded(items));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _WishlistError());
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
            content: Text('Could not refresh your wishlist. Please try again.'),
          ),
        );
      } else {
        setState(() => _state = const _WishlistError());
      }
    }
  }

  @override
  void dispose() {
    wishlistRouteObserver.unsubscribe(this);
    wishlistImportNotifier.removeListener(_onImportNotification);
    _shakeSub?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    if (_ownsThumbService) _thumbnailCacheService.close();
    super.dispose();
  }

  Widget _buildBody() {
    return switch (_state) {
      _Loading() => const Center(child: CircularProgressIndicator()),
      _Loaded(:final items) when items.isEmpty => RefreshIndicator(
        onRefresh: _refresh,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _EmptyWishlistState())],
        ),
      ),
      _Loaded(:final items) => _buildLoadedList(items),
      _WishlistError() => _WishlistErrorState(onRetry: _load),
    };
  }

  Widget _buildLoadedList(List<WishlistItem> items) {
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
      child: _WishlistList(
        items: filtered,
        thumbnailCacheService: _thumbnailCacheService,
      ),
    );
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!mounted || !_shakeActive) return;
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null && shell.currentIndex != 2) return;
    final x = event.x, y = event.y, z = event.z;
    if (sqrt(x * x + y * y + z * z) < _kShakeThreshold) return;
    final now = DateTime.now();
    if (now.difference(_lastShake) < _kShakeCooldown) return;
    _lastShake = now;
    final state = _state;
    if (state is! _Loaded || state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Je verlanglijst is leeg — voeg eerst platen toe.'),
        ),
      );
      return;
    }
    final item = state.items[Random().nextInt(state.items.length)];
    context.push(AppRoutes.wishlistDetail(item.id));
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
              hintText: 'Search your wishlist…',
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
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _WishlistList extends StatelessWidget {
  const _WishlistList({
    required this.items,
    required this.thumbnailCacheService,
  });

  final List<WishlistItem> items;
  final ThumbnailCacheService thumbnailCacheService;

  static const _kWideBreakpoint = 700.0;
  static const _kGridItemExtent = 124.0;

  void _openDetail(BuildContext context, int index) {
    context.push(AppRoutes.wishlistDetail(items[index].id));
  }

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
      // Match the collection list's spacing (US/QA: equal density across tabs).
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => WishlistItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailCacheService: thumbnailCacheService,
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      // Match the collection grid's spacing (US/QA: equal density across tabs).
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: _kGridItemExtent,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => WishlistItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailCacheService: thumbnailCacheService,
      ),
    );
  }
}

class _EmptyWishlistState extends StatelessWidget {
  const _EmptyWishlistState();

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
              Icons.bookmark_border,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('Your wishlist is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Your wishlist is saved on this device and works without internet.',
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

class _WishlistErrorState extends StatelessWidget {
  const _WishlistErrorState({required this.onRetry});

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
              'Could not load your wishlist from device storage.',
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

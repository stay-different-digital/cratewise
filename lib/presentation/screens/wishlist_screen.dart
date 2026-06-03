import 'package:flutter/material.dart';

import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_thumbnail_repository.dart';
import '../../infrastructure/local_database/local_wishlist_repository.dart';
import '../widgets/wishlist_item_card.dart';
import 'wishlist_detail_screen.dart';

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
  const WishlistScreen({super.key, this.repository, this.thumbnailRepository});

  final WishlistRepository? repository;
  final ThumbnailRepository? thumbnailRepository;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late final WishlistRepository _repository;
  late final ThumbnailRepository _thumbnailRepository;
  AppDatabase? _ownedDb;
  _WishlistState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    _thumbnailRepository =
        widget.thumbnailRepository ?? LocalThumbnailRepository();
    if (widget.repository != null) {
      _repository = widget.repository!;
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _repository = LocalWishlistRepository(db);
    }
    _load();
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
    _ownedDb?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _Loading() => const Center(child: CircularProgressIndicator()),
      _Loaded(:final items) when items.isEmpty => const _EmptyWishlistState(),
      _Loaded(:final items) => RefreshIndicator(
        onRefresh: _refresh,
        child: _WishlistList(
          items: items,
          repository: _repository,
          thumbnailRepository: _thumbnailRepository,
        ),
      ),
      _WishlistError() => _WishlistErrorState(onRetry: _load),
    };
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _WishlistList extends StatelessWidget {
  const _WishlistList({
    required this.items,
    required this.repository,
    required this.thumbnailRepository,
  });

  final List<WishlistItem> items;
  final WishlistRepository repository;
  final ThumbnailRepository thumbnailRepository;

  static const _kWideBreakpoint = 700.0;
  static const _kGridItemExtent = 124.0;

  void _openDetail(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WishlistDetailScreen(
          itemId: items[index].id,
          repository: repository,
          thumbnailRepository: thumbnailRepository,
        ),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => WishlistItemCard(
        item: items[index],
        onTap: () => _openDetail(context, index),
        thumbnailRepository: thumbnailRepository,
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
        thumbnailRepository: thumbnailRepository,
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

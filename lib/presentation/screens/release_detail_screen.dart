import 'package:flutter/material.dart';

import '../../application/services/discogs_release_detail_service.dart';
import '../../application/use_cases/add_to_collection_use_case.dart';
import '../../application/use_cases/add_to_wishlist_use_case.dart';
import '../../domain/models/cached_release_metadata.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/repositories/cached_release_metadata_repository.dart';
import '../../infrastructure/local_database/app_database.dart';
import '../../infrastructure/local_database/local_collection_repository.dart';
import '../../infrastructure/local_database/local_cached_release_metadata_repository.dart';
import '../../infrastructure/local_database/local_wishlist_repository.dart';
import '../../shared/errors/app_error.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _DetailState {
  const _DetailState();
}

class _Loading extends _DetailState {
  const _Loading();
}

class _Loaded extends _DetailState {
  const _Loaded(this.detail);
  final ReleaseDetail detail;
}

class _CachedLoaded extends _DetailState {
  _CachedLoaded(this.metadata);
  final CachedReleaseMetadata metadata;
}

class _DetailError extends _DetailState {
  const _DetailError(this.error);
  final AppError error;
}

// ---------------------------------------------------------------------------
// Add state
// ---------------------------------------------------------------------------

enum _AddState { idle, adding, added, duplicate }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ReleaseDetailScreen extends StatefulWidget {
  const ReleaseDetailScreen({
    super.key,
    required this.releaseId,
    this.detailService,
    this.addToCollectionUseCase,
    this.addToWishlistUseCase,
    this.cacheRepository,
  });

  final int releaseId;
  final DiscogsReleaseDetailService? detailService;
  final AddToCollectionUseCase? addToCollectionUseCase;
  final AddToWishlistUseCase? addToWishlistUseCase;
  final CachedReleaseMetadataRepository? cacheRepository;

  @override
  State<ReleaseDetailScreen> createState() => _ReleaseDetailScreenState();
}

class _ReleaseDetailScreenState extends State<ReleaseDetailScreen> {
  late final DiscogsReleaseDetailService _service;
  late final AddToCollectionUseCase _addUseCase;
  late final AddToWishlistUseCase _addWishlistUseCase;
  late final CachedReleaseMetadataRepository? _cacheRepository;
  AppDatabase? _ownedDb;

  _DetailState _state = const _Loading();
  _AddState _addState = _AddState.idle;
  _AddState _addWishlistState = _AddState.idle;

  @override
  void initState() {
    super.initState();
    final collectionProvided = widget.addToCollectionUseCase != null;
    final wishlistProvided = widget.addToWishlistUseCase != null;
    if (collectionProvided && wishlistProvided) {
      _addUseCase = widget.addToCollectionUseCase!;
      _addWishlistUseCase = widget.addToWishlistUseCase!;
      _cacheRepository = widget.cacheRepository;
      _service = widget.detailService ??
          DiscogsReleaseDetailService(
            cacheRepository: _cacheRepository,
          );
    } else {
      final db = AppDatabase(openAppDatabase());
      _ownedDb = db;
      _addUseCase = widget.addToCollectionUseCase ??
          AddToCollectionUseCase(LocalCollectionRepository(db));
      _addWishlistUseCase = widget.addToWishlistUseCase ??
          AddToWishlistUseCase(LocalWishlistRepository(db));
      _cacheRepository =
          widget.cacheRepository ?? LocalCachedReleaseMetadataRepository(db);
      _service = widget.detailService ??
          DiscogsReleaseDetailService(
            cacheRepository: _cacheRepository,
          );
    }
    _fetch();
  }

  @override
  void dispose() {
    _ownedDb?.close();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final detail = await _service.fetchDetail(widget.releaseId);
      if (!mounted) return;
      setState(() => _state = _Loaded(detail));
    } on AppError catch (e) {
      final cached = await _tryLoadFromCache();
      if (!mounted) return;
      if (cached != null) {
        setState(() => _state = _CachedLoaded(cached));
      } else {
        setState(() => _state = _DetailError(e));
      }
    }
  }

  Future<CachedReleaseMetadata?> _tryLoadFromCache() async {
    if (_cacheRepository == null) return null;
    try {
      return await _cacheRepository.getByReleaseId(widget.releaseId);
    } catch (_) {
      return null;
    }
  }

  void _retry() {
    setState(() => _state = const _Loading());
    _fetch();
  }

  ReleaseDetail? _currentDetail() {
    final state = _state;
    if (state is _Loaded) return state.detail;
    if (state is _CachedLoaded) return _cachedMetadataToDetail(state.metadata);
    return null;
  }

  Future<void> _handleAdd() async {
    final detail = _currentDetail();
    if (detail == null) return;
    setState(() => _addState = _AddState.adding);
    final result = await _addUseCase.execute(detail);
    if (!mounted) return;
    switch (result) {
      case AddToCollectionSuccess():
        setState(() => _addState = _AddState.added);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to your collection')),
        );
      case AddToCollectionDuplicate():
        setState(() => _addState = _AddState.duplicate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already in your collection')),
        );
    }
  }

  Future<void> _handleAddToWishlist() async {
    final detail = _currentDetail();
    if (detail == null) return;
    setState(() => _addWishlistState = _AddState.adding);
    final result = await _addWishlistUseCase.execute(detail);
    if (!mounted) return;
    switch (result) {
      case AddToWishlistSuccess():
        setState(() => _addWishlistState = _AddState.added);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to your wishlist')),
        );
      case AddToWishlistDuplicate():
        setState(() => _addWishlistState = _AddState.duplicate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already in your wishlist')),
        );
    }
  }

  static bool _isRetriable(AppError e) =>
      e is! NoTokenError && e is! InvalidTokenError;

  String get _appBarTitle {
    final state = _state;
    if (state is _Loaded && state.detail.title.isNotEmpty) {
      return state.detail.title;
    }
    if (state is _CachedLoaded && state.metadata.title.isNotEmpty) {
      return state.metadata.title;
    }
    return 'Release Detail';
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
      ),
      body: switch (state) {
        _Loading() => const _SkeletonBody(),
        _DetailError(:final error) => _ErrorBody(
            error: error,
            onRetry: _isRetriable(error) ? _retry : null,
          ),
        _Loaded(:final detail) => _DetailBody(detail: detail),
        _CachedLoaded(:final metadata) => _CachedDetailBody(metadata: metadata),
      },
      bottomNavigationBar: (state is _Loaded || state is _CachedLoaded)
          ? _AddActionsBar(
              collectionState: _addState,
              wishlistState: _addWishlistState,
              onAddCollection: _handleAdd,
              onAddToWishlist: _handleAddToWishlist,
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Add actions bar (collection + wishlist)
// ---------------------------------------------------------------------------

class _AddActionsBar extends StatelessWidget {
  const _AddActionsBar({
    required this.collectionState,
    required this.wishlistState,
    required this.onAddCollection,
    required this.onAddToWishlist,
  });

  final _AddState collectionState;
  final _AddState wishlistState;
  final VoidCallback onAddCollection;
  final VoidCallback onAddToWishlist;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: _buildCollectionButton(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _buildWishlistButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionButton() {
    final Widget icon;
    final String label;
    final VoidCallback? onPressed;

    switch (collectionState) {
      case _AddState.idle:
        icon = const Icon(Icons.add);
        label = 'Add to Collection';
        onPressed = onAddCollection;
      case _AddState.adding:
        icon = const Icon(Icons.add);
        label = 'Adding…';
        onPressed = null;
      case _AddState.added || _AddState.duplicate:
        icon = const Icon(Icons.check);
        label = 'In Collection';
        onPressed = null;
    }

    return FilledButton.icon(
      key: const Key('add-to-collection-button'),
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
    );
  }

  Widget _buildWishlistButton() {
    final Widget icon;
    final String label;
    final VoidCallback? onPressed;

    switch (wishlistState) {
      case _AddState.idle:
        icon = const Icon(Icons.bookmark_border);
        label = 'Add to Wishlist';
        onPressed = onAddToWishlist;
      case _AddState.adding:
        icon = const Icon(Icons.bookmark_border);
        label = 'Adding…';
        onPressed = null;
      case _AddState.added || _AddState.duplicate:
        icon = const Icon(Icons.bookmark);
        label = 'In Wishlist';
        onPressed = null;
    }

    return OutlinedButton.icon(
      key: const Key('add-to-wishlist-button'),
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget block({double? width, required double height}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return SingleChildScrollView(
      key: const Key('release-detail-loading'),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 1, child: ColoredBox(color: color)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(width: 200, height: 22),
                const SizedBox(height: 8),
                block(width: 130, height: 16),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      block(width: 80, height: 12),
                      const SizedBox(width: 16),
                      Expanded(child: block(height: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: block(width: 80, height: 14),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      block(width: 28, height: 12),
                      const SizedBox(width: 12),
                      Expanded(child: block(height: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, this.onRetry});

  final AppError error;
  final VoidCallback? onRetry;

  String get _message => switch (error) {
        NoTokenError() =>
          'Connect a Discogs token in Settings to view release details.',
        InvalidTokenError() =>
          'Your Discogs token is not valid. Go to Settings to reconnect.',
        RateLimitedError() => 'Too many requests. Wait a moment and try again.',
        NetworkError() => 'No internet connection.',
        StorageError() => 'Could not load your saved token. Try again.',
        DiscogsUnavailableError() => 'Could not reach Discogs. Try again.',
        UnexpectedApiError() => 'Could not reach Discogs. Try again.',
      };

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
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail body
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final ReleaseDetail detail;

  static const _kWideBreakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= _kWideBreakpoint
              ? _buildWide(context)
              : _buildNarrow(context),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (detail.coverUrl != null) _CoverImage(url: detail.coverUrl!),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _TitleArtist(detail: detail),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _InfoRows(detail: detail),
          ),
          if (detail.tracklist.isNotEmpty)
            _TracklistSection(tracks: detail.tracklist),
          if (detail.notes != null && detail.notes!.isNotEmpty)
            _NotesSection(notes: detail.notes!),
          if (detail.identifiers.isNotEmpty)
            _IdentifiersSection(identifiers: detail.identifiers),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (detail.coverUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _CoverImage(url: detail.coverUrl!),
                  )
                else
                  AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.album,
                          size: 72,
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _TitleArtist(detail: detail),
                const SizedBox(height: 16),
                _InfoRows(detail: detail),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (detail.tracklist.isNotEmpty)
                  _TracklistSection(tracks: detail.tracklist),
                if (detail.notes != null && detail.notes!.isNotEmpty)
                  _NotesSection(notes: detail.notes!),
                if (detail.identifiers.isNotEmpty)
                  _IdentifiersSection(identifiers: detail.identifiers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cached detail body
// ---------------------------------------------------------------------------

class _CachedDetailBody extends StatelessWidget {
  const _CachedDetailBody({required this.metadata});

  final CachedReleaseMetadata metadata;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CachedBanner(fetchedAt: metadata.fetchedAt),
        Expanded(child: _DetailBody(detail: _cachedMetadataToDetail(metadata))),
      ],
    );
  }
}

class _CachedBanner extends StatelessWidget {
  const _CachedBanner({required this.fetchedAt});

  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.offline_pin_outlined,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Showing saved data · last updated ${_formatCachedDate(fetchedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCachedDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

ReleaseDetail _cachedMetadataToDetail(CachedReleaseMetadata m) => ReleaseDetail(
      id: m.discogsReleaseId,
      title: m.title,
      artist: m.artist,
      label: m.label ?? '',
      catno: m.catno ?? '',
      format: m.format ?? '',
      country: m.country ?? '',
      year: m.year,
      genres: m.genres,
      styles: m.styles,
      tracklist: m.tracklist
          .map((t) => ReleaseTrack(position: '', title: t, duration: ''))
          .toList(),
      notes: m.notes,
      coverUrl: m.coverUrl,
      identifiers: m.barcodes
          .map((b) => ReleaseIdentifier(type: 'Barcode', value: b))
          .toList(),
    );

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _TitleArtist extends StatelessWidget {
  const _TitleArtist({required this.detail});

  final ReleaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.title.isEmpty ? '(Untitled)' : detail.title,
          style: theme.textTheme.headlineSmall,
        ),
        if (detail.artist.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            detail.artist,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRows extends StatelessWidget {
  const _InfoRows({required this.detail});

  final ReleaseDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (detail.label.isNotEmpty)
          _InfoRow(
            'Label',
            detail.catno.isNotEmpty
                ? '${detail.label} — ${detail.catno}'
                : detail.label,
          ),
        if (detail.format.isNotEmpty) _InfoRow('Format', detail.format),
        if (detail.country.isNotEmpty) _InfoRow('Country', detail.country),
        if (detail.year != null) _InfoRow('Released', '${detail.year}'),
        if (detail.genres.isNotEmpty)
          _InfoRow('Genre', detail.genres.join(', ')),
        if (detail.styles.isNotEmpty)
          _InfoRow('Style', detail.styles.join(', ')),
        _InfoRow('Discogs ID', '#${detail.id}'),
      ],
    );
  }
}

class _TracklistSection extends StatelessWidget {
  const _TracklistSection({required this.tracks});

  final List<ReleaseTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Tracklist'),
        ...tracks.map((t) => _TrackRow(track: t)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Notes'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _IdentifiersSection extends StatelessWidget {
  const _IdentifiersSection({required this.identifiers});

  final List<ReleaseIdentifier> identifiers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const _SectionHeader('Identifiers'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children:
                identifiers.map((i) => _InfoRow(i.type, i.value)).toList(),
          ),
        ),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      key: const Key('release-cover-image'),
      aspectRatio: 1,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: Icon(
              Icons.album,
              size: 72,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track});

  final ReleaseTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              track.position,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(track.title, style: theme.textTheme.bodyMedium),
          ),
          if (track.duration.isNotEmpty)
            Text(
              track.duration,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

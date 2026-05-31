import 'package:flutter/material.dart';

import '../../application/services/discogs_release_detail_service.dart';
import '../../domain/models/release_detail.dart';
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

class _DetailError extends _DetailState {
  const _DetailError(this.error);
  final AppError error;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ReleaseDetailScreen extends StatefulWidget {
  const ReleaseDetailScreen({
    super.key,
    required this.releaseId,
    this.detailService,
  });

  final int releaseId;
  final DiscogsReleaseDetailService? detailService;

  @override
  State<ReleaseDetailScreen> createState() => _ReleaseDetailScreenState();
}

class _ReleaseDetailScreenState extends State<ReleaseDetailScreen> {
  late final DiscogsReleaseDetailService _service;
  _DetailState _state = const _Loading();

  @override
  void initState() {
    super.initState();
    _service = widget.detailService ?? DiscogsReleaseDetailService();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final detail = await _service.fetchDetail(widget.releaseId);
      if (!mounted) return;
      setState(() => _state = _Loaded(detail));
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _state = _DetailError(e));
    }
  }

  void _retry() {
    setState(() => _state = const _Loading());
    _fetch();
  }

  static bool _isRetriable(AppError e) =>
      e is! NoTokenError && e is! InvalidTokenError;

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          state is _Loaded && state.detail.title.isNotEmpty
              ? state.detail.title
              : 'Release Detail',
        ),
      ),
      body: switch (state) {
        _Loading() => const _SkeletonBody(),
        _DetailError(:final error) => _ErrorBody(
            error: error,
            onRetry: _isRetriable(error) ? _retry : null,
          ),
        _Loaded(:final detail) => _DetailBody(detail: detail),
      },
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

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Release Detail')),
      body: switch (_state) {
        _Loading() => const Center(child: CircularProgressIndicator()),
        _DetailError(:final error) => _ErrorBody(error: error),
        _Loaded(:final detail) => _DetailBody(detail: detail),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final AppError error;

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
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final ReleaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (detail.coverUrl != null) _CoverImage(url: detail.coverUrl!),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.title, style: theme.textTheme.headlineSmall),
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
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (detail.label.isNotEmpty)
                  _InfoRow(
                    'Label',
                    detail.catno.isNotEmpty
                        ? '${detail.label} — ${detail.catno}'
                        : detail.label,
                  ),
                if (detail.format.isNotEmpty)
                  _InfoRow('Format', detail.format),
                if (detail.country.isNotEmpty)
                  _InfoRow('Country', detail.country),
                if (detail.year != null)
                  _InfoRow('Released', '${detail.year}'),
                if (detail.genres.isNotEmpty)
                  _InfoRow('Genre', detail.genres.join(', ')),
                if (detail.styles.isNotEmpty)
                  _InfoRow('Style', detail.styles.join(', ')),
                _InfoRow('Discogs ID', '#${detail.id}'),
              ],
            ),
          ),
          if (detail.tracklist.isNotEmpty) ...[
            const Divider(height: 1),
            const _SectionHeader('Tracklist'),
            ...detail.tracklist.map((t) => _TrackRow(track: t)),
            const SizedBox(height: 8),
          ],
          if (detail.notes != null && detail.notes!.isNotEmpty) ...[
            const Divider(height: 1),
            const _SectionHeader('Notes'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(detail.notes!, style: theme.textTheme.bodyMedium),
            ),
          ],
          if (detail.identifiers.isNotEmpty) ...[
            const Divider(height: 1),
            const _SectionHeader('Identifiers'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: detail.identifiers
                    .map((i) => _InfoRow(i.type, i.value))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
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

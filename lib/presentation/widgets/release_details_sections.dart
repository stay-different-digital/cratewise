import 'package:material_ui/material_ui.dart';

import '../../domain/models/release_detail.dart';

/// Shared sections for showing Discogs release details on the collection
/// and wishlist detail screens (US-74/US-76). Obtain the [ReleaseDetail]
/// via `DiscogsReleaseDetailService.getCachedOrFetch` — that is the
/// standard, cache-first way to load these.

class ReleaseTracklistSection extends StatelessWidget {
  const ReleaseTracklistSection({super.key, required this.tracks});

  final List<ReleaseTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const ReleaseSectionHeader('Tracklist'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              for (final track in tracks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: Text(
                          track.title,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (track.duration.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          track.duration,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Discogs release notes — distinct from the user's personal notes section.
class ReleaseNotesSection extends StatelessWidget {
  const ReleaseNotesSection({super.key, required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const ReleaseSectionHeader('Release Notes'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class ReleaseSectionHeader extends StatelessWidget {
  const ReleaseSectionHeader(this.title, {super.key});

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

import 'package:material_ui/material_ui.dart';

import '../../domain/models/release_search_result.dart';

class ReleaseSearchResultCard extends StatelessWidget {
  const ReleaseSearchResultCard({
    super.key,
    required this.result,
    this.onTap,
    this.inCollection = false,
    this.onWishlist = false,
  });

  final ReleaseSearchResult result;
  final VoidCallback? onTap;

  /// Whether this release is already in the local collection (US-80).
  final bool inCollection;

  /// Whether this release is already on the local wishlist (US-80).
  final bool onWishlist;

  String get _metaLine {
    final parts = <String>[
      result.label,
      if (result.year != null) '${result.year}',
      result.format,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverThumbnail(theme: theme, coverUrl: result.coverUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.artist,
                      style: theme.textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.title,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _metaLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '#${result.id}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    if (result.country.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.country,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (inCollection || onWishlist) ...[
                const SizedBox(width: 8),
                _MembershipBadges(
                  theme: theme,
                  inCollection: inCollection,
                  onWishlist: onWishlist,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing icons showing whether the release is already in the user's
/// collection and/or on their wishlist. Renders nothing when neither applies,
/// so cards without membership keep their layout unchanged (US-80).
class _MembershipBadges extends StatelessWidget {
  const _MembershipBadges({
    required this.theme,
    required this.inCollection,
    required this.onWishlist,
  });

  final ThemeData theme;
  final bool inCollection;
  final bool onWishlist;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inCollection)
          Tooltip(
            message: 'In your collection',
            child: Icon(
              Icons.library_music,
              key: const Key('in-collection-icon'),
              size: 20,
              color: theme.colorScheme.primary,
              semanticLabel: 'In your collection',
            ),
          ),
        if (inCollection && onWishlist) const SizedBox(width: 6),
        if (onWishlist)
          Tooltip(
            message: 'On your wishlist',
            child: Icon(
              Icons.favorite,
              key: const Key('on-wishlist-icon'),
              size: 20,
              color: theme.colorScheme.tertiary,
              semanticLabel: 'On your wishlist',
            ),
          ),
      ],
    );
  }
}

class _CoverThumbnail extends StatelessWidget {
  const _CoverThumbnail({required this.theme, this.coverUrl});

  final ThemeData theme;
  final String? coverUrl;

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.album,
        size: 32,
        color: theme.colorScheme.outlineVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null) return _placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        coverUrl!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      ),
    );
  }
}

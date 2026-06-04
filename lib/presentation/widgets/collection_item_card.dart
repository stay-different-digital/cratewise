import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/collection_item.dart';
import '../../domain/repositories/thumbnail_repository.dart';

class CollectionItemCard extends StatelessWidget {
  const CollectionItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.thumbnailRepository,
  });

  final CollectionItem item;
  final VoidCallback? onTap;
  final ThumbnailRepository? thumbnailRepository;

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
              _LocalCoverThumbnail(
                theme: theme,
                releaseId: item.discogsReleaseId,
                repository: thumbnailRepository,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.artist,
                      style: theme.textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _MetaRow(item: item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (item.label != null) item.label!,
      if (item.year != null) '${item.year}',
      if (item.format != null) item.format!,
    ];

    final hasMetaParts = parts.isNotEmpty;
    final hasLocation = item.storageLocation != null;
    if (!hasMetaParts && !hasLocation) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasMetaParts)
          Text(
            parts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (hasLocation) ...[
          if (hasMetaParts) const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 12,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.storageLocation!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LocalCoverThumbnail extends StatefulWidget {
  const _LocalCoverThumbnail({
    required this.theme,
    required this.releaseId,
    this.repository,
  });

  final ThemeData theme;
  final int releaseId;
  final ThumbnailRepository? repository;

  @override
  State<_LocalCoverThumbnail> createState() => _LocalCoverThumbnailState();
}

class _LocalCoverThumbnailState extends State<_LocalCoverThumbnail> {
  late final Future<String?> _pathFuture;

  @override
  void initState() {
    super.initState();
    _pathFuture =
        widget.repository?.getLocalPath(widget.releaseId) ??
        Future<String?>.value();
  }

  Widget _placeholder() => Semantics(
    label: 'No cover image',
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.album,
        size: 32,
        color: widget.theme.colorScheme.outlineVariant,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _pathFuture,
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) return _placeholder();
        return ClipRRect(
          key: const Key('collection-cached-cover'),
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(path),
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        );
      },
    );
  }
}

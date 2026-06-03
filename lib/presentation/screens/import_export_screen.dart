import 'package:flutter/material.dart';

import '../../application/use_cases/build_collection_csv_export_preview_use_case.dart';
import '../../application/use_cases/build_collection_export_preview_use_case.dart';
import '../../application/use_cases/build_wishlist_csv_export_preview_use_case.dart';
import '../../application/use_cases/build_wishlist_export_preview_use_case.dart';
import '../../application/use_cases/fetch_collection_import_preview_use_case.dart';
import '../../application/use_cases/fetch_wishlist_import_preview_use_case.dart';
import 'collection_csv_export_preview_screen.dart';
import 'collection_csv_import_preview_screen.dart';
import 'collection_export_preview_screen.dart';
import 'collection_import_preview_screen.dart';
import 'wishlist_csv_export_preview_screen.dart';
import 'wishlist_csv_import_preview_screen.dart';
import 'wishlist_export_preview_screen.dart';
import 'wishlist_import_preview_screen.dart';

const _kWideBreakpoint = 700.0;
const _kCardExtent = 96.0;

class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({
    super.key,
    this.collectionImportUseCase,
    this.wishlistImportUseCase,
    this.collectionExportPreviewUseCase,
    this.wishlistExportPreviewUseCase,
    this.collectionCsvExportPreviewUseCase,
    this.wishlistCsvExportPreviewUseCase,
  });

  /// Injected only for testing. Production code passes null.
  final FetchCollectionImportPreviewUseCase? collectionImportUseCase;

  /// Injected only for testing. Production code passes null.
  final FetchWishlistImportPreviewUseCase? wishlistImportUseCase;

  /// Injected only for testing. Production code passes null.
  final BuildCollectionExportPreviewUseCase? collectionExportPreviewUseCase;

  /// Injected only for testing. Production code passes null.
  final BuildWishlistExportPreviewUseCase? wishlistExportPreviewUseCase;

  /// Injected only for testing. Production code passes null.
  final BuildCollectionCsvExportPreviewUseCase? collectionCsvExportPreviewUseCase;

  /// Injected only for testing. Production code passes null.
  final BuildWishlistCsvExportPreviewUseCase? wishlistCsvExportPreviewUseCase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import & Export')),
      body: LayoutBuilder(
        builder: (context, constraints) => _ActionBody(
          isWide: constraints.maxWidth >= _kWideBreakpoint,
          onImportCollection: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CollectionImportPreviewScreen(
                useCase: collectionImportUseCase,
              ),
            ),
          ),
          onImportWishlist: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WishlistImportPreviewScreen(
                useCase: wishlistImportUseCase,
              ),
            ),
          ),
          onExportCollection: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CollectionExportPreviewScreen(
                useCase: collectionExportPreviewUseCase,
              ),
            ),
          ),
          onExportWishlist: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WishlistExportPreviewScreen(
                useCase: wishlistExportPreviewUseCase,
              ),
            ),
          ),
          onExportCollectionCsv: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CollectionCsvExportPreviewScreen(
                previewUseCase: collectionCsvExportPreviewUseCase,
              ),
            ),
          ),
          onExportWishlistCsv: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WishlistCsvExportPreviewScreen(
                previewUseCase: wishlistCsvExportPreviewUseCase,
              ),
            ),
          ),
          onImportCollectionCsv: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CollectionCsvImportPreviewScreen(),
            ),
          ),
          onImportWishlistCsv: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const WishlistCsvImportPreviewScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action configs
// ---------------------------------------------------------------------------

class _ActionConfig {
  const _ActionConfig({
    required this.icon,
    required this.title,
    this.badge = 'Coming soon',
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? badge;
  final void Function(BuildContext)? onTap;
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _ActionBody extends StatelessWidget {
  const _ActionBody({
    required this.isWide,
    required this.onImportCollection,
    required this.onImportWishlist,
    required this.onExportCollection,
    required this.onExportWishlist,
    required this.onExportCollectionCsv,
    required this.onExportWishlistCsv,
    required this.onImportCollectionCsv,
    required this.onImportWishlistCsv,
  });

  final bool isWide;
  final VoidCallback onImportCollection;
  final VoidCallback onImportWishlist;
  final VoidCallback onExportCollection;
  final VoidCallback onExportWishlist;
  final VoidCallback onExportCollectionCsv;
  final VoidCallback onExportWishlistCsv;
  final VoidCallback onImportCollectionCsv;
  final VoidCallback onImportWishlistCsv;

  List<_ActionConfig> get _discogsActions => [
        _ActionConfig(
          icon: Icons.cloud_download_outlined,
          title: 'Import Collection from Discogs',
          badge: null,
          onTap: (ctx) => onImportCollection(),
        ),
        _ActionConfig(
          icon: Icons.cloud_download_outlined,
          title: 'Import Wishlist from Discogs',
          badge: null,
          onTap: (ctx) => onImportWishlist(),
        ),
        _ActionConfig(
          icon: Icons.cloud_upload_outlined,
          title: 'Export Collection to Discogs',
          badge: null,
          onTap: (ctx) => onExportCollection(),
        ),
        _ActionConfig(
          icon: Icons.cloud_upload_outlined,
          title: 'Export Wishlist to Discogs',
          badge: null,
          onTap: (ctx) => onExportWishlist(),
        ),
      ];

  List<_ActionConfig> get _csvActions => [
        _ActionConfig(
          icon: Icons.download_outlined,
          title: 'Export Collection to CSV',
          badge: null,
          onTap: (ctx) => onExportCollectionCsv(),
        ),
        _ActionConfig(
          icon: Icons.download_outlined,
          title: 'Export Wishlist to CSV',
          badge: null,
          onTap: (ctx) => onExportWishlistCsv(),
        ),
        _ActionConfig(
          icon: Icons.upload_file_outlined,
          title: 'Import Collection from CSV',
          badge: null,
          onTap: (ctx) => onImportCollectionCsv(),
        ),
        _ActionConfig(
          icon: Icons.upload_file_outlined,
          title: 'Import Wishlist from CSV',
          badge: null,
          onTap: (ctx) => onImportWishlistCsv(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: _SectionHeader(title: 'Discogs')),
        _buildSection(context, _discogsActions),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: _SectionHeader(title: 'CSV files')),
        _buildSection(context, _csvActions),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildSection(BuildContext context, List<_ActionConfig> actions) {
    if (isWide) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
            mainAxisExtent: _kCardExtent,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) =>
              _ActionCard(action: actions[index]),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList.separated(
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _ActionCard(action: actions[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action card
// ---------------------------------------------------------------------------

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _ActionConfig action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action.onTap != null
            ? () => action.onTap!(context)
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                action.icon,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                    ),
                    if (action.badge != null) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          action.badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

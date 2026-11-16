import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../application/use_cases/build_collection_csv_export_preview_use_case.dart';
import '../../application/use_cases/build_collection_export_preview_use_case.dart';
import '../../application/use_cases/build_wishlist_csv_export_preview_use_case.dart';
import '../../application/use_cases/build_wishlist_export_preview_use_case.dart';
import '../../application/use_cases/fetch_collection_import_preview_use_case.dart';
import '../../application/use_cases/fetch_wishlist_import_preview_use_case.dart';
import '../../domain/repositories/import_export_job_repository.dart';

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
    this.jobRepository,
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
  final BuildCollectionCsvExportPreviewUseCase?
  collectionCsvExportPreviewUseCase;

  /// Injected only for testing. Production code passes null.
  final BuildWishlistCsvExportPreviewUseCase? wishlistCsvExportPreviewUseCase;

  /// Injected only for testing. Production code passes null.
  final ImportExportJobRepository? jobRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import & Export')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => _ActionBody(
            isWide: constraints.maxWidth >= _kWideBreakpoint,
            onImportCollection: () => context.push(AppRoutes.importCollection),
            onImportWishlist: () => context.push(AppRoutes.importWishlist),
            onExportCollection: () => context.push(AppRoutes.exportCollection),
            onExportWishlist: () => context.push(AppRoutes.exportWishlist),
            onExportCollectionCsv: () =>
                context.push(AppRoutes.exportCollectionCsv),
            onExportWishlistCsv: () =>
                context.push(AppRoutes.exportWishlistCsv),
            onImportCollectionCsv: () =>
                context.push(AppRoutes.importCollectionCsv),
            onImportWishlistCsv: () =>
                context.push(AppRoutes.importWishlistCsv),
            onViewHistory: () => context.push(AppRoutes.importExportHistory),
            onViewPendingDeletions: () =>
                context.push(AppRoutes.pendingDeletions),
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
    required this.onViewHistory,
    required this.onViewPendingDeletions,
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
  final VoidCallback onViewHistory;
  final VoidCallback onViewPendingDeletions;

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
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: _SectionHeader(title: 'History')),
        _buildSection(context, [
          _ActionConfig(
            icon: Icons.history_outlined,
            title: 'View import & export history',
            badge: null,
            onTap: (_) => onViewHistory(),
          ),
          _ActionConfig(
            icon: Icons.cloud_off_outlined,
            title: 'Removals to sync to Discogs',
            badge: null,
            onTap: (_) => onViewPendingDeletions(),
          ),
        ]),
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
          itemBuilder: (context, index) => _ActionCard(action: actions[index]),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList.separated(
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _ActionCard(action: actions[index]),
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
              Icon(action.icon, color: theme.colorScheme.onSurfaceVariant),
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

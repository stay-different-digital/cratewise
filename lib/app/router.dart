import 'package:go_router/go_router.dart';

import '../application/services/thumbnail_eviction_service.dart';
import '../infrastructure/local_database/local_thumbnail_repository.dart';
import '../presentation/screens/barcode_scan_screen.dart';
import '../presentation/screens/collection_csv_export_preview_screen.dart';
import '../presentation/screens/collection_csv_import_preview_screen.dart';
import '../presentation/screens/collection_detail_screen.dart';
import '../presentation/screens/collection_export_preview_screen.dart';
import '../presentation/screens/collection_import_preview_screen.dart';
import '../presentation/screens/collection_screen.dart';
import '../presentation/screens/failed_actions_screen.dart';
import '../presentation/screens/home_shell_screen.dart';
import '../presentation/screens/import_export_history_screen.dart';
import '../presentation/screens/import_export_screen.dart';
import '../presentation/screens/release_detail_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/wishlist_csv_export_preview_screen.dart';
import '../presentation/screens/wishlist_csv_import_preview_screen.dart';
import '../presentation/screens/wishlist_detail_screen.dart';
import '../presentation/screens/wishlist_export_preview_screen.dart';
import '../presentation/screens/wishlist_import_preview_screen.dart';
import '../presentation/screens/wishlist_screen.dart';
import '../shared/route_observer.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

abstract final class AppRoutes {
  static const search = '/search';
  static const collection = '/collection';
  static const wishlist = '/wishlist';
  static const barcode = '/barcode';
  static const settings = '/settings';
  static const importExport = '/settings/import-export';
  static const importExportHistory = '/settings/import-export/history';
  static const importCollection = '/settings/import-export/collection-import';
  static const importWishlist = '/settings/import-export/wishlist-import';
  static const exportCollection = '/settings/import-export/collection-export';
  static const exportWishlist = '/settings/import-export/wishlist-export';
  static const exportCollectionCsv =
      '/settings/import-export/collection-csv-export';
  static const exportWishlistCsv =
      '/settings/import-export/wishlist-csv-export';
  static const importCollectionCsv =
      '/settings/import-export/collection-csv-import';
  static const importWishlistCsv =
      '/settings/import-export/wishlist-csv-import';
  static const failedActions = '/settings/failed-actions';

  // Build typed paths for parameterised routes.
  static String searchRelease(int releaseId, {String? artist, String? title}) {
    final params = <String, String>{
      if (artist != null && artist.isNotEmpty) 'artist': artist,
      if (title != null && title.isNotEmpty) 'title': title,
    };
    return Uri(
      path: '/search/release/$releaseId',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  static String collectionDetail(String itemId) => '/collection/$itemId';
  static String wishlistDetail(String itemId) => '/wishlist/$itemId';
}

// ---------------------------------------------------------------------------
// Router instance
// ---------------------------------------------------------------------------

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.search,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          HomeShellScreen(navigationShell: navigationShell),
      branches: [
        // ── Tab 0: Search ────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              builder: (_, _) => const SearchScreen(),
              routes: [
                GoRoute(
                  path: 'release/:releaseId',
                  builder: (_, state) => ReleaseDetailScreen(
                    releaseId: int.parse(state.pathParameters['releaseId']!),
                    initialArtist: state.uri.queryParameters['artist'],
                    initialTitle: state.uri.queryParameters['title'],
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Tab 1: Collection ────────────────────────────────────────────
        StatefulShellBranch(
          observers: [appRouteObserver],
          routes: [
            GoRoute(
              path: AppRoutes.collection,
              builder: (_, _) => const CollectionScreen(),
              routes: [
                GoRoute(
                  path: ':itemId',
                  builder: (_, state) => CollectionDetailScreen(
                    itemId: state.pathParameters['itemId']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Tab 2: Wishlist ──────────────────────────────────────────────
        StatefulShellBranch(
          observers: [wishlistRouteObserver],
          routes: [
            GoRoute(
              path: AppRoutes.wishlist,
              builder: (_, _) => const WishlistScreen(),
              routes: [
                GoRoute(
                  path: ':itemId',
                  builder: (_, state) => WishlistDetailScreen(
                    itemId: state.pathParameters['itemId']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Tab 3: Barcode ───────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.barcode,
              builder: (_, _) => const BarcodeScanScreen(),
            ),
          ],
        ),

        // ── Tab 4: Settings ──────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, _) => SettingsScreen(
                evictionService: ThumbnailEvictionService(
                  repository: LocalThumbnailRepository(),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'import-export',
                  builder: (_, _) => const ImportExportScreen(),
                  routes: [
                    GoRoute(
                      path: 'history',
                      builder: (_, _) => const ImportExportHistoryScreen(),
                    ),
                    GoRoute(
                      path: 'collection-import',
                      builder: (_, _) => const CollectionImportPreviewScreen(),
                    ),
                    GoRoute(
                      path: 'wishlist-import',
                      builder: (_, _) => const WishlistImportPreviewScreen(),
                    ),
                    GoRoute(
                      path: 'collection-export',
                      builder: (_, _) => const CollectionExportPreviewScreen(),
                    ),
                    GoRoute(
                      path: 'wishlist-export',
                      builder: (_, _) => const WishlistExportPreviewScreen(),
                    ),
                    GoRoute(
                      path: 'collection-csv-export',
                      builder: (_, _) =>
                          const CollectionCsvExportPreviewScreen(),
                    ),
                    GoRoute(
                      path: 'wishlist-csv-export',
                      builder: (_, _) => const WishlistCsvExportPreviewScreen(),
                    ),
                    GoRoute(
                      path: 'collection-csv-import',
                      builder: (_, _) =>
                          const CollectionCsvImportPreviewScreen(),
                    ),
                    GoRoute(
                      path: 'wishlist-csv-import',
                      builder: (_, _) => const WishlistCsvImportPreviewScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'failed-actions',
                  builder: (_, _) => const FailedActionsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

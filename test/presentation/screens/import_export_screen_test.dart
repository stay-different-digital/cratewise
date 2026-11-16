import 'package:cratewise/application/use_cases/build_collection_csv_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/build_collection_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/build_collection_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/build_wishlist_csv_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/build_wishlist_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/build_wishlist_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/check_collection_export_capability_use_case.dart';
import 'package:cratewise/application/use_cases/check_wishlist_export_capability_use_case.dart';
import 'package:cratewise/application/use_cases/fetch_collection_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/fetch_wishlist_import_preview_use_case.dart';
import 'package:cratewise/domain/models/collection_import_preview.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/wishlist_import_preview.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/csv_export_preview_screen.dart';
import 'package:cratewise/presentation/screens/csv_import_preview_screen.dart';
import 'package:cratewise/presentation/screens/export_preview_screen.dart';
import 'package:cratewise/presentation/screens/import_preview_screen.dart';
import 'package:cratewise/presentation/screens/import_export_history_screen.dart';
import 'package:cratewise/presentation/screens/import_export_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Fake use cases for navigation tests
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<List<WishlistItem>> getAll() async => [];
  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakeCollectionImportUseCase extends FetchCollectionImportPreviewUseCase {
  _FakeCollectionImportUseCase()
    : super(
        previewBuilder: BuildCollectionImportPreviewUseCase(
          _FakeCollectionRepository(),
        ),
      );

  @override
  Future<FetchCollectionImportPreviewResult> execute() async =>
      FetchPreviewReady(const CollectionImportPreview(rows: []));
}

class _FakeWishlistImportUseCase extends FetchWishlistImportPreviewUseCase {
  _FakeWishlistImportUseCase()
    : super(
        previewBuilder: BuildWishlistImportPreviewUseCase(
          _FakeWishlistRepository(),
        ),
      );

  @override
  Future<FetchWishlistImportPreviewResult> execute() async =>
      FetchWishlistPreviewReady(const WishlistImportPreview(rows: []));
}

class _FakeCollectionExportUseCase extends BuildCollectionExportPreviewUseCase {
  _FakeCollectionExportUseCase()
    : super(
        repository: _FakeCollectionRepository(),
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
      );

  @override
  Future<BuildCollectionExportPreviewResult> execute() async =>
      const CollectionExportPreviewNotSupported('Not available yet.');
}

class _FakeWishlistExportUseCase extends BuildWishlistExportPreviewUseCase {
  _FakeWishlistExportUseCase()
    : super(
        repository: _FakeWishlistRepository(),
        capabilityUseCase: const CheckWishlistExportCapabilityUseCase(),
      );

  @override
  Future<BuildWishlistExportPreviewResult> execute() async =>
      const WishlistExportPreviewNotSupported('Not available yet.');
}

class _FakeCollectionCsvExportUseCase
    extends BuildCollectionCsvExportPreviewUseCase {
  _FakeCollectionCsvExportUseCase()
    : super(repository: _FakeCollectionRepository());

  @override
  Future<BuildCollectionCsvExportPreviewResult> execute() async =>
      const CollectionCsvExportPreviewError();
}

class _FakeWishlistCsvExportUseCase
    extends BuildWishlistCsvExportPreviewUseCase {
  _FakeWishlistCsvExportUseCase()
    : super(repository: _FakeWishlistRepository());

  @override
  Future<BuildWishlistCsvExportPreviewResult> execute() async =>
      const WishlistCsvExportPreviewError();
}

class _FakeJobRepository implements ImportExportJobRepository {
  @override
  Future<List<ImportExportJob>> getRecent({
    int limit = 20,
    int offset = 0,
  }) async => [];
  @override
  Future<int> count() async => 0;

  @override
  Future<ImportExportJob?> getById(String id) async => null;

  @override
  Future<void> add(ImportExportJob job) async {}

  @override
  Future<void> update(ImportExportJob job) async {}

  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Router-backed wrapper for tests that navigate to sub-screens.
/// Fake use cases are injected directly into the sub-screen route builders so
/// that [pumpAndSettle] can settle without opening a real database.
Widget _buildSubjectWithRouter({
  FetchCollectionImportPreviewUseCase? importUseCase,
  FetchWishlistImportPreviewUseCase? wishlistImportUseCase,
  BuildCollectionExportPreviewUseCase? collectionExportPreviewUseCase,
  BuildWishlistExportPreviewUseCase? wishlistExportPreviewUseCase,
  BuildCollectionCsvExportPreviewUseCase? collectionCsvExportPreviewUseCase,
  BuildWishlistCsvExportPreviewUseCase? wishlistCsvExportPreviewUseCase,
  ImportExportJobRepository? jobRepository,
}) {
  final router = GoRouter(
    initialLocation: '/settings/import-export',
    routes: [
      GoRoute(
        path: '/settings/import-export',
        builder: (_, _) => ImportExportScreen(
          collectionImportUseCase: importUseCase,
          wishlistImportUseCase: wishlistImportUseCase,
          collectionExportPreviewUseCase: collectionExportPreviewUseCase,
          wishlistExportPreviewUseCase: wishlistExportPreviewUseCase,
          collectionCsvExportPreviewUseCase: collectionCsvExportPreviewUseCase,
          wishlistCsvExportPreviewUseCase: wishlistCsvExportPreviewUseCase,
          jobRepository: jobRepository,
        ),
        routes: [
          GoRoute(
            path: 'collection-import',
            builder: (_, _) =>
                CollectionImportPreviewScreen(useCase: importUseCase),
          ),
          GoRoute(
            path: 'wishlist-import',
            builder: (_, _) =>
                WishlistImportPreviewScreen(useCase: wishlistImportUseCase),
          ),
          GoRoute(
            path: 'collection-export',
            builder: (_, _) => CollectionExportPreviewScreen(
              useCase: collectionExportPreviewUseCase,
            ),
          ),
          GoRoute(
            path: 'wishlist-export',
            builder: (_, _) => WishlistExportPreviewScreen(
              useCase: wishlistExportPreviewUseCase,
            ),
          ),
          GoRoute(
            path: 'collection-csv-export',
            builder: (_, _) => CollectionCsvExportPreviewScreen(
              previewUseCase: collectionCsvExportPreviewUseCase,
            ),
          ),
          GoRoute(
            path: 'wishlist-csv-export',
            builder: (_, _) => WishlistCsvExportPreviewScreen(
              previewUseCase: wishlistCsvExportPreviewUseCase,
            ),
          ),
          GoRoute(
            path: 'collection-csv-import',
            builder: (_, _) => const CollectionCsvImportPreviewScreen(),
          ),
          GoRoute(
            path: 'wishlist-csv-import',
            builder: (_, _) => const WishlistCsvImportPreviewScreen(),
          ),
          GoRoute(
            path: 'history',
            builder: (_, _) =>
                ImportExportHistoryScreen(repository: jobRepository),
          ),
        ],
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void _setNarrowTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 2.0;
}

void _setWideTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(2800, 2000);
  tester.view.devicePixelRatio = 2.0;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ImportExportScreen', () {
    group('structure', () {
      testWidgets('shows Import & Export in AppBar', (tester) async {
        await tester.pumpWidget(_buildSubjectWithRouter());
        expect(find.text('Import & Export'), findsOneWidget);
      });

      testWidgets('shows Discogs section header', (tester) async {
        await tester.pumpWidget(_buildSubjectWithRouter());
        expect(find.text('Discogs'), findsOneWidget);
      });

      testWidgets('shows CSV files section header', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubjectWithRouter());
        expect(find.text('CSV files'), findsOneWidget);
      });

      testWidgets('shows all 8 action card titles', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubjectWithRouter());

        expect(find.text('Import Collection from Discogs'), findsOneWidget);
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
        expect(find.text('Export Wishlist to Discogs'), findsOneWidget);
        expect(find.text('Export Collection to CSV'), findsOneWidget);
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
        expect(find.text('Import Collection from CSV'), findsOneWidget);
        expect(find.text('Import Wishlist from CSV'), findsOneWidget);
      });

      testWidgets('no cards show a Coming soon badge', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubjectWithRouter());

        expect(find.text('Coming soon'), findsNothing);
      });
    });

    group('action card interactions', () {
      testWidgets(
        'tapping Import Wishlist from Discogs does not show snackbar',
        (tester) async {
          final wishlistUseCase = _FakeWishlistImportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(wishlistImportUseCase: wishlistUseCase),
          );
          await tester.tap(find.text('Import Wishlist from Discogs'));
          await tester.pump();
          expect(find.byType(SnackBar), findsNothing);
        },
      );

      testWidgets('tapping Export Wishlist to Discogs does not show snackbar', (
        tester,
      ) async {
        final wishlistExportUseCase = _FakeWishlistExportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(
            wishlistExportPreviewUseCase: wishlistExportUseCase,
          ),
        );
        await tester.tap(find.text('Export Wishlist to Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets(
        'tapping Import Collection from CSV navigates to preview screen',
        (tester) async {
          _setNarrowTallScreen(tester);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(_buildSubjectWithRouter());
          await tester.tap(find.text('Import Collection from CSV'));
          await tester.pumpAndSettle();
          expect(find.byType(CollectionCsvImportPreviewScreen), findsOneWidget);
        },
      );

      testWidgets(
        'tapping Import Wishlist from CSV navigates to preview screen',
        (tester) async {
          _setNarrowTallScreen(tester);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(_buildSubjectWithRouter());
          await tester.tap(find.text('Import Wishlist from CSV'));
          await tester.pumpAndSettle();
          expect(find.byType(WishlistCsvImportPreviewScreen), findsOneWidget);
        },
      );
    });

    group('Import Collection from Discogs navigation', () {
      testWidgets(
        'tapping Import Collection from Discogs navigates to preview screen',
        (tester) async {
          final importUseCase = _FakeCollectionImportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(importUseCase: importUseCase),
          );
          await tester.tap(find.text('Import Collection from Discogs'));
          await tester.pumpAndSettle();
          expect(find.byType(CollectionImportPreviewScreen), findsOneWidget);
        },
      );

      testWidgets('preview screen shows Import from Discogs AppBar title', (
        tester,
      ) async {
        final importUseCase = _FakeCollectionImportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(importUseCase: importUseCase),
        );
        await tester.tap(find.text('Import Collection from Discogs'));
        await tester.pumpAndSettle();
        expect(find.text('Import from Discogs'), findsOneWidget);
      });

      testWidgets(
        'tapping Import Collection does not show Coming soon snackbar',
        (tester) async {
          final importUseCase = _FakeCollectionImportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(importUseCase: importUseCase),
          );
          await tester.tap(find.text('Import Collection from Discogs'));
          await tester.pump();
          expect(find.byType(SnackBar), findsNothing);
        },
      );
    });

    group('Import Wishlist from Discogs navigation', () {
      testWidgets(
        'tapping Import Wishlist from Discogs navigates to preview screen',
        (tester) async {
          final wishlistUseCase = _FakeWishlistImportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(wishlistImportUseCase: wishlistUseCase),
          );
          await tester.tap(find.text('Import Wishlist from Discogs'));
          await tester.pumpAndSettle();
          expect(find.byType(WishlistImportPreviewScreen), findsOneWidget);
        },
      );

      testWidgets('wishlist preview screen shows correct AppBar title', (
        tester,
      ) async {
        final wishlistUseCase = _FakeWishlistImportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(wishlistImportUseCase: wishlistUseCase),
        );
        await tester.tap(find.text('Import Wishlist from Discogs'));
        await tester.pumpAndSettle();
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
      });

      testWidgets(
        'tapping Import Wishlist does not show Coming soon snackbar',
        (tester) async {
          final wishlistUseCase = _FakeWishlistImportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(wishlistImportUseCase: wishlistUseCase),
          );
          await tester.tap(find.text('Import Wishlist from Discogs'));
          await tester.pump();
          expect(find.byType(SnackBar), findsNothing);
        },
      );
    });

    group('Export Collection to Discogs navigation', () {
      testWidgets(
        'tapping Export Collection to Discogs navigates to export preview screen',
        (tester) async {
          final exportUseCase = _FakeCollectionExportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(
              collectionExportPreviewUseCase: exportUseCase,
            ),
          );
          await tester.tap(find.text('Export Collection to Discogs'));
          await tester.pumpAndSettle();
          expect(find.byType(CollectionExportPreviewScreen), findsOneWidget);
        },
      );

      testWidgets('export preview screen shows correct AppBar title', (
        tester,
      ) async {
        final exportUseCase = _FakeCollectionExportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(
            collectionExportPreviewUseCase: exportUseCase,
          ),
        );
        await tester.tap(find.text('Export Collection to Discogs'));
        await tester.pumpAndSettle();
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
      });

      testWidgets(
        'tapping Export Collection to Discogs does not show Coming soon snackbar',
        (tester) async {
          final exportUseCase = _FakeCollectionExportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(
              collectionExportPreviewUseCase: exportUseCase,
            ),
          );
          await tester.tap(find.text('Export Collection to Discogs'));
          await tester.pump();
          expect(find.byType(SnackBar), findsNothing);
        },
      );
    });

    group('Export Wishlist to Discogs navigation', () {
      testWidgets(
        'tapping Export Wishlist to Discogs navigates to export preview screen',
        (tester) async {
          final wishlistExportUseCase = _FakeWishlistExportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(
              wishlistExportPreviewUseCase: wishlistExportUseCase,
            ),
          );
          await tester.tap(find.text('Export Wishlist to Discogs'));
          await tester.pumpAndSettle();
          expect(find.byType(WishlistExportPreviewScreen), findsOneWidget);
        },
      );

      testWidgets('wishlist export preview screen shows correct AppBar title', (
        tester,
      ) async {
        final wishlistExportUseCase = _FakeWishlistExportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(
            wishlistExportPreviewUseCase: wishlistExportUseCase,
          ),
        );
        await tester.tap(find.text('Export Wishlist to Discogs'));
        await tester.pumpAndSettle();
        expect(find.text('Export Wishlist to Discogs'), findsOneWidget);
      });

      testWidgets(
        'tapping Export Wishlist to Discogs does not show Coming soon snackbar',
        (tester) async {
          final wishlistExportUseCase = _FakeWishlistExportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(
              wishlistExportPreviewUseCase: wishlistExportUseCase,
            ),
          );
          await tester.tap(find.text('Export Wishlist to Discogs'));
          await tester.pump();
          expect(find.byType(SnackBar), findsNothing);
        },
      );
    });

    group('Export Collection to CSV navigation', () {
      testWidgets(
        'tapping Export Collection to CSV navigates to CSV export preview screen',
        (tester) async {
          _setNarrowTallScreen(tester);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final csvUseCase = _FakeCollectionCsvExportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(
              collectionCsvExportPreviewUseCase: csvUseCase,
            ),
          );
          await tester.tap(find.text('Export Collection to CSV'));
          await tester.pumpAndSettle();
          expect(find.byType(CollectionCsvExportPreviewScreen), findsOneWidget);
        },
      );

      testWidgets('CSV collection export screen shows correct AppBar title', (
        tester,
      ) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final csvUseCase = _FakeCollectionCsvExportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(
            collectionCsvExportPreviewUseCase: csvUseCase,
          ),
        );
        await tester.tap(find.text('Export Collection to CSV'));
        await tester.pumpAndSettle();
        expect(find.text('Export Collection to CSV'), findsOneWidget);
      });

      testWidgets('tapping Export Collection to CSV does not show snackbar', (
        tester,
      ) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final csvUseCase = _FakeCollectionCsvExportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(
            collectionCsvExportPreviewUseCase: csvUseCase,
          ),
        );
        await tester.tap(find.text('Export Collection to CSV'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });
    });

    group('Export Wishlist to CSV navigation', () {
      testWidgets(
        'tapping Export Wishlist to CSV navigates to CSV export preview screen',
        (tester) async {
          _setNarrowTallScreen(tester);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final csvUseCase = _FakeWishlistCsvExportUseCase();
          await tester.pumpWidget(
            _buildSubjectWithRouter(
              wishlistCsvExportPreviewUseCase: csvUseCase,
            ),
          );
          await tester.tap(find.text('Export Wishlist to CSV'));
          await tester.pumpAndSettle();
          expect(find.byType(WishlistCsvExportPreviewScreen), findsOneWidget);
        },
      );

      testWidgets('CSV wishlist export screen shows correct AppBar title', (
        tester,
      ) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final csvUseCase = _FakeWishlistCsvExportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(wishlistCsvExportPreviewUseCase: csvUseCase),
        );
        await tester.tap(find.text('Export Wishlist to CSV'));
        await tester.pumpAndSettle();
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
      });

      testWidgets('tapping Export Wishlist to CSV does not show snackbar', (
        tester,
      ) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final csvUseCase = _FakeWishlistCsvExportUseCase();
        await tester.pumpWidget(
          _buildSubjectWithRouter(wishlistCsvExportPreviewUseCase: csvUseCase),
        );
        await tester.tap(find.text('Export Wishlist to CSV'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });
    });

    group('wide layout', () {
      testWidgets('renders without error on wide screen', (tester) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubjectWithRouter());

        expect(find.text('Import & Export'), findsOneWidget);
        expect(find.text('Discogs'), findsOneWidget);
        expect(find.text('CSV files'), findsOneWidget);
      });

      testWidgets('shows all 8 action cards on wide tall screen', (
        tester,
      ) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubjectWithRouter());

        expect(find.text('Import Collection from Discogs'), findsOneWidget);
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
        expect(find.text('Export Wishlist to Discogs'), findsOneWidget);
        expect(find.text('Export Collection to CSV'), findsOneWidget);
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
        expect(find.text('Import Collection from CSV'), findsOneWidget);
        expect(find.text('Import Wishlist from CSV'), findsOneWidget);
      });

      testWidgets(
        'tapping Import Collection from CSV on wide screen navigates',
        (tester) async {
          _setWideTallScreen(tester);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(_buildSubjectWithRouter());
          await tester.tap(find.text('Import Collection from CSV'));
          await tester.pumpAndSettle();
          expect(find.byType(CollectionCsvImportPreviewScreen), findsOneWidget);
        },
      );

      testWidgets('no cards show Coming soon badge on wide screen', (
        tester,
      ) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubjectWithRouter());
        expect(find.text('Coming soon'), findsNothing);
      });
    });

    group('History navigation', () {
      testWidgets('shows History section header', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubjectWithRouter());
        expect(find.text('History'), findsOneWidget);
      });

      testWidgets('shows View import & export history card', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubjectWithRouter());
        expect(find.text('View import & export history'), findsOneWidget);
      });

      testWidgets(
        'tapping history card navigates to ImportExportHistoryScreen',
        (tester) async {
          _setNarrowTallScreen(tester);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final jobRepo = _FakeJobRepository();
          await tester.pumpWidget(
            _buildSubjectWithRouter(jobRepository: jobRepo),
          );
          await tester.tap(find.text('View import & export history'));
          await tester.pumpAndSettle();
          expect(find.byType(ImportExportHistoryScreen), findsOneWidget);
        },
      );

      testWidgets('history screen shows Import & Export History AppBar title', (
        tester,
      ) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final jobRepo = _FakeJobRepository();
        await tester.pumpWidget(
          _buildSubjectWithRouter(jobRepository: jobRepo),
        );
        await tester.tap(find.text('View import & export history'));
        await tester.pumpAndSettle();
        expect(find.text('Import & Export History'), findsOneWidget);
      });
    });
  });

  group('ImportExportScreen — safe area', () {
    testWidgets('body has SafeArea with top: false', (tester) async {
      await tester.pumpWidget(_buildSubjectWithRouter());
      await tester.pump();
      final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
      expect(safeAreas.any((sa) => !sa.top), isTrue);
    });
  });
}

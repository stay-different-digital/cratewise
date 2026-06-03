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
import 'package:cratewise/domain/models/wishlist_import_preview.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/collection_csv_export_preview_screen.dart';
import 'package:cratewise/presentation/screens/collection_export_preview_screen.dart';
import 'package:cratewise/presentation/screens/collection_import_preview_screen.dart';
import 'package:cratewise/presentation/screens/import_export_screen.dart';
import 'package:cratewise/presentation/screens/wishlist_csv_export_preview_screen.dart';
import 'package:cratewise/presentation/screens/wishlist_export_preview_screen.dart';
import 'package:cratewise/presentation/screens/wishlist_import_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake use cases for navigation tests
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildSubject({
  FetchCollectionImportPreviewUseCase? importUseCase,
  FetchWishlistImportPreviewUseCase? wishlistImportUseCase,
  BuildCollectionExportPreviewUseCase? collectionExportPreviewUseCase,
  BuildWishlistExportPreviewUseCase? wishlistExportPreviewUseCase,
  BuildCollectionCsvExportPreviewUseCase? collectionCsvExportPreviewUseCase,
  BuildWishlistCsvExportPreviewUseCase? wishlistCsvExportPreviewUseCase,
}) =>
    MaterialApp(
      home: ImportExportScreen(
        collectionImportUseCase: importUseCase,
        wishlistImportUseCase: wishlistImportUseCase,
        collectionExportPreviewUseCase: collectionExportPreviewUseCase,
        wishlistExportPreviewUseCase: wishlistExportPreviewUseCase,
        collectionCsvExportPreviewUseCase: collectionCsvExportPreviewUseCase,
        wishlistCsvExportPreviewUseCase: wishlistCsvExportPreviewUseCase,
      ),
    );

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
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Import & Export'), findsOneWidget);
      });

      testWidgets('shows Discogs section header', (tester) async {
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Discogs'), findsOneWidget);
      });

      testWidgets('shows CSV files section header', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        expect(find.text('CSV files'), findsOneWidget);
      });

      testWidgets('shows all 8 action card titles', (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());

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
          '2 cards show a Coming soon badge (CSV import cards are still coming soon)',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());

        expect(find.text('Coming soon'), findsNWidgets(2));
      });

    });

    group('action card interactions', () {
      testWidgets('tapping Import Wishlist from Discogs does not show snackbar',
          (tester) async {
        final wishlistUseCase = _FakeWishlistImportUseCase();
        await tester.pumpWidget(
            _buildSubject(wishlistImportUseCase: wishlistUseCase));
        await tester.tap(find.text('Import Wishlist from Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('tapping Export Wishlist to Discogs does not show snackbar',
          (tester) async {
        final wishlistExportUseCase = _FakeWishlistExportUseCase();
        await tester.pumpWidget(
            _buildSubject(wishlistExportPreviewUseCase: wishlistExportUseCase));
        await tester.tap(find.text('Export Wishlist to Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('tapping Import Collection from CSV shows Coming soon snackbar',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Import Collection from CSV'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('tapping Import Wishlist from CSV shows snackbar',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Import Wishlist from CSV'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('tapping a Coming soon card does not navigate',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Import Collection from CSV'));
        await tester.pump();
        // Still on the import/export screen
        expect(find.text('Import & Export'), findsOneWidget);
      });
    });

    group('Import Collection from Discogs navigation', () {
      testWidgets('tapping Import Collection from Discogs navigates to preview screen',
          (tester) async {
        final importUseCase = _FakeCollectionImportUseCase();
        await tester.pumpWidget(_buildSubject(importUseCase: importUseCase));
        await tester.tap(find.text('Import Collection from Discogs'));
        await tester.pumpAndSettle();
        expect(find.byType(CollectionImportPreviewScreen), findsOneWidget);
      });

      testWidgets('preview screen shows Import from Discogs AppBar title',
          (tester) async {
        final importUseCase = _FakeCollectionImportUseCase();
        await tester.pumpWidget(_buildSubject(importUseCase: importUseCase));
        await tester.tap(find.text('Import Collection from Discogs'));
        await tester.pumpAndSettle();
        expect(find.text('Import from Discogs'), findsOneWidget);
      });

      testWidgets('tapping Import Collection does not show Coming soon snackbar',
          (tester) async {
        final importUseCase = _FakeCollectionImportUseCase();
        await tester.pumpWidget(_buildSubject(importUseCase: importUseCase));
        await tester.tap(find.text('Import Collection from Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });
    });

    group('Import Wishlist from Discogs navigation', () {
      testWidgets(
          'tapping Import Wishlist from Discogs navigates to preview screen',
          (tester) async {
        final wishlistUseCase = _FakeWishlistImportUseCase();
        await tester.pumpWidget(
            _buildSubject(wishlistImportUseCase: wishlistUseCase));
        await tester.tap(find.text('Import Wishlist from Discogs'));
        await tester.pumpAndSettle();
        expect(find.byType(WishlistImportPreviewScreen), findsOneWidget);
      });

      testWidgets('wishlist preview screen shows correct AppBar title',
          (tester) async {
        final wishlistUseCase = _FakeWishlistImportUseCase();
        await tester.pumpWidget(
            _buildSubject(wishlistImportUseCase: wishlistUseCase));
        await tester.tap(find.text('Import Wishlist from Discogs'));
        await tester.pumpAndSettle();
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
      });

      testWidgets('tapping Import Wishlist does not show Coming soon snackbar',
          (tester) async {
        final wishlistUseCase = _FakeWishlistImportUseCase();
        await tester.pumpWidget(
            _buildSubject(wishlistImportUseCase: wishlistUseCase));
        await tester.tap(find.text('Import Wishlist from Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });
    });

    group('Export Collection to Discogs navigation', () {
      testWidgets(
          'tapping Export Collection to Discogs navigates to export preview screen',
          (tester) async {
        final exportUseCase = _FakeCollectionExportUseCase();
        await tester.pumpWidget(
            _buildSubject(collectionExportPreviewUseCase: exportUseCase));
        await tester.tap(find.text('Export Collection to Discogs'));
        await tester.pumpAndSettle();
        expect(find.byType(CollectionExportPreviewScreen), findsOneWidget);
      });

      testWidgets('export preview screen shows correct AppBar title',
          (tester) async {
        final exportUseCase = _FakeCollectionExportUseCase();
        await tester.pumpWidget(
            _buildSubject(collectionExportPreviewUseCase: exportUseCase));
        await tester.tap(find.text('Export Collection to Discogs'));
        await tester.pumpAndSettle();
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
      });

      testWidgets(
          'tapping Export Collection to Discogs does not show Coming soon snackbar',
          (tester) async {
        final exportUseCase = _FakeCollectionExportUseCase();
        await tester.pumpWidget(
            _buildSubject(collectionExportPreviewUseCase: exportUseCase));
        await tester.tap(find.text('Export Collection to Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });
    });

    group('Export Wishlist to Discogs navigation', () {
      testWidgets(
          'tapping Export Wishlist to Discogs navigates to export preview screen',
          (tester) async {
        final wishlistExportUseCase = _FakeWishlistExportUseCase();
        await tester.pumpWidget(
            _buildSubject(wishlistExportPreviewUseCase: wishlistExportUseCase));
        await tester.tap(find.text('Export Wishlist to Discogs'));
        await tester.pumpAndSettle();
        expect(find.byType(WishlistExportPreviewScreen), findsOneWidget);
      });

      testWidgets('wishlist export preview screen shows correct AppBar title',
          (tester) async {
        final wishlistExportUseCase = _FakeWishlistExportUseCase();
        await tester.pumpWidget(
            _buildSubject(wishlistExportPreviewUseCase: wishlistExportUseCase));
        await tester.tap(find.text('Export Wishlist to Discogs'));
        await tester.pumpAndSettle();
        expect(find.text('Export Wishlist to Discogs'), findsOneWidget);
      });

      testWidgets(
          'tapping Export Wishlist to Discogs does not show Coming soon snackbar',
          (tester) async {
        final wishlistExportUseCase = _FakeWishlistExportUseCase();
        await tester.pumpWidget(
            _buildSubject(wishlistExportPreviewUseCase: wishlistExportUseCase));
        await tester.tap(find.text('Export Wishlist to Discogs'));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      });
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
          _buildSubject(collectionCsvExportPreviewUseCase: csvUseCase),
        );
        await tester.tap(find.text('Export Collection to CSV'));
        await tester.pumpAndSettle();
        expect(find.byType(CollectionCsvExportPreviewScreen), findsOneWidget);
      });

      testWidgets(
          'CSV collection export screen shows correct AppBar title',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final csvUseCase = _FakeCollectionCsvExportUseCase();
        await tester.pumpWidget(
          _buildSubject(collectionCsvExportPreviewUseCase: csvUseCase),
        );
        await tester.tap(find.text('Export Collection to CSV'));
        await tester.pumpAndSettle();
        expect(find.text('Export Collection to CSV'), findsOneWidget);
      });

      testWidgets('tapping Export Collection to CSV does not show snackbar',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final csvUseCase = _FakeCollectionCsvExportUseCase();
        await tester.pumpWidget(
          _buildSubject(collectionCsvExportPreviewUseCase: csvUseCase),
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
          _buildSubject(wishlistCsvExportPreviewUseCase: csvUseCase),
        );
        await tester.tap(find.text('Export Wishlist to CSV'));
        await tester.pumpAndSettle();
        expect(find.byType(WishlistCsvExportPreviewScreen), findsOneWidget);
      });

      testWidgets('CSV wishlist export screen shows correct AppBar title',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final csvUseCase = _FakeWishlistCsvExportUseCase();
        await tester.pumpWidget(
          _buildSubject(wishlistCsvExportPreviewUseCase: csvUseCase),
        );
        await tester.tap(find.text('Export Wishlist to CSV'));
        await tester.pumpAndSettle();
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
      });

      testWidgets('tapping Export Wishlist to CSV does not show snackbar',
          (tester) async {
        _setNarrowTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final csvUseCase = _FakeWishlistCsvExportUseCase();
        await tester.pumpWidget(
          _buildSubject(wishlistCsvExportPreviewUseCase: csvUseCase),
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

        await tester.pumpWidget(_buildSubject());

        expect(find.text('Import & Export'), findsOneWidget);
        expect(find.text('Discogs'), findsOneWidget);
        expect(find.text('CSV files'), findsOneWidget);
      });

      testWidgets('shows all 8 action cards on wide tall screen', (tester) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());

        expect(find.text('Import Collection from Discogs'), findsOneWidget);
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
        expect(find.text('Export Wishlist to Discogs'), findsOneWidget);
        expect(find.text('Export Collection to CSV'), findsOneWidget);
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
        expect(find.text('Import Collection from CSV'), findsOneWidget);
        expect(find.text('Import Wishlist from CSV'), findsOneWidget);
      });

      testWidgets('tapping Import Collection from CSV on wide screen shows snackbar',
          (tester) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        await tester.tap(find.text('Import Collection from CSV'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('2 cards show Coming soon badge on wide screen', (tester) async {
        _setWideTallScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject());
        expect(find.text('Coming soon'), findsNWidgets(2));
      });
    });
  });
}

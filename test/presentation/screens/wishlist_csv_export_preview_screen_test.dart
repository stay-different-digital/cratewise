import 'dart:io';

import 'package:cratewise/application/use_cases/build_wishlist_csv_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/execute_wishlist_csv_export_use_case.dart';
import 'package:cratewise/domain/models/csv_wishlist_export_preview.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/csv/csv_file_writer.dart';
import 'package:cratewise/infrastructure/csv/wishlist_csv_mapper.dart';
import 'package:cratewise/presentation/screens/wishlist_csv_export_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<List<WishlistItem>> getAll() async => [];
  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakePreviewUseCase extends BuildWishlistCsvExportPreviewUseCase {
  _FakePreviewUseCase(this._override)
    : super(repository: _FakeWishlistRepository());

  final BuildWishlistCsvExportPreviewResult _override;

  @override
  Future<BuildWishlistCsvExportPreviewResult> execute() async => _override;
}

class _CountingPreviewUseCase extends BuildWishlistCsvExportPreviewUseCase {
  _CountingPreviewUseCase({
    required this.firstResult,
    required this.secondResult,
  }) : super(repository: _FakeWishlistRepository());

  final BuildWishlistCsvExportPreviewResult firstResult;
  final BuildWishlistCsvExportPreviewResult secondResult;
  int _calls = 0;

  @override
  Future<BuildWishlistCsvExportPreviewResult> execute() async {
    _calls++;
    return _calls == 1 ? firstResult : secondResult;
  }
}

class _FakeJobRepository implements ImportExportJobRepository {
  @override
  Future<void> add(ImportExportJob job) async {}
  @override
  Future<void> update(ImportExportJob job) async {}
  @override
  Future<ImportExportJob?> getById(String id) async => null;
  @override
  Future<List<ImportExportJob>> getRecent({
    int limit = 20,
    int offset = 0,
  }) async => [];
  Future<int> count() async => 0;
  @override
  Future<void> remove(String id) async {}
}

class _FakeCsvFileWriter implements CsvFileWriter {
  @override
  Future<String> write({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) async => '/tmp/$filename';
}

class _FakeExecuteUseCase extends ExecuteWishlistCsvExportUseCase {
  _FakeExecuteUseCase(this._override)
    : super(
        jobRepository: _FakeJobRepository(),
        fileWriter: _FakeCsvFileWriter(),
        onShare: (_) async {},
      );

  final ExecuteWishlistCsvExportResult _override;

  @override
  Future<ExecuteWishlistCsvExportResult> execute(
    CsvWishlistExportPreview preview,
  ) async => _override;
}

class _PausingExecuteUseCase extends ExecuteWishlistCsvExportUseCase {
  _PausingExecuteUseCase(this._future)
    : super(
        jobRepository: _FakeJobRepository(),
        fileWriter: _FakeCsvFileWriter(),
        onShare: (_) async {},
      );

  final Future<ExecuteWishlistCsvExportResult> _future;

  @override
  Future<ExecuteWishlistCsvExportResult> execute(
    CsvWishlistExportPreview preview,
  ) => _future;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WishlistItem _item(String id) => WishlistItem(
  id: id,
  discogsReleaseId: 1,
  artist: 'John Coltrane',
  title: 'A Love Supreme',
  priority: WishlistPriority.high,
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
);

CsvWishlistExportPreview _preview({int count = 2}) => CsvWishlistExportPreview(
  items: List.generate(count, (i) => _item('item-$i')),
  headers: wishlistCsvHeaders,
  sampleRows: [
    if (count > 0)
      [
        'John Coltrane',
        'A Love Supreme',
        '',
        '',
        '',
        '',
        '1965',
        '1',
        '',
        'High',
        '',
        '',
        '',
      ],
  ],
);

Widget _buildSubject({
  required BuildWishlistCsvExportPreviewUseCase previewUseCase,
  ExecuteWishlistCsvExportUseCase? executeUseCase,
  Future<void> Function(String)? onShareFile,
}) => MaterialApp(
  home: WishlistCsvExportPreviewScreen(
    previewUseCase: previewUseCase,
    executeUseCase: executeUseCase,
    onShareFile: onShareFile,
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WishlistCsvExportPreviewScreen', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while loading', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(const WishlistCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows Export Wishlist to CSV in AppBar', (tester) async {
        final uc = _FakePreviewUseCase(const WishlistCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
      });
    });

    group('ready state', () {
      testWidgets('shows Export preview heading', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Export preview'), findsOneWidget);
      });

      testWidgets('shows Rows to export label', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 4)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Rows to export'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
      });

      testWidgets('shows Artist column chip', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview()),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Artist'), findsOneWidget);
      });

      testWidgets('shows No data to preview when empty', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 0)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('No data to preview'), findsOneWidget);
      });

      testWidgets('shows empty note when wishlist has no items', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 0)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(
          find.text('Your wishlist is empty. Add items before exporting.'),
          findsOneWidget,
        );
      });

      testWidgets('does not show empty note when wishlist has items', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(
          find.text('Your wishlist is empty. Add items before exporting.'),
          findsNothing,
        );
      });
    });

    group('confirm button', () {
      testWidgets('shows Nothing to export when rowCount is 0', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 0)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Nothing to export'), findsOneWidget);
      });

      testWidgets('shows Export N rows for rowCount > 1', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 4)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Export 4 rows'), findsOneWidget);
      });

      testWidgets('shows Export 1 row for rowCount == 1', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 1)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Export 1 row'), findsOneWidget);
      });

      testWidgets('button is enabled when rowCount > 0 and execute provided', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(
          _buildSubject(
            previewUseCase: uc,
            executeUseCase: _FakeExecuteUseCase(
              const ExecuteWishlistCsvExportCompleted(
                jobId: 'j',
                rowCount: 2,
                filename: 'f.csv',
                filePath: '/tmp/f.csv',
              ),
            ),
          ),
        );
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Export 2 rows'),
        );
        expect(button.onPressed, isNotNull);
      });
    });

    group('error state', () {
      testWidgets('shows error message', (tester) async {
        final uc = _FakePreviewUseCase(const WishlistCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });

      testWidgets('shows Try again button', (tester) async {
        final uc = _FakePreviewUseCase(const WishlistCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('retry', () {
      testWidgets('tapping Try again triggers reload', (tester) async {
        final uc = _CountingPreviewUseCase(
          firstResult: const WishlistCsvExportPreviewError(),
          secondResult: WishlistCsvExportPreviewReady(_preview(count: 1)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        await tester.tap(find.text('Try again'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Export preview'), findsOneWidget);
      });
    });

    group('exporting state', () {
      testWidgets('shows spinner and Generating CSV label', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 2)),
        );
        final pauseCompleter = Future<ExecuteWishlistCsvExportResult>.delayed(
          const Duration(seconds: 10),
          () => const ExecuteWishlistCsvExportCompleted(
            jobId: 'j',
            rowCount: 2,
            filename: 'f.csv',
            filePath: '/tmp/f.csv',
          ),
        );
        final executeUseCase = _PausingExecuteUseCase(pauseCompleter);
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 2 rows'));
        await tester.pump();
        expect(find.text('Generating CSV…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 11));
      });
    });

    group('done state', () {
      testWidgets('shows Export complete heading', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 2)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteWishlistCsvExportCompleted(
            jobId: 'j',
            rowCount: 2,
            filename: 'wishlist_export_123.csv',
            filePath: '/tmp/wishlist_export_123.csv',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 2 rows'));
        await tester.pumpAndSettle();
        expect(find.text('Export complete'), findsOneWidget);
      });

      testWidgets('shows row count in done state', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 5)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteWishlistCsvExportCompleted(
            jobId: 'j',
            rowCount: 5,
            filename: 'f.csv',
            filePath: '/tmp/f.csv',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 5 rows'));
        await tester.pumpAndSettle();
        expect(find.text('5 rows exported'), findsOneWidget);
      });

      testWidgets('shows Done button', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 2)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteWishlistCsvExportCompleted(
            jobId: 'j',
            rowCount: 2,
            filename: 'f.csv',
            filePath: '/tmp/f.csv',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 2 rows'));
        await tester.pumpAndSettle();
        expect(find.text('Done'), findsOneWidget);
      });

      testWidgets('done state contains no token or secret text', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteWishlistCsvExportCompleted(
            jobId: 'j',
            rowCount: 1,
            filename: 'wishlist_export_123.csv',
            filePath: '/tmp/wishlist_export_123.csv',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 1 row'));
        await tester.pumpAndSettle();
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .toList();
        for (final t in texts) {
          expect(t.toLowerCase(), isNot(contains('token')));
          expect(t.toLowerCase(), isNot(contains('secret')));
        }
      });

      testWidgets('shows Share Again button in done state', (tester) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteWishlistCsvExportCompleted(
            jobId: 'j',
            rowCount: 1,
            filename: 'f.csv',
            filePath: '/tmp/f.csv',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 1 row'));
        await tester.pumpAndSettle();
        expect(find.text('Share Again'), findsOneWidget);
      });

      testWidgets('Share Again shows snackbar when file is missing', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteWishlistCsvExportCompleted(
            jobId: 'j',
            rowCount: 1,
            filename: 'f.csv',
            filePath: '/tmp/cratewise_does_not_exist_xyz.csv',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 1 row'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Share Again'));
        await tester.pump();
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('Share Again calls onShareFile when file exists', (
        tester,
      ) async {
        final tempFile = File(
          '${Directory.systemTemp.path}/cratewise_test_wl_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
        tempFile.writeAsStringSync('test');
        addTearDown(() => tempFile.deleteSync());

        final sharedPaths = <String>[];
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          ExecuteWishlistCsvExportCompleted(
            jobId: 'j',
            rowCount: 1,
            filename: 'f.csv',
            filePath: tempFile.path,
          ),
        );
        await tester.pumpWidget(
          _buildSubject(
            previewUseCase: uc,
            executeUseCase: executeUseCase,
            onShareFile: (path) async => sharedPaths.add(path),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Export 1 row'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Share Again'));
        await tester.pump();
        await tester.pump();
        expect(sharedPaths, [tempFile.path]);
      });
    });

    group('execute failure snackbar', () {
      testWidgets('shows snackbar and stays on ready state on failure', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 2)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteWishlistCsvExportFailed(
            'CSV export could not be completed',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 2 rows'));
        await tester.pump();
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Export preview'), findsOneWidget);
      });
    });

    group('wide layout', () {
      testWidgets('renders without error on wide screen', (tester) async {
        tester.view.physicalSize = const Size(2800, 2000);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final uc = _FakePreviewUseCase(
          WishlistCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Export Wishlist to CSV'), findsOneWidget);
        expect(find.text('Export preview'), findsOneWidget);
      });
    });
  });
}

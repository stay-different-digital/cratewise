import 'dart:async';

import 'package:cratewise/application/use_cases/build_wishlist_csv_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/execute_wishlist_csv_import_use_case.dart';
import 'package:cratewise/domain/models/csv_wishlist_import_preview.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/csv/csv_file_picker_service.dart';
import 'package:cratewise/presentation/screens/wishlist_csv_import_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kValidCsv =
    '''Artist,Title,Label,Catalog Number,Format,Country,Year,Discogs Release ID,Target Price,Priority,Notes,Created Date,Updated Date
Herbie Hancock,Head Hunters,Columbia,KC 32731,LP,US,1973,99999,25.00,High,Original pressing,2024-01-15T10:00:00.000000Z,2024-06-01T12:30:00.000000Z''';

const _kMissingColCsv = '''Artist,Title
Herbie Hancock,Head Hunters''';

Future<CsvPickedFile?> _pickerWith(String filename, String content) async =>
    CsvPickedFile(filename: filename, content: content);

Future<CsvPickedFile?> _cancelledPicker() async => null;

Widget _buildSubject({
  Future<CsvPickedFile?> Function()? picker,
  BuildWishlistCsvImportPreviewUseCase? useCase,
  ExecuteWishlistCsvImportUseCase? executeUseCase,
}) => MaterialApp(
  home: WishlistCsvImportPreviewScreen(
    onPickFile: picker,
    previewUseCase: useCase,
    executeUseCase: executeUseCase,
  ),
);

void _setNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
}

void _setWideScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(2800, 2000);
  tester.view.devicePixelRatio = 2.0;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WishlistCsvImportPreviewScreen', () {
    group('idle state', () {
      testWidgets('shows correct AppBar title', (tester) async {
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Import Wishlist from CSV'), findsOneWidget);
      });

      testWidgets('shows Select a CSV file heading', (tester) async {
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Select a CSV file'), findsOneWidget);
      });

      testWidgets('shows Choose file button', (tester) async {
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Choose file'), findsOneWidget);
      });

      testWidgets('no preview content shown in idle state', (tester) async {
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Import preview'), findsNothing);
      });
    });

    group('cancelled picker', () {
      testWidgets('returns to idle state when picker is cancelled', (
        tester,
      ) async {
        await tester.pumpWidget(_buildSubject(picker: _cancelledPicker));
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Select a CSV file'), findsOneWidget);
      });
    });

    group('preview state — valid file', () {
      testWidgets('shows Import preview heading after picking valid file', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('wishlist.csv', _kValidCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Import preview'), findsOneWidget);
      });

      testWidgets('shows filename in summary card', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('my_wishlist.csv', _kValidCsv),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('my_wishlist.csv'), findsOneWidget);
      });

      testWidgets('shows correct valid row count', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('wishlist.csv', _kValidCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Ready to import'), findsOneWidget);
      });

      testWidgets('confirm button shows Import N record label', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('wishlist.csv', _kValidCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Import 1 record'), findsOneWidget);
      });

      testWidgets('confirm button is disabled without execute use case', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('wishlist.csv', _kValidCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Import 1 record'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('tapping Choose different file returns to idle', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('wishlist.csv', _kValidCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose different file'));
        await tester.pumpAndSettle();
        expect(find.text('Select a CSV file'), findsOneWidget);
      });
    });

    group('preview state — failed rows', () {
      testWidgets('shows Validation errors card when rows fail', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('bad.csv', _kMissingColCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Validation errors'), findsOneWidget);
      });

      testWidgets('shows safe error message', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final preview = CsvWishlistImportPreview(
          validRows: const [],
          skippedRows: const [],
          failedRows: [
            const FailedRow(rowIndex: 0, safeErrorMessage: 'Missing artist'),
          ],
        );
        final fakeUseCase = _FakeUseCase(
          WishlistCsvImportPreviewReady(filename: 'test.csv', preview: preview),
        );
        await tester.pumpWidget(
          _buildSubject(
            picker: () async =>
                const CsvPickedFile(filename: 'test.csv', content: ''),
            useCase: fakeUseCase,
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Missing artist'), findsOneWidget);
      });

      testWidgets('Nothing to import button when validCount is 0', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('bad.csv', _kMissingColCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Nothing to import'), findsOneWidget);
      });

      testWidgets('caps displayed errors at 5, shows overflow message', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final failedRows = List.generate(
          7,
          (i) => FailedRow(rowIndex: i, safeErrorMessage: 'Error $i'),
        );
        final preview = CsvWishlistImportPreview(
          validRows: const [],
          skippedRows: const [],
          failedRows: failedRows,
        );
        final fakeUseCase = _FakeUseCase(
          WishlistCsvImportPreviewReady(filename: 'test.csv', preview: preview),
        );
        await tester.pumpWidget(
          _buildSubject(
            picker: () async =>
                const CsvPickedFile(filename: 'test.csv', content: ''),
            useCase: fakeUseCase,
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.textContaining('and 2 more'), findsOneWidget);
      });
    });

    group('preview state — skipped rows', () {
      testWidgets('shows Skipped duplicate count in summary', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final preview = CsvWishlistImportPreview(
          validRows: [
            const CsvWishlistImportRow(
              rowIndex: 0,
              artist: 'Herbie Hancock',
              title: 'Head Hunters',
              discogsReleaseId: 99999,
              priority: WishlistPriority.high,
            ),
          ],
          skippedRows: [
            const SkippedRow(
              rowIndex: 1,
              reason: 'Duplicate release ID in file',
            ),
          ],
          failedRows: const [],
        );
        final fakeUseCase = _FakeUseCase(
          WishlistCsvImportPreviewReady(filename: 'test.csv', preview: preview),
        );
        await tester.pumpWidget(
          _buildSubject(
            picker: () async =>
                const CsvPickedFile(filename: 'test.csv', content: ''),
            useCase: fakeUseCase,
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Skipped (duplicate)'), findsOneWidget);
      });
    });

    group('parse failed state', () {
      testWidgets('shows Could not read this file on parse error', (
        tester,
      ) async {
        final fakeUseCase = _FakeUseCase(
          const WishlistCsvImportPreviewParseFailed(
            'The file could not be read as a CSV',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(
            picker: () async =>
                const CsvPickedFile(filename: 'bad.csv', content: ''),
            useCase: fakeUseCase,
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Could not read this file'), findsOneWidget);
      });

      testWidgets(
        'tapping Choose different file returns to idle from parse error',
        (tester) async {
          final fakeUseCase = _FakeUseCase(
            const WishlistCsvImportPreviewParseFailed('Bad CSV'),
          );
          await tester.pumpWidget(
            _buildSubject(
              picker: () async =>
                  const CsvPickedFile(filename: 'bad.csv', content: ''),
              useCase: fakeUseCase,
            ),
          );
          await tester.tap(find.text('Choose file'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Choose different file'));
          await tester.pumpAndSettle();
          expect(find.text('Select a CSV file'), findsOneWidget);
        },
      );
    });

    group('error state', () {
      testWidgets('shows Something went wrong on unexpected error', (
        tester,
      ) async {
        final fakeUseCase = _FakeUseCase(const WishlistCsvImportPreviewError());
        await tester.pumpWidget(
          _buildSubject(
            picker: () async =>
                const CsvPickedFile(filename: 'bad.csv', content: ''),
            useCase: fakeUseCase,
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });
    });

    group('wide layout', () {
      testWidgets('shows both cards side by side when errors exist', (
        tester,
      ) async {
        _setWideScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('bad.csv', _kMissingColCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Import preview'), findsOneWidget);
        expect(find.text('Validation errors'), findsOneWidget);
      });
    });

    group('confirm and import', () {
      testWidgets(
        'confirm button is enabled with execute use case and valid rows',
        (tester) async {
          _setNarrowScreen(tester);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildSubject(
              picker: () => _pickerWith('wishlist.csv', _kValidCsv),
              executeUseCase: _FakeExecuteUseCase(
                const ExecuteWishlistCsvImportCompleted(
                  jobId: 'j1',
                  imported: 1,
                  skipped: 0,
                  failed: 0,
                ),
              ),
            ),
          );
          await tester.tap(find.text('Choose file'));
          await tester.pumpAndSettle();
          final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Import 1 record'),
          );
          expect(button.onPressed, isNotNull);
        },
      );

      testWidgets('tapping confirm enters importing state', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('wishlist.csv', _kValidCsv),
            executeUseCase: _HangingFakeExecuteUseCase(),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Import 1 record'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows done body after successful import', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('wishlist.csv', _kValidCsv),
            executeUseCase: _FakeExecuteUseCase(
              const ExecuteWishlistCsvImportCompleted(
                jobId: 'j1',
                imported: 1,
                skipped: 0,
                failed: 0,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Import 1 record'));
        await tester.pumpAndSettle();
        expect(find.text('Import complete'), findsOneWidget);
      });

      testWidgets('done body shows added to wishlist label', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('wishlist.csv', _kValidCsv),
            executeUseCase: _FakeExecuteUseCase(
              const ExecuteWishlistCsvImportCompleted(
                jobId: 'j1',
                imported: 1,
                skipped: 0,
                failed: 0,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Import 1 record'));
        await tester.pumpAndSettle();
        expect(find.text('Added to wishlist'), findsOneWidget);
      });

      testWidgets('done body shows Done button', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('wishlist.csv', _kValidCsv),
            executeUseCase: _FakeExecuteUseCase(
              const ExecuteWishlistCsvImportCompleted(
                jobId: 'j1',
                imported: 1,
                skipped: 0,
                failed: 0,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Import 1 record'));
        await tester.pumpAndSettle();
        expect(find.text('Done'), findsOneWidget);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeUseCase extends BuildWishlistCsvImportPreviewUseCase {
  _FakeUseCase(this._result);

  final BuildWishlistCsvImportPreviewResult _result;

  @override
  BuildWishlistCsvImportPreviewResult execute({
    required String filename,
    required String content,
  }) => _result;
}

class _NoOpWishlistRepo implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<List<WishlistItem>> getAll() async => [];
  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _NoOpJobRepo implements ImportExportJobRepository {
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

class _NoOpRowResultRepo implements ImportExportRowResultRepository {
  @override
  Future<void> addResult(String jobId, ImportExportRowResult result) async {}
  @override
  Future<List<ImportExportRowResult>> getResults(String jobId) async => [];
  @override
  Future<void> removeAllForJob(String jobId) async {}
}

class _FakeExecuteUseCase extends ExecuteWishlistCsvImportUseCase {
  _FakeExecuteUseCase(this._result)
    : super(
        wishlistRepository: _NoOpWishlistRepo(),
        jobRepository: _NoOpJobRepo(),
        rowResultRepository: _NoOpRowResultRepo(),
      );

  final ExecuteWishlistCsvImportResult _result;

  @override
  Future<ExecuteWishlistCsvImportResult> execute(
    CsvWishlistImportPreview preview,
  ) async => _result;
}

class _HangingFakeExecuteUseCase extends ExecuteWishlistCsvImportUseCase {
  _HangingFakeExecuteUseCase()
    : super(
        wishlistRepository: _NoOpWishlistRepo(),
        jobRepository: _NoOpJobRepo(),
        rowResultRepository: _NoOpRowResultRepo(),
      );

  @override
  Future<ExecuteWishlistCsvImportResult> execute(
    CsvWishlistImportPreview preview,
  ) => Completer<ExecuteWishlistCsvImportResult>().future;
}

import 'dart:async';

import 'package:cratewise/application/use_cases/build_collection_csv_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/execute_collection_csv_import_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/csv_collection_import_preview.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/infrastructure/csv/csv_file_picker_service.dart';
import 'package:cratewise/presentation/screens/collection_csv_import_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kValidCsv =
    '''Artist,Title,Label,Catalog Number,Format,Country,Year,Discogs Release ID,Media Condition,Sleeve Condition,Notes,Tags,Storage Location,Created Date,Updated Date
Miles Davis,Kind of Blue,Columbia,CL 1355,LP,US,1959,12345,Near Mint (NM or M-),Very Good Plus (VG+),,,,,''';

const _kMissingColCsv = '''Artist,Title
Miles Davis,Kind of Blue''';

Future<CsvPickedFile?> _pickerWith(String filename, String content) async =>
    CsvPickedFile(filename: filename, content: content);

Future<CsvPickedFile?> _cancelledPicker() async => null;

Widget _buildSubject({
  Future<CsvPickedFile?> Function()? picker,
  BuildCollectionCsvImportPreviewUseCase? useCase,
  ExecuteCollectionCsvImportUseCase? executeUseCase,
}) => MaterialApp(
  home: CollectionCsvImportPreviewScreen(
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
  group('CollectionCsvImportPreviewScreen', () {
    group('idle state', () {
      testWidgets('shows correct AppBar title', (tester) async {
        await tester.pumpWidget(_buildSubject());
        expect(find.text('Import Collection from CSV'), findsOneWidget);
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
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
          ),
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
            picker: () => _pickerWith('my_collection.csv', _kValidCsv),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('my_collection.csv'), findsOneWidget);
      });

      testWidgets('shows correct valid row count', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Ready to import'), findsOneWidget);
        expect(find.text('1'), findsWidgets);
      });

      testWidgets('confirm button shows correct label', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
          ),
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
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Import 1 record'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('shows Choose different file button', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
          ),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Choose different file'), findsOneWidget);
      });

      testWidgets('tapping Choose different file returns to idle', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
          ),
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

      testWidgets('shows error count in summary card', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(picker: () => _pickerWith('bad.csv', _kMissingColCsv)),
        );
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        expect(find.text('Errors'), findsOneWidget);
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

      testWidgets('shows safe error message text', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final preview = CsvCollectionImportPreview(
          validRows: const [],
          skippedRows: const [],
          failedRows: [
            const FailedRow(rowIndex: 0, safeErrorMessage: 'Missing artist'),
          ],
        );
        final fakeUseCase = _FakeUseCase(
          CollectionCsvImportPreviewReady(
            filename: 'test.csv',
            preview: preview,
          ),
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

      testWidgets('caps displayed errors at 5, shows overflow message', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final failedRows = List.generate(
          8,
          (i) => FailedRow(rowIndex: i, safeErrorMessage: 'Error $i'),
        );
        final preview = CsvCollectionImportPreview(
          validRows: const [],
          skippedRows: const [],
          failedRows: failedRows,
        );
        final fakeUseCase = _FakeUseCase(
          CollectionCsvImportPreviewReady(
            filename: 'test.csv',
            preview: preview,
          ),
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
        expect(find.textContaining('and 3 more'), findsOneWidget);
      });
    });

    group('preview state — skipped rows', () {
      testWidgets('shows Skipped duplicate row in summary', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final preview = CsvCollectionImportPreview(
          validRows: [
            const CsvCollectionImportRow(
              rowIndex: 0,
              artist: 'Miles Davis',
              title: 'Kind of Blue',
              discogsReleaseId: 12345,
              mediaCondition: RecordCondition.nearMint,
              sleeveCondition: RecordCondition.veryGoodPlus,
              tags: [],
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
          CollectionCsvImportPreviewReady(
            filename: 'test.csv',
            preview: preview,
          ),
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
        expect(find.text('1'), findsWidgets);
      });
    });

    group('parse failed state', () {
      testWidgets('shows Could not read this file on parse error', (
        tester,
      ) async {
        final fakeUseCase = _FakeUseCase(
          const CollectionCsvImportPreviewParseFailed(
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

      testWidgets('shows parse error reason', (tester) async {
        const reason = 'The file could not be read as a CSV';
        final fakeUseCase = _FakeUseCase(
          const CollectionCsvImportPreviewParseFailed(reason),
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
        expect(find.text(reason), findsOneWidget);
      });

      testWidgets(
        'tapping Choose different file returns to idle from parse error',
        (tester) async {
          final fakeUseCase = _FakeUseCase(
            const CollectionCsvImportPreviewParseFailed('Bad CSV'),
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
        final fakeUseCase = _FakeUseCase(
          const CollectionCsvImportPreviewError(),
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
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });

      testWidgets('tapping Try again returns to idle', (tester) async {
        final fakeUseCase = _FakeUseCase(
          const CollectionCsvImportPreviewError(),
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
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Select a CSV file'), findsOneWidget);
      });
    });

    group('wide layout', () {
      testWidgets('shows summary and errors cards side by side when wide', (
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

    group('plural labels', () {
      testWidgets('Import N records label for multiple valid rows', (
        tester,
      ) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final preview = CsvCollectionImportPreview(
          validRows: [
            const CsvCollectionImportRow(
              rowIndex: 0,
              artist: 'A',
              title: 'B',
              discogsReleaseId: 1,
              mediaCondition: RecordCondition.notSet,
              sleeveCondition: RecordCondition.notSet,
              tags: [],
            ),
            const CsvCollectionImportRow(
              rowIndex: 1,
              artist: 'C',
              title: 'D',
              discogsReleaseId: 2,
              mediaCondition: RecordCondition.notSet,
              sleeveCondition: RecordCondition.notSet,
              tags: [],
            ),
          ],
          skippedRows: const [],
          failedRows: const [],
        );
        final fakeUseCase = _FakeUseCase(
          CollectionCsvImportPreviewReady(
            filename: 'test.csv',
            preview: preview,
          ),
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
        expect(find.text('Import 2 records'), findsOneWidget);
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
              picker: () => _pickerWith('collection.csv', _kValidCsv),
              executeUseCase: _FakeExecuteUseCase(
                ExecuteCollectionCsvImportCompleted(
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

      testWidgets(
        'confirm button is disabled when validCount is 0 even with execute use case',
        (tester) async {
          _setNarrowScreen(tester);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final preview = CsvCollectionImportPreview(
            validRows: const [],
            skippedRows: const [],
            failedRows: [
              const FailedRow(rowIndex: 0, safeErrorMessage: 'Missing artist'),
            ],
          );
          final fakePreviewUseCase = _FakeUseCase(
            CollectionCsvImportPreviewReady(
              filename: 'bad.csv',
              preview: preview,
            ),
          );
          await tester.pumpWidget(
            _buildSubject(
              picker: () async =>
                  const CsvPickedFile(filename: 'bad.csv', content: ''),
              useCase: fakePreviewUseCase,
              executeUseCase: _FakeExecuteUseCase(
                const ExecuteCollectionCsvImportCompleted(
                  jobId: 'j1',
                  imported: 0,
                  skipped: 0,
                  failed: 0,
                ),
              ),
            ),
          );
          await tester.tap(find.text('Choose file'));
          await tester.pumpAndSettle();
          final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Nothing to import'),
          );
          expect(button.onPressed, isNull);
        },
      );

      testWidgets('tapping confirm enters importing state', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
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
            picker: () => _pickerWith('collection.csv', _kValidCsv),
            executeUseCase: _FakeExecuteUseCase(
              const ExecuteCollectionCsvImportCompleted(
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

      testWidgets('done body shows added to collection count', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
            executeUseCase: _FakeExecuteUseCase(
              const ExecuteCollectionCsvImportCompleted(
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
        expect(find.text('Added to collection'), findsOneWidget);
      });

      testWidgets('done body shows Done button', (tester) async {
        _setNarrowScreen(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            picker: () => _pickerWith('collection.csv', _kValidCsv),
            executeUseCase: _FakeExecuteUseCase(
              const ExecuteCollectionCsvImportCompleted(
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

class _FakeUseCase extends BuildCollectionCsvImportPreviewUseCase {
  _FakeUseCase(this._result);

  final BuildCollectionCsvImportPreviewResult _result;

  @override
  BuildCollectionCsvImportPreviewResult execute({
    required String filename,
    required String content,
  }) => _result;
}

class _NoOpCollectionRepo implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<void> update(CollectionItem item) async {}
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
  @override
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

class _FakeExecuteUseCase extends ExecuteCollectionCsvImportUseCase {
  _FakeExecuteUseCase(this._result)
    : super(
        collectionRepository: _NoOpCollectionRepo(),
        jobRepository: _NoOpJobRepo(),
        rowResultRepository: _NoOpRowResultRepo(),
      );

  final ExecuteCollectionCsvImportResult _result;

  @override
  Future<ExecuteCollectionCsvImportResult> execute(
    CsvCollectionImportPreview preview,
  ) async => _result;
}

class _HangingFakeExecuteUseCase extends ExecuteCollectionCsvImportUseCase {
  _HangingFakeExecuteUseCase()
    : super(
        collectionRepository: _NoOpCollectionRepo(),
        jobRepository: _NoOpJobRepo(),
        rowResultRepository: _NoOpRowResultRepo(),
      );

  @override
  Future<ExecuteCollectionCsvImportResult> execute(
    CsvCollectionImportPreview preview,
  ) => Completer<ExecuteCollectionCsvImportResult>().future;
}

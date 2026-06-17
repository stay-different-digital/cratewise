import 'dart:io';

import 'package:cratewise/application/use_cases/build_collection_csv_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/execute_collection_csv_export_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/csv_collection_export_preview.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/infrastructure/csv/collection_csv_mapper.dart';
import 'package:cratewise/infrastructure/csv/csv_file_writer.dart';
import 'package:cratewise/presentation/screens/collection_csv_export_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes — preview use case
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakePreviewUseCase extends BuildCollectionCsvExportPreviewUseCase {
  _FakePreviewUseCase(this._override)
    : super(repository: _FakeCollectionRepository());

  final BuildCollectionCsvExportPreviewResult _override;

  @override
  Future<BuildCollectionCsvExportPreviewResult> execute() async => _override;
}

class _CountingPreviewUseCase extends BuildCollectionCsvExportPreviewUseCase {
  _CountingPreviewUseCase({
    required this.firstResult,
    required this.secondResult,
  }) : super(repository: _FakeCollectionRepository());

  final BuildCollectionCsvExportPreviewResult firstResult;
  final BuildCollectionCsvExportPreviewResult secondResult;
  int _calls = 0;

  @override
  Future<BuildCollectionCsvExportPreviewResult> execute() async {
    _calls++;
    return _calls == 1 ? firstResult : secondResult;
  }
}

// ---------------------------------------------------------------------------
// Fakes — execute use case
// ---------------------------------------------------------------------------

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
  @override
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

class _FakeExecuteUseCase extends ExecuteCollectionCsvExportUseCase {
  _FakeExecuteUseCase(this._override)
    : super(
        jobRepository: _FakeJobRepository(),
        fileWriter: _FakeCsvFileWriter(),
        onShare: (_) async {},
      );

  final ExecuteCollectionCsvExportResult _override;

  @override
  Future<ExecuteCollectionCsvExportResult> execute(
    CsvCollectionExportPreview preview,
  ) async => _override;
}

class _PausingExecuteUseCase extends ExecuteCollectionCsvExportUseCase {
  _PausingExecuteUseCase(this._future)
    : super(
        jobRepository: _FakeJobRepository(),
        fileWriter: _FakeCsvFileWriter(),
        onShare: (_) async {},
      );

  final Future<ExecuteCollectionCsvExportResult> _future;

  @override
  Future<ExecuteCollectionCsvExportResult> execute(
    CsvCollectionExportPreview preview,
  ) => _future;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _item(String id) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: 'Miles Davis',
  title: 'Kind of Blue',
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
);

CsvCollectionExportPreview _preview({int count = 2}) =>
    CsvCollectionExportPreview(
      items: List.generate(count, (i) => _item('item-$i')),
      headers: collectionCsvHeaders,
      sampleRows: [
        if (count > 0)
          [
            'Miles Davis',
            'Kind of Blue',
            '',
            '',
            '',
            '',
            '1959',
            '1',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
          ],
      ],
    );

Widget _buildSubject({
  required BuildCollectionCsvExportPreviewUseCase previewUseCase,
  ExecuteCollectionCsvExportUseCase? executeUseCase,
  Future<void> Function(String)? onShareFile,
}) => MaterialApp(
  home: CollectionCsvExportPreviewScreen(
    previewUseCase: previewUseCase,
    executeUseCase: executeUseCase,
    onShareFile: onShareFile,
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionCsvExportPreviewScreen', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while loading', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(const CollectionCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows Export Collection to CSV in AppBar', (tester) async {
        final uc = _FakePreviewUseCase(const CollectionCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        expect(find.text('Export Collection to CSV'), findsOneWidget);
      });
    });

    group('ready state', () {
      testWidgets('shows Export preview heading', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Export preview'), findsOneWidget);
      });

      testWidgets('shows Rows to export label', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 3)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Rows to export'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows Columns label', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview()),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Columns'), findsWidgets);
      });

      testWidgets('shows Artist column chip', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview()),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Artist'), findsOneWidget);
      });

      testWidgets('shows sample data section', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.textContaining('Sample data'), findsOneWidget);
      });

      testWidgets('shows No data to preview when empty', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 0)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('No data to preview'), findsOneWidget);
      });

      testWidgets('shows empty note when collection has no items', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 0)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(
          find.text('Your collection is empty. Add items before exporting.'),
          findsOneWidget,
        );
      });

      testWidgets('does not show empty note when collection has items', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(
          find.text('Your collection is empty. Add items before exporting.'),
          findsNothing,
        );
      });
    });

    group('confirm button', () {
      testWidgets('shows Nothing to export when rowCount is 0', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 0)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Nothing to export'), findsOneWidget);
      });

      testWidgets('shows Export N rows for rowCount > 1', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 5)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Export 5 rows'), findsOneWidget);
      });

      testWidgets('shows Export 1 row for rowCount == 1', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 1)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Export 1 row'), findsOneWidget);
      });

      testWidgets('button is disabled when rowCount is 0', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 0)),
        );
        await tester.pumpWidget(
          _buildSubject(
            previewUseCase: uc,
            executeUseCase: _FakeExecuteUseCase(
              const ExecuteCollectionCsvExportCompleted(
                jobId: 'j',
                rowCount: 0,
                filename: 'f.csv',
                filePath: '/tmp/f.csv',
              ),
            ),
          ),
        );
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Nothing to export'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets(
        'button is enabled when rowCount > 0 and execute use case provided',
        (tester) async {
          final uc = _FakePreviewUseCase(
            CollectionCsvExportPreviewReady(_preview(count: 2)),
          );
          await tester.pumpWidget(
            _buildSubject(
              previewUseCase: uc,
              executeUseCase: _FakeExecuteUseCase(
                const ExecuteCollectionCsvExportCompleted(
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
        },
      );

      testWidgets('button is disabled when no execute use case provided', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Export 2 rows'),
        );
        expect(button.onPressed, isNull);
      });
    });

    group('error state', () {
      testWidgets('shows error message on CollectionCsvExportPreviewError', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(const CollectionCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });

      testWidgets('shows Try again button in error state', (tester) async {
        final uc = _FakePreviewUseCase(const CollectionCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });

      testWidgets('error state does not show confirm button', (tester) async {
        final uc = _FakePreviewUseCase(const CollectionCsvExportPreviewError());
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.byType(FilledButton), findsNothing);
      });
    });

    group('retry', () {
      testWidgets('tapping Try again triggers reload', (tester) async {
        final uc = _CountingPreviewUseCase(
          firstResult: const CollectionCsvExportPreviewError(),
          secondResult: CollectionCsvExportPreviewReady(_preview(count: 1)),
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
      testWidgets('shows spinner and label while exporting', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        final pauseCompleter = Future<ExecuteCollectionCsvExportResult>.delayed(
          const Duration(seconds: 10),
          () => const ExecuteCollectionCsvExportCompleted(
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
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportCompleted(
            jobId: 'j',
            rowCount: 2,
            filename: 'collection_export_1234.csv',
            filePath: '/tmp/collection_export_1234.csv',
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
          CollectionCsvExportPreviewReady(_preview(count: 3)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportCompleted(
            jobId: 'j',
            rowCount: 3,
            filename: 'collection_export_1234.csv',
            filePath: '/tmp/collection_export_1234.csv',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 3 rows'));
        await tester.pumpAndSettle();
        expect(find.text('3 rows exported'), findsOneWidget);
      });

      testWidgets('shows singular row wording for 1 row', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportCompleted(
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
        expect(find.text('1 row exported'), findsOneWidget);
      });

      testWidgets('shows filename in done state', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportCompleted(
            jobId: 'j',
            rowCount: 1,
            filename: 'collection_export_123.csv',
            filePath: '/tmp/collection_export_123.csv',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 1 row'));
        await tester.pumpAndSettle();
        expect(find.text('collection_export_123.csv'), findsOneWidget);
      });

      testWidgets('shows Done button', (tester) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportCompleted(
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

      testWidgets('done state does not show token or secret text', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportCompleted(
            jobId: 'j',
            rowCount: 1,
            filename: 'collection_export_123.csv',
            filePath: '/tmp/collection_export_123.csv',
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
          CollectionCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportCompleted(
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
          CollectionCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportCompleted(
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
          '${Directory.systemTemp.path}/cratewise_test_col_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
        tempFile.writeAsStringSync('test');
        addTearDown(() => tempFile.deleteSync());

        final sharedPaths = <String>[];
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          ExecuteCollectionCsvExportCompleted(
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
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportFailed(
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

      testWidgets('failure snackbar does not contain token or secret', (
        tester,
      ) async {
        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          const ExecuteCollectionCsvExportFailed(
            'CSV export could not be completed',
          ),
        );
        await tester.pumpWidget(
          _buildSubject(previewUseCase: uc, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 1 row'));
        await tester.pump();
        await tester.pump();
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        final snackText = (snackBar.content as Text).data ?? '';
        expect(snackText.toLowerCase(), isNot(contains('token')));
        expect(snackText.toLowerCase(), isNot(contains('secret')));
      });
    });

    group('wide layout', () {
      testWidgets('renders without error on wide screen', (tester) async {
        tester.view.physicalSize = const Size(2800, 2000);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final uc = _FakePreviewUseCase(
          CollectionCsvExportPreviewReady(_preview(count: 2)),
        );
        await tester.pumpWidget(_buildSubject(previewUseCase: uc));
        await tester.pump();
        expect(find.text('Export Collection to CSV'), findsOneWidget);
        expect(find.text('Export preview'), findsOneWidget);
      });
    });
  });
}

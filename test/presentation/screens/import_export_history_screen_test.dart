import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/presentation/screens/import_export_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeJobRepository implements ImportExportJobRepository {
  _FakeJobRepository({
    this.jobs = const [],
    this.throwsOnLoad = false,
    this._total,
  });

  final List<ImportExportJob> jobs;
  final bool throwsOnLoad;
  final int? _total;
  int loadCallCount = 0;
  int? lastOffset;
  final List<String> removedIds = [];

  @override
  Future<List<ImportExportJob>> getRecent({
    int limit = 20,
    int offset = 0,
  }) async {
    loadCallCount++;
    if (throwsOnLoad) throw Exception('db error');
    lastOffset = offset;
    final start = offset.clamp(0, jobs.length);
    final end = (offset + limit).clamp(0, jobs.length);
    return jobs.sublist(start, end);
  }

  @override
  Future<int> count() async => _total ?? jobs.length;

  @override
  Future<ImportExportJob?> getById(String id) async =>
      jobs.where((j) => j.id == id).firstOrNull;

  @override
  Future<void> add(ImportExportJob job) async {}

  @override
  Future<void> update(ImportExportJob job) async {}

  @override
  Future<void> remove(String id) async => removedIds.add(id);
}

/// A fake whose getRecent returns a preconfigured response per call index,
/// allowing pagination behaviour to be tested without real page sizes.
class _PagedFakeJobRepository implements ImportExportJobRepository {
  _PagedFakeJobRepository({required this.responses, required this.totalCount});

  final List<List<ImportExportJob>> responses;
  final int totalCount;
  int _callIndex = 0;
  int? lastOffset;

  @override
  Future<List<ImportExportJob>> getRecent({
    int limit = 20,
    int offset = 0,
  }) async {
    lastOffset = offset;
    if (_callIndex < responses.length) return responses[_callIndex++];
    return [];
  }

  @override
  Future<int> count() async => totalCount;

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

ImportExportJob makeJob({
  String id = 'job-1',
  ImportExportJobType jobType = ImportExportJobType.importCollectionFromDiscogs,
  String source = 'Discogs',
  String target = 'Local collection',
  ImportExportStatus status = ImportExportStatus.completed,
  int? validItems = 10,
  int? skippedItems = 2,
  int? failedItems = 0,
  String? safeErrorMessage,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 6, 1, 14, 30);
  return ImportExportJob(
    id: id,
    jobType: jobType,
    source: source,
    target: target,
    status: status,
    validItems: validItems,
    skippedItems: skippedItems,
    failedItems: failedItems,
    safeErrorMessage: safeErrorMessage,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildSubject({ImportExportJobRepository? repository}) =>
    MaterialApp(home: ImportExportHistoryScreen(repository: repository));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ImportExportHistoryScreen', () {
    group('AppBar', () {
      testWidgets('shows Import & Export History title', (tester) async {
        final repo = _FakeJobRepository();
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Import & Export History'), findsOneWidget);
      });
    });

    group('loading state', () {
      testWidgets('shows loading indicator before data loads', (tester) async {
        final repo = _FakeJobRepository();
        await tester.pumpWidget(_buildSubject(repository: repo));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('shows No history yet when list is empty', (tester) async {
        final repo = _FakeJobRepository();
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('No history yet'), findsOneWidget);
      });

      testWidgets('empty state describes what the screen shows', (
        tester,
      ) async {
        final repo = _FakeJobRepository();
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(
          find.text('Import and export jobs will appear here.'),
          findsOneWidget,
        );
      });

      testWidgets('empty state shows history icon', (tester) async {
        final repo = _FakeJobRepository();
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.byIcon(Icons.history_outlined), findsOneWidget);
      });
    });

    group('loaded state', () {
      testWidgets('shows job type label', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(jobType: ImportExportJobType.importCollectionFromDiscogs),
          ],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Import collection from Discogs'), findsOneWidget);
      });

      testWidgets('shows status chip', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [makeJob(status: ImportExportStatus.completed)],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('shows completedWithErrors status', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [makeJob(status: ImportExportStatus.completedWithErrors)],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Completed with errors'), findsOneWidget);
      });

      testWidgets('shows failed status', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(
              status: ImportExportStatus.failed,
              validItems: null,
              skippedItems: null,
              failedItems: null,
            ),
          ],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Failed'), findsOneWidget);
      });

      testWidgets('shows source and target', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [makeJob(source: 'Discogs', target: 'Local collection')],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Discogs → Local collection'), findsOneWidget);
      });

      testWidgets('shows Added count for import job', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(
              jobType: ImportExportJobType.importCollectionFromDiscogs,
              validItems: 7,
            ),
          ],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Added: '), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
      });

      testWidgets('shows Exported count for export job', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(
              jobType: ImportExportJobType.exportCollectionToDiscogs,
              validItems: 5,
            ),
          ],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Exported: '), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('shows skipped count', (tester) async {
        final repo = _FakeJobRepository(jobs: [makeJob(skippedItems: 3)]);
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Skipped: '), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows failed count', (tester) async {
        final repo = _FakeJobRepository(jobs: [makeJob(failedItems: 1)]);
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Failed: '), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('shows formatted start date', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [makeJob(createdAt: DateTime(2026, 6, 1, 14, 30))],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.textContaining('Jun 1, 2026'), findsOneWidget);
      });

      testWidgets('shows safe error message when present', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(
              status: ImportExportStatus.failed,
              safeErrorMessage: 'Export could not be completed',
              validItems: null,
              skippedItems: null,
              failedItems: null,
            ),
          ],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Export could not be completed'), findsOneWidget);
      });

      testWidgets('does not show safe error message when absent', (
        tester,
      ) async {
        final repo = _FakeJobRepository(
          jobs: [makeJob(safeErrorMessage: null)],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Export could not be completed'), findsNothing);
      });

      testWidgets('safe error message does not contain token or secret', (
        tester,
      ) async {
        final repo = _FakeJobRepository(
          jobs: [makeJob(safeErrorMessage: 'Export could not be completed')],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        final widgets = tester.widgetList<Text>(find.byType(Text));
        for (final w in widgets) {
          final text = (w.data ?? '').toLowerCase();
          expect(text, isNot(contains('token')));
          expect(text, isNot(contains('secret')));
        }
      });

      testWidgets('shows multiple jobs', (tester) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(
              id: 'j1',
              jobType: ImportExportJobType.importCollectionFromDiscogs,
            ),
            makeJob(
              id: 'j2',
              jobType: ImportExportJobType.exportWishlistToDiscogs,
            ),
          ],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Import collection from Discogs'), findsOneWidget);
        expect(find.text('Export wishlist to Discogs'), findsOneWidget);
      });

      testWidgets('does not show counts section when all counts are null', (
        tester,
      ) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(validItems: null, skippedItems: null, failedItems: null),
          ],
        );
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Added: '), findsNothing);
        expect(find.text('Skipped: '), findsNothing);
        expect(find.text('Failed: '), findsNothing);
      });

      testWidgets('does not show import/export action buttons', (tester) async {
        final repo = _FakeJobRepository(jobs: [makeJob()]);
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Import Collection from Discogs'), findsNothing);
        expect(find.text('Export Collection to Discogs'), findsNothing);
      });
    });

    group('error state', () {
      testWidgets('shows error message when load fails', (tester) async {
        final repo = _FakeJobRepository(throwsOnLoad: true);
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(
          find.text('Could not load history from device storage.'),
          findsOneWidget,
        );
      });

      testWidgets('shows Retry button on error', (tester) async {
        final repo = _FakeJobRepository(throwsOnLoad: true);
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('tapping Retry reloads the list', (tester) async {
        final repo = _FakeJobRepository(throwsOnLoad: true);
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();
        expect(repo.loadCallCount, 1);
        await tester.tap(find.text('Retry'));
        await tester.pump();
        expect(repo.loadCallCount, 2);
      });
    });
  });

  group('ImportExportHistoryScreen — pagination', () {
    testWidgets('shows job count header when jobs are loaded', (tester) async {
      final repo = _FakeJobRepository(jobs: [makeJob()]);
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();
      expect(find.textContaining('Showing 1 of 1 jobs'), findsOneWidget);
    });

    testWidgets('count header reflects total from repository', (tester) async {
      final repo = _FakeJobRepository(jobs: [makeJob()], total: 5);
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();
      expect(find.textContaining('Showing 1 of 5 jobs'), findsOneWidget);
    });

    testWidgets('shows Load more button when more jobs exist', (tester) async {
      final repo = _FakeJobRepository(jobs: [makeJob()], total: 5);
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();
      expect(find.text('Load more'), findsOneWidget);
    });

    testWidgets('does not show Load more when all jobs are loaded', (
      tester,
    ) async {
      final repo = _FakeJobRepository(jobs: [makeJob()]);
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('does not show count header on empty state', (tester) async {
      final repo = _FakeJobRepository();
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();
      expect(find.textContaining('Showing'), findsNothing);
    });

    testWidgets('Load more appends jobs and updates count', (tester) async {
      final j1 = makeJob(
        id: 'j1',
        jobType: ImportExportJobType.importCollectionFromDiscogs,
      );
      final j2 = makeJob(
        id: 'j2',
        jobType: ImportExportJobType.csvCollectionExport,
      );
      final repo = _PagedFakeJobRepository(
        responses: [
          [j1],
          [j2],
        ],
        totalCount: 2,
      );
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();

      expect(find.textContaining('Showing 1 of 2 jobs'), findsOneWidget);
      expect(find.text('Import collection from Discogs'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);

      await tester.tap(find.text('Load more'));
      await tester.pump();

      expect(find.textContaining('Showing 2 of 2 jobs'), findsOneWidget);
      expect(find.text('Import collection from Discogs'), findsOneWidget);
      expect(find.text('Export collection to CSV'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('Load more passes correct offset to repository', (
      tester,
    ) async {
      final repo = _PagedFakeJobRepository(
        responses: [
          [makeJob(id: 'j1')],
          [makeJob(id: 'j2')],
        ],
        totalCount: 2,
      );
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();

      await tester.tap(find.text('Load more'));
      await tester.pump();

      expect(repo.lastOffset, 1);
    });
  });

  group('ImportExportHistoryScreen — status chip colours', () {
    Color? chipBg(WidgetTester tester) {
      final container = tester.widget<Container>(
        find.byKey(const Key('status-chip')),
      );
      return (container.decoration as BoxDecoration?)?.color;
    }

    Widget buildWithTheme(
      ImportExportJobRepository repository,
      Brightness brightness,
    ) => MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        ),
      ),
      home: ImportExportHistoryScreen(repository: repository),
    );

    testWidgets(
      'completedWithErrors chip is visually distinct from completed in light mode',
      (tester) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(
              id: 'j1',
              status: ImportExportStatus.completed,
              createdAt: DateTime(2026, 6, 2),
            ),
            makeJob(
              id: 'j2',
              status: ImportExportStatus.completedWithErrors,
              createdAt: DateTime(2026, 6, 1),
            ),
          ],
        );
        await tester.pumpWidget(buildWithTheme(repo, Brightness.light));
        await tester.pump();

        final chips = tester
            .widgetList<Container>(find.byKey(const Key('status-chip')))
            .toList();
        expect(chips, hasLength(2));
        final completedBg = (chips[0].decoration as BoxDecoration?)?.color;
        final warningBg = (chips[1].decoration as BoxDecoration?)?.color;
        expect(completedBg, isNotNull);
        expect(warningBg, isNotNull);
        expect(completedBg, isNot(equals(warningBg)));
      },
    );

    testWidgets(
      'completedWithErrors chip is visually distinct from completed in dark mode',
      (tester) async {
        final repo = _FakeJobRepository(
          jobs: [
            makeJob(
              id: 'j1',
              status: ImportExportStatus.completed,
              createdAt: DateTime(2026, 6, 2),
            ),
            makeJob(
              id: 'j2',
              status: ImportExportStatus.completedWithErrors,
              createdAt: DateTime(2026, 6, 1),
            ),
          ],
        );
        await tester.pumpWidget(buildWithTheme(repo, Brightness.dark));
        await tester.pump();

        final chips = tester
            .widgetList<Container>(find.byKey(const Key('status-chip')))
            .toList();
        expect(chips, hasLength(2));
        final completedBg = (chips[0].decoration as BoxDecoration?)?.color;
        final warningBg = (chips[1].decoration as BoxDecoration?)?.color;
        expect(completedBg, isNotNull);
        expect(warningBg, isNotNull);
        expect(completedBg, isNot(equals(warningBg)));
      },
    );

    testWidgets('failed chip uses errorContainer background', (tester) async {
      final repo = _FakeJobRepository(
        jobs: [
          makeJob(
            status: ImportExportStatus.failed,
            validItems: null,
            skippedItems: null,
            failedItems: null,
          ),
        ],
      );
      await tester.pumpWidget(buildWithTheme(repo, Brightness.light));
      await tester.pump();

      final bg = chipBg(tester);
      final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
      expect(bg, equals(cs.errorContainer));
    });

    testWidgets('cancelled chip uses errorContainer background', (
      tester,
    ) async {
      final repo = _FakeJobRepository(
        jobs: [makeJob(status: ImportExportStatus.cancelled)],
      );
      await tester.pumpWidget(buildWithTheme(repo, Brightness.light));
      await tester.pump();

      final bg = chipBg(tester);
      final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
      expect(bg, equals(cs.errorContainer));
    });
  });

  group('ImportExportHistoryScreen — safe area', () {
    testWidgets('loaded list has SafeArea with top: false', (tester) async {
      final repo = _FakeJobRepository(jobs: [makeJob()]);
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();
      final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
      expect(safeAreas.any((sa) => !sa.top), isTrue);
    });
  });

  group('ImportExportHistoryScreen — delete', () {
    testWidgets('each job card is wrapped in a Dismissible', (tester) async {
      final repo = _FakeJobRepository(
        jobs: [
          makeJob(id: 'j1'),
          makeJob(id: 'j2'),
        ],
      );
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();

      expect(find.byKey(const ValueKey('j1')), findsOneWidget);
      expect(find.byKey(const ValueKey('j2')), findsOneWidget);
      expect(find.byType(Dismissible), findsNWidgets(2));
    });

    testWidgets('swiping left removes entry from the list immediately', (
      tester,
    ) async {
      final repo = _FakeJobRepository(
        jobs: [
          makeJob(
            id: 'j1',
            jobType: ImportExportJobType.importCollectionFromDiscogs,
          ),
        ],
      );
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();

      expect(find.text('Import collection from Discogs'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('j1')),
        const Offset(-800, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Import collection from Discogs'), findsNothing);
    });

    testWidgets('swiping shows undo snackbar', (tester) async {
      final repo = _FakeJobRepository(jobs: [makeJob(id: 'j1')]);
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('j1')),
        const Offset(-800, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entry deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('tapping undo restores the entry', (tester) async {
      final repo = _FakeJobRepository(
        jobs: [
          makeJob(
            id: 'j1',
            jobType: ImportExportJobType.importCollectionFromDiscogs,
          ),
        ],
      );
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('j1')),
        const Offset(-800, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Import collection from Discogs'), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Import collection from Discogs'), findsOneWidget);
      expect(repo.removedIds, isEmpty);
    });

    testWidgets(
      'confirming delete calls repository remove after snackbar closes',
      (tester) async {
        final repo = _FakeJobRepository(jobs: [makeJob(id: 'j1')]);
        await tester.pumpWidget(_buildSubject(repository: repo));
        await tester.pump();

        await tester.drag(
          find.byKey(const ValueKey('j1')),
          const Offset(-800, 0),
        );
        await tester.pumpAndSettle();

        // Dismiss snackbar without tapping Undo (triggers the else → remove branch)
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold)),
        ).hideCurrentSnackBar();
        await tester.pumpAndSettle();
        await tester.pump();

        expect(repo.removedIds, contains('j1'));
      },
    );

    testWidgets('count header decrements immediately after swipe', (
      tester,
    ) async {
      final repo = _FakeJobRepository(
        jobs: [
          makeJob(id: 'j1'),
          makeJob(id: 'j2'),
        ],
        total: 2,
      );
      await tester.pumpWidget(_buildSubject(repository: repo));
      await tester.pump();

      expect(find.textContaining('Showing 2 of 2 jobs'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('j1')),
        const Offset(-800, 0),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing 1 of 1 jobs'), findsOneWidget);
    });
  });
}

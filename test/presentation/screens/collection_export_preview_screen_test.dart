import 'package:cratewise/application/use_cases/build_collection_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/check_collection_export_capability_use_case.dart';
import 'package:cratewise/application/use_cases/execute_collection_export_use_case.dart';
import 'package:cratewise/domain/models/collection_export_preview.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/presentation/screens/export_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Preview use case fake
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakeUseCase extends BuildCollectionExportPreviewUseCase {
  _FakeUseCase(this._override)
    : super(
        repository: _FakeCollectionRepository(),
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
      );

  final BuildCollectionExportPreviewResult _override;
  bool executeCalled = false;

  @override
  Future<BuildCollectionExportPreviewResult> execute() async {
    executeCalled = true;
    return _override;
  }
}

class _CountingFakeUseCase extends BuildCollectionExportPreviewUseCase {
  _CountingFakeUseCase({
    required this.firstResult,
    required this.secondResult,
    required this.onCall,
  }) : super(
         repository: _FakeCollectionRepository(),
         capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
       );

  final BuildCollectionExportPreviewResult firstResult;
  final BuildCollectionExportPreviewResult secondResult;
  final VoidCallback onCall;
  int _calls = 0;

  @override
  Future<BuildCollectionExportPreviewResult> execute() async {
    onCall();
    _calls++;
    return _calls == 1 ? firstResult : secondResult;
  }
}

// ---------------------------------------------------------------------------
// Execute use case fake
// ---------------------------------------------------------------------------

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => 'tok';
  @override
  Future<String?> loadUsername() async => 'user';
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async {}
}

class _FakeImportExportJobRepository implements ImportExportJobRepository {
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

class _FakeRowResultRepository implements ImportExportRowResultRepository {
  @override
  Future<void> addResult(String jobId, ImportExportRowResult result) async {}
  @override
  Future<List<ImportExportRowResult>> getResults(String jobId) async => [];
  @override
  Future<void> removeAllForJob(String jobId) async {}
}

class _FakeExecuteUseCase extends ExecuteCollectionExportUseCase {
  _FakeExecuteUseCase(this._override)
    : super(
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
        tokenStorage: _FakeTokenStorage(),
        apiClient: DiscogsApiClient(
          httpClient: MockClient((_) async => http.Response('', 201)),
        ),
        collectionRepository: _FakeCollectionRepository(),
        jobRepository: _FakeImportExportJobRepository(),
        rowResultRepository: _FakeRowResultRepository(),
      );

  final ExecuteCollectionExportResult _override;

  @override
  Future<ExecuteCollectionExportResult> execute(
    CollectionExportPreview preview, {
    void Function(int, int, String)? onProgress,
  }) async => _override;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionExportPreview makePreview({
  int eligibleCount = 0,
  int alreadySyncedCount = 0,
  int invalidCount = 0,
}) {
  final rows = <CollectionExportRow>[
    for (int i = 0; i < eligibleCount; i++)
      EligibleExportRow(
        itemId: 'e-$i',
        releaseId: 100 + i,
        artist: 'Artist',
        title: 'Eligible $i',
      ),
    for (int i = 0; i < alreadySyncedCount; i++)
      AlreadySyncedExportRow(
        itemId: 's-$i',
        releaseId: 200 + i,
        artist: 'Artist',
        title: 'Synced $i',
      ),
    for (int i = 0; i < invalidCount; i++)
      InvalidExportRow(
        itemId: 'x-$i',
        releaseId: 0,
        artist: 'Artist',
        title: 'Invalid $i',
        reason: 'Missing Discogs release ID',
      ),
  ];
  return CollectionExportPreview(rows: rows);
}

Widget buildSubject({
  required BuildCollectionExportPreviewUseCase useCase,
  ExecuteCollectionExportUseCase? executeUseCase,
}) => MaterialApp(
  home: CollectionExportPreviewScreen(
    useCase: useCase,
    executeUseCase: executeUseCase,
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionExportPreviewScreen', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while loading', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported('N/A'),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows Export Collection to Discogs in AppBar', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported('N/A'),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
      });

      testWidgets('calls execute on initState', (tester) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported('N/A'),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        expect(useCase.executeCalled, isTrue);
      });
    });

    group('not supported state', () {
      testWidgets('shows Export not available heading', (tester) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported('Feature coming soon.'),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Export not available'), findsOneWidget);
      });

      testWidgets('shows the not-supported reason text', (tester) async {
        const reason = 'Export to Discogs is not available yet.';
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported(reason),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text(reason), findsOneWidget);
      });

      testWidgets('does not show a confirm button in not-supported state', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported('N/A'),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.byType(FilledButton), findsNothing);
      });

      testWidgets('not-supported reason does not contain token or secret', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported(
            'Export to Discogs is not available yet. '
            'You can export your collection as a CSV file instead.',
          ),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .toList();
        for (final t in texts) {
          expect(t.toLowerCase(), isNot(contains('token')));
          expect(t.toLowerCase(), isNot(contains('secret')));
        }
      });
    });

    group('ready state', () {
      testWidgets('shows Export preview heading after load', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview()),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Export preview'), findsOneWidget);
      });

      testWidgets('shows total local items count', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 2, alreadySyncedCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Total local items'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows eligible count as Ready to export', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 2, alreadySyncedCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Ready to export'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('shows already synced count', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 1, alreadySyncedCount: 3),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Already linked to Discogs'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows invalid count as Cannot export', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 1, invalidCount: 2),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Cannot export'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('shows zero for all counts on empty collection', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview()),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('0'), findsNWidgets(4));
      });
    });

    group('confirm button', () {
      testWidgets('shows Nothing to export when eligible count is 0', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview()),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Nothing to export'), findsOneWidget);
      });

      testWidgets('shows Export N records for eligibleCount > 1', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 5)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Export 5 records'), findsOneWidget);
      });

      testWidgets('shows Export 1 record for eligibleCount == 1', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Export 1 record'), findsOneWidget);
      });

      testWidgets('confirm button is disabled when nothing to export', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview()),
        );
        final executeUseCase = _FakeExecuteUseCase(
          ExecuteExportCompleted(
            jobId: 'j',
            exported: 0,
            skipped: 0,
            failed: 0,
          ),
        );
        await tester.pumpWidget(
          buildSubject(useCase: useCase, executeUseCase: executeUseCase),
        );
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Nothing to export'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets(
        'confirm button is enabled when eligible items exist and execute use case provided',
        (tester) async {
          final useCase = _FakeUseCase(
            CollectionExportPreviewReady(makePreview(eligibleCount: 3)),
          );
          final executeUseCase = _FakeExecuteUseCase(
            ExecuteExportCompleted(
              jobId: 'j',
              exported: 3,
              skipped: 0,
              failed: 0,
            ),
          );
          await tester.pumpWidget(
            buildSubject(useCase: useCase, executeUseCase: executeUseCase),
          );
          await tester.pump();
          final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Export 3 records'),
          );
          expect(button.onPressed, isNotNull);
        },
      );

      testWidgets(
        'confirm button is disabled when eligible items exist but no execute use case',
        (tester) async {
          final useCase = _FakeUseCase(
            CollectionExportPreviewReady(makePreview(eligibleCount: 3)),
          );
          await tester.pumpWidget(buildSubject(useCase: useCase));
          await tester.pump();
          final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Export 3 records'),
          );
          expect(button.onPressed, isNull);
        },
      );
    });

    group('notes card', () {
      testWidgets('shows notes when already-synced items exist', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(alreadySyncedCount: 2)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Notes'), findsOneWidget);
        expect(
          find.textContaining('already linked to your Discogs collection'),
          findsOneWidget,
        );
      });

      testWidgets('shows notes when invalid items exist', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(invalidCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Notes'), findsOneWidget);
        expect(find.textContaining('cannot be exported'), findsOneWidget);
      });

      testWidgets('no notes card when all items are eligible', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 3)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Notes'), findsNothing);
      });

      testWidgets('plural wording for multiple already-synced items', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(alreadySyncedCount: 3)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.textContaining('3 items are'), findsOneWidget);
      });

      testWidgets('singular wording for one already-synced item', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(alreadySyncedCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.textContaining('1 item is'), findsOneWidget);
      });

      testWidgets('plural wording for multiple invalid items', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(invalidCount: 4)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(
          find.textContaining('4 items cannot be exported'),
          findsOneWidget,
        );
      });

      testWidgets('singular wording for one invalid item', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(invalidCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(
          find.textContaining('1 item cannot be exported'),
          findsOneWidget,
        );
      });
    });

    group('error state', () {
      testWidgets('shows error message on CollectionExportPreviewError', (
        tester,
      ) async {
        final useCase = _FakeUseCase(const CollectionExportPreviewError());
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });

      testWidgets('shows Try again button in error state', (tester) async {
        final useCase = _FakeUseCase(const CollectionExportPreviewError());
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });

      testWidgets('error state does not show confirm button', (tester) async {
        final useCase = _FakeUseCase(const CollectionExportPreviewError());
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.byType(FilledButton), findsNothing);
      });
    });

    group('retry', () {
      testWidgets('tapping Try again triggers reload', (tester) async {
        int callCount = 0;
        final useCase = _CountingFakeUseCase(
          firstResult: const CollectionExportPreviewError(),
          secondResult: CollectionExportPreviewReady(
            makePreview(eligibleCount: 1),
          ),
          onCall: () => callCount++,
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
        await tester.tap(find.text('Try again'));
        await tester.pump();
        await tester.pump();
        expect(callCount, 2);
      });
    });

    group('exporting state', () {
      testWidgets('shows spinner and progress label while exporting', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 2)),
        );
        // Execute use case never completes (completer never resolved) — use
        // a fake that pauses to let us observe the exporting state.
        final pauseCompleter = Future<ExecuteCollectionExportResult>.delayed(
          const Duration(seconds: 10),
          () => ExecuteExportCompleted(
            jobId: 'j',
            exported: 2,
            skipped: 0,
            failed: 0,
          ),
        );
        late CollectionExportPreview capturedPreview;
        final executeUseCase = _PausingExecuteUseCase(
          pauseCompleter,
          onExecute: (p) => capturedPreview = p,
        );
        await tester.pumpWidget(
          buildSubject(useCase: useCase, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 2 records'));
        await tester.pump();
        expect(find.text('Exporting your collection…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Suppress async leakage.
        capturedPreview; // suppress unused warning
        await tester.pumpAndSettle(const Duration(seconds: 11));
      });

      testWidgets('shows Exporting item N of M when progress callback fires', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 2)),
        );
        final executeUseCase = _ProgressingExecuteUseCase();
        await tester.pumpWidget(
          buildSubject(useCase: useCase, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 2 records'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Exporting item 1 of 2…'), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 11));
      });

      testWidgets(
        'shows current item description when progress callback fires',
        (tester) async {
          final useCase = _FakeUseCase(
            CollectionExportPreviewReady(makePreview(eligibleCount: 2)),
          );
          final executeUseCase = _ProgressingExecuteUseCase();
          await tester.pumpWidget(
            buildSubject(useCase: useCase, executeUseCase: executeUseCase),
          );
          await tester.pump();
          await tester.tap(find.text('Export 2 records'));
          await tester.pump();
          await tester.pump();
          expect(find.textContaining('Artist – Eligible 0'), findsOneWidget);
          await tester.pumpAndSettle(const Duration(seconds: 11));
        },
      );

      testWidgets(
        'shows LinearProgressIndicator when progress callback fires',
        (tester) async {
          final useCase = _FakeUseCase(
            CollectionExportPreviewReady(makePreview(eligibleCount: 2)),
          );
          final executeUseCase = _ProgressingExecuteUseCase();
          await tester.pumpWidget(
            buildSubject(useCase: useCase, executeUseCase: executeUseCase),
          );
          await tester.pump();
          await tester.tap(find.text('Export 2 records'));
          await tester.pump();
          await tester.pump();
          expect(find.byType(LinearProgressIndicator), findsOneWidget);
          await tester.pumpAndSettle(const Duration(seconds: 11));
        },
      );
    });

    group('export done state', () {
      testWidgets('shows Export complete heading', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 2)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          ExecuteExportCompleted(
            jobId: 'j',
            exported: 2,
            skipped: 0,
            failed: 0,
          ),
        );
        await tester.pumpWidget(
          buildSubject(useCase: useCase, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 2 records'));
        await tester.pumpAndSettle();
        expect(find.text('Export complete'), findsOneWidget);
      });

      testWidgets('shows exported count', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 3)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          ExecuteExportCompleted(
            jobId: 'j',
            exported: 3,
            skipped: 0,
            failed: 0,
          ),
        );
        await tester.pumpWidget(
          buildSubject(useCase: useCase, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 3 records'));
        await tester.pumpAndSettle();
        expect(find.text('Added to Discogs'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows Done button', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 1)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          ExecuteExportCompleted(
            jobId: 'j',
            exported: 1,
            skipped: 0,
            failed: 0,
          ),
        );
        await tester.pumpWidget(
          buildSubject(useCase: useCase, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 1 record'));
        await tester.pumpAndSettle();
        expect(find.text('Done'), findsOneWidget);
      });

      testWidgets('shows Failed count when some items failed', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 3)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          ExecuteExportCompleted(
            jobId: 'j',
            exported: 2,
            skipped: 0,
            failed: 1,
          ),
        );
        await tester.pumpWidget(
          buildSubject(useCase: useCase, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 3 records'));
        await tester.pumpAndSettle();
        expect(find.text('Failed'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('does not show Failed row when failed count is zero', (
        tester,
      ) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 2)),
        );
        final executeUseCase = _FakeExecuteUseCase(
          ExecuteExportCompleted(
            jobId: 'j',
            exported: 2,
            skipped: 0,
            failed: 0,
          ),
        );
        await tester.pumpWidget(
          buildSubject(useCase: useCase, executeUseCase: executeUseCase),
        );
        await tester.pump();
        await tester.tap(find.text('Export 2 records'));
        await tester.pumpAndSettle();
        expect(find.text('Failed'), findsNothing);
      });
    });

    group('execute — not supported transition', () {
      testWidgets(
        'transitions to not-supported state when execute returns NotSupported',
        (tester) async {
          final useCase = _FakeUseCase(
            CollectionExportPreviewReady(makePreview(eligibleCount: 1)),
          );
          final executeUseCase = _FakeExecuteUseCase(
            const ExecuteExportNotSupported('No write access.'),
          );
          await tester.pumpWidget(
            buildSubject(useCase: useCase, executeUseCase: executeUseCase),
          );
          await tester.pump();
          await tester.tap(find.text('Export 1 record'));
          await tester.pumpAndSettle();
          expect(find.text('Export not available'), findsOneWidget);
        },
      );
    });

    group('execute — no token transition', () {
      testWidgets(
        'transitions to no-token state when execute returns NoToken',
        (tester) async {
          final useCase = _FakeUseCase(
            CollectionExportPreviewReady(makePreview(eligibleCount: 1)),
          );
          final executeUseCase = _FakeExecuteUseCase(
            const ExecuteExportNoToken(),
          );
          await tester.pumpWidget(
            buildSubject(useCase: useCase, executeUseCase: executeUseCase),
          );
          await tester.pump();
          await tester.tap(find.text('Export 1 record'));
          await tester.pumpAndSettle();
          expect(find.text('No Discogs account connected'), findsOneWidget);
        },
      );
    });

    group('execute — failure snackbar', () {
      testWidgets(
        'shows snackbar and stays on ready state on execute failure',
        (tester) async {
          final useCase = _FakeUseCase(
            CollectionExportPreviewReady(makePreview(eligibleCount: 1)),
          );
          final executeUseCase = _FakeExecuteUseCase(
            const ExecuteExportFailed('Export could not be completed'),
          );
          await tester.pumpWidget(
            buildSubject(useCase: useCase, executeUseCase: executeUseCase),
          );
          await tester.pump();
          await tester.tap(find.text('Export 1 record'));
          await tester.pump();
          await tester.pump();
          expect(find.byType(SnackBar), findsOneWidget);
          expect(find.text('Export preview'), findsOneWidget);
        },
      );
    });

    group('wide layout', () {
      testWidgets('renders without error on wide screen', (tester) async {
        tester.view.physicalSize = const Size(2800, 2000);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 2, alreadySyncedCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
        expect(find.text('Export preview'), findsOneWidget);
      });

      testWidgets('not-supported state renders on wide screen', (tester) async {
        tester.view.physicalSize = const Size(2800, 2000);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported('Not available yet.'),
        );
        await tester.pumpWidget(buildSubject(useCase: useCase));
        await tester.pump();
        expect(find.text('Export not available'), findsOneWidget);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers for async-state tests
// ---------------------------------------------------------------------------

class _PausingExecuteUseCase extends ExecuteCollectionExportUseCase {
  _PausingExecuteUseCase(this._future, {required this.onExecute})
    : super(
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
        tokenStorage: _FakeTokenStorage(),
        apiClient: DiscogsApiClient(
          httpClient: MockClient((_) async => http.Response('', 201)),
        ),
        collectionRepository: _FakeCollectionRepository(),
        jobRepository: _FakeImportExportJobRepository(),
        rowResultRepository: _FakeRowResultRepository(),
      );

  final Future<ExecuteCollectionExportResult> _future;
  final void Function(CollectionExportPreview) onExecute;

  @override
  Future<ExecuteCollectionExportResult> execute(
    CollectionExportPreview preview, {
    void Function(int, int, String)? onProgress,
  }) {
    onExecute(preview);
    return _future;
  }
}

class _ProgressingExecuteUseCase extends ExecuteCollectionExportUseCase {
  _ProgressingExecuteUseCase()
    : super(
        capabilityUseCase: const CheckCollectionExportCapabilityUseCase(),
        tokenStorage: _FakeTokenStorage(),
        apiClient: DiscogsApiClient(
          httpClient: MockClient((_) async => http.Response('', 201)),
        ),
        collectionRepository: _FakeCollectionRepository(),
        jobRepository: _FakeImportExportJobRepository(),
        rowResultRepository: _FakeRowResultRepository(),
      );

  @override
  Future<ExecuteCollectionExportResult> execute(
    CollectionExportPreview preview, {
    void Function(int, int, String)? onProgress,
  }) async {
    onProgress?.call(1, 2, 'Artist – Eligible 0');
    await Future<void>.delayed(const Duration(seconds: 10));
    return ExecuteExportCompleted(
      jobId: 'j',
      exported: 2,
      skipped: 0,
      failed: 0,
    );
  }
}

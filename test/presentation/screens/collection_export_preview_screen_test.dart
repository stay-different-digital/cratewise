import 'package:cratewise/application/use_cases/build_collection_export_preview_use_case.dart';
import 'package:cratewise/application/use_cases/check_collection_export_capability_use_case.dart';
import 'package:cratewise/domain/models/collection_export_preview.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/presentation/screens/collection_export_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
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

Widget buildSubject(BuildCollectionExportPreviewUseCase useCase) =>
    MaterialApp(
      home: CollectionExportPreviewScreen(useCase: useCase),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionExportPreviewScreen', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while loading',
          (tester) async {
        final useCase =
            _FakeUseCase(const CollectionExportPreviewNotSupported('N/A'));
        await tester.pumpWidget(buildSubject(useCase));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows Export Collection to Discogs in AppBar',
          (tester) async {
        final useCase =
            _FakeUseCase(const CollectionExportPreviewNotSupported('N/A'));
        await tester.pumpWidget(buildSubject(useCase));
        expect(find.text('Export Collection to Discogs'), findsOneWidget);
      });

      testWidgets('calls execute on initState', (tester) async {
        final useCase =
            _FakeUseCase(const CollectionExportPreviewNotSupported('N/A'));
        await tester.pumpWidget(buildSubject(useCase));
        expect(useCase.executeCalled, isTrue);
      });
    });

    group('not supported state', () {
      testWidgets('shows Export not available heading', (tester) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported('Feature coming soon.'),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Export not available'), findsOneWidget);
      });

      testWidgets('shows the not-supported reason text', (tester) async {
        const reason = 'Export to Discogs is not available yet.';
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported(reason),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text(reason), findsOneWidget);
      });

      testWidgets('does not show a confirm button in not-supported state',
          (tester) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported('N/A'),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.byType(FilledButton), findsNothing);
      });

      testWidgets('not-supported reason does not contain token or secret',
          (tester) async {
        final useCase = _FakeUseCase(
          const CollectionExportPreviewNotSupported(
            'Export to Discogs is not available yet. '
            'You can export your collection as a CSV file instead.',
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
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
        final useCase =
            _FakeUseCase(CollectionExportPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Export preview'), findsOneWidget);
      });

      testWidgets('shows total local items count', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 2, alreadySyncedCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Total local items'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows eligible count as Ready to export', (tester) async {
        // alreadySyncedCount=1 keeps totalCount(3) != eligibleCount(2) so '2' appears once.
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 2, alreadySyncedCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Ready to export'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('shows already synced count', (tester) async {
        // eligibleCount=1 keeps totalCount(4) != alreadySyncedCount(3) so '3' appears once.
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 1, alreadySyncedCount: 3),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Already linked to Discogs'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows invalid count as Cannot export', (tester) async {
        // eligibleCount=1 keeps totalCount(3) != invalidCount(2) so '2' appears once.
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(
            makePreview(eligibleCount: 1, invalidCount: 2),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Cannot export'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('shows zero for all counts on empty collection',
          (tester) async {
        final useCase =
            _FakeUseCase(CollectionExportPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('0'), findsNWidgets(4));
      });
    });

    group('confirm button', () {
      testWidgets('shows Nothing to export when eligible count is 0',
          (tester) async {
        final useCase =
            _FakeUseCase(CollectionExportPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Nothing to export'), findsOneWidget);
      });

      testWidgets('shows Export N records for eligibleCount > 1', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 5)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Export 5 records'), findsOneWidget);
      });

      testWidgets('shows Export 1 record for eligibleCount == 1',
          (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Export 1 record'), findsOneWidget);
      });

      testWidgets('confirm button is disabled when eligible items exist',
          (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 3)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Export 3 records'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('confirm button disabled when nothing to export',
          (tester) async {
        final useCase =
            _FakeUseCase(CollectionExportPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Nothing to export'),
        );
        expect(button.onPressed, isNull);
      });
    });

    group('notes card', () {
      testWidgets('shows notes when already-synced items exist', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(alreadySyncedCount: 2)),
        );
        await tester.pumpWidget(buildSubject(useCase));
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
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Notes'), findsOneWidget);
        expect(find.textContaining('cannot be exported'), findsOneWidget);
      });

      testWidgets('no notes card when all items are eligible', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(eligibleCount: 3)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Notes'), findsNothing);
      });

      testWidgets('plural wording for multiple already-synced items',
          (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(alreadySyncedCount: 3)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('3 items are'), findsOneWidget);
      });

      testWidgets('singular wording for one already-synced item', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(alreadySyncedCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('1 item is'), findsOneWidget);
      });

      testWidgets('plural wording for multiple invalid items', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(invalidCount: 4)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('4 items cannot be exported'), findsOneWidget);
      });

      testWidgets('singular wording for one invalid item', (tester) async {
        final useCase = _FakeUseCase(
          CollectionExportPreviewReady(makePreview(invalidCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('1 item cannot be exported'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error message on CollectionExportPreviewError',
          (tester) async {
        final useCase =
            _FakeUseCase(const CollectionExportPreviewError());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });

      testWidgets('shows Try again button in error state', (tester) async {
        final useCase =
            _FakeUseCase(const CollectionExportPreviewError());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });

      testWidgets('error state does not show confirm button', (tester) async {
        final useCase =
            _FakeUseCase(const CollectionExportPreviewError());
        await tester.pumpWidget(buildSubject(useCase));
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
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
        await tester.tap(find.text('Try again'));
        await tester.pump();
        await tester.pump();
        expect(callCount, 2);
      });
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
        await tester.pumpWidget(buildSubject(useCase));
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
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Export not available'), findsOneWidget);
      });
    });
  });
}

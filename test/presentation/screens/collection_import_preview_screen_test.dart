import 'package:cratewise/application/use_cases/build_collection_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/fetch_collection_import_preview_use_case.dart';
import 'package:cratewise/domain/models/collection_import_preview.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/presentation/screens/collection_import_preview_screen.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake use case
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
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

class _FakeUseCase extends FetchCollectionImportPreviewUseCase {
  _FakeUseCase(this._result)
      : super(
          previewBuilder: BuildCollectionImportPreviewUseCase(
            _FakeCollectionRepository(),
          ),
        );

  final FetchCollectionImportPreviewResult _result;
  bool executeCalled = false;

  @override
  Future<FetchCollectionImportPreviewResult> execute() async {
    executeCalled = true;
    return _result;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionImportPreview makePreview({
  int newCount = 0,
  int duplicateCount = 0,
  int invalidCount = 0,
}) {
  final rows = <CollectionImportRow>[
    for (int i = 0; i < newCount; i++)
      NewCollectionRow(
        releaseId: 100 + i,
        title: 'New Album $i',
        artist: 'Artist',
      ),
    for (int i = 0; i < duplicateCount; i++)
      DuplicateCollectionRow(
        releaseId: 200 + i,
        title: 'Duplicate $i',
        artist: 'Artist',
      ),
    for (int i = 0; i < invalidCount; i++)
      InvalidCollectionRow(
        releaseId: 0,
        title: '',
        artist: 'Artist',
        reason: 'Missing title',
      ),
  ];
  return CollectionImportPreview(rows: rows);
}

Widget buildSubject(FetchCollectionImportPreviewUseCase useCase) =>
    MaterialApp(
      home: CollectionImportPreviewScreen(useCase: useCase),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionImportPreviewScreen', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while loading',
          (tester) async {
        final useCase = _FakeUseCase(FetchPreviewReady(makePreview()));
        // Check initial state before the async execute() completes.
        await tester.pumpWidget(buildSubject(useCase));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows Import from Discogs in AppBar', (tester) async {
        final useCase = _FakeUseCase(FetchPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        expect(find.text('Import from Discogs'), findsOneWidget);
      });

      testWidgets('calls execute on initState', (tester) async {
        final useCase = _FakeUseCase(FetchPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        expect(useCase.executeCalled, isTrue);
      });
    });

    group('preview ready state', () {
      testWidgets('shows Collection preview heading after load', (tester) async {
        final useCase =
            _FakeUseCase(FetchPreviewReady(makePreview(newCount: 3)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Collection preview'), findsOneWidget);
      });

      testWidgets('shows total count', (tester) async {
        final useCase = _FakeUseCase(
          FetchPreviewReady(
            makePreview(newCount: 2, duplicateCount: 1, invalidCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Total found'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
      });

      testWidgets('shows new count', (tester) async {
        // duplicateCount=1 ensures totalCount(6) != newCount(5) so '5' appears once.
        final useCase = _FakeUseCase(
          FetchPreviewReady(makePreview(newCount: 5, duplicateCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('New items'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('shows duplicate count', (tester) async {
        // newCount=1 ensures totalCount(4) != duplicateCount(3) so '3' appears once.
        final useCase = _FakeUseCase(
          FetchPreviewReady(makePreview(duplicateCount: 3, newCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Already in collection'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows invalid count', (tester) async {
        // newCount=1 ensures totalCount(3) != invalidCount(2) so '2' appears once.
        final useCase = _FakeUseCase(
          FetchPreviewReady(makePreview(invalidCount: 2, newCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Cannot import'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('shows zero for all counts on empty collection',
          (tester) async {
        final useCase = _FakeUseCase(FetchPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('0'), findsNWidgets(4));
      });
    });

    group('confirm button', () {
      testWidgets('shows Nothing to import when newCount is 0', (tester) async {
        final useCase = _FakeUseCase(FetchPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Nothing to import'), findsOneWidget);
      });

      testWidgets('shows Import N records for newCount > 1', (tester) async {
        final useCase =
            _FakeUseCase(FetchPreviewReady(makePreview(newCount: 7)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Import 7 records'), findsOneWidget);
      });

      testWidgets('shows Import 1 record for newCount == 1', (tester) async {
        final useCase =
            _FakeUseCase(FetchPreviewReady(makePreview(newCount: 1)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Import 1 record'), findsOneWidget);
      });

      testWidgets('confirm button is disabled (no import yet)', (tester) async {
        final useCase =
            _FakeUseCase(FetchPreviewReady(makePreview(newCount: 3)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Import 3 records'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('confirm button disabled when nothing to import',
          (tester) async {
        final useCase = _FakeUseCase(FetchPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Nothing to import'),
        );
        expect(button.onPressed, isNull);
      });
    });

    group('warning card', () {
      testWidgets('shows warning notes when duplicates exist', (tester) async {
        final useCase = _FakeUseCase(
          FetchPreviewReady(makePreview(duplicateCount: 2)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Notes'), findsOneWidget);
        expect(
          find.textContaining('already in your collection'),
          findsOneWidget,
        );
      });

      testWidgets('shows warning when invalid items exist', (tester) async {
        final useCase = _FakeUseCase(
          FetchPreviewReady(makePreview(invalidCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Notes'), findsOneWidget);
        expect(find.textContaining('cannot be imported'), findsOneWidget);
      });

      testWidgets('no warning card when all items are new', (tester) async {
        final useCase =
            _FakeUseCase(FetchPreviewReady(makePreview(newCount: 5)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Notes'), findsNothing);
      });

      testWidgets('plural wording for multiple duplicates', (tester) async {
        final useCase = _FakeUseCase(
          FetchPreviewReady(makePreview(duplicateCount: 3)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('3 items are'), findsOneWidget);
      });

      testWidgets('singular wording for one duplicate', (tester) async {
        final useCase = _FakeUseCase(
          FetchPreviewReady(makePreview(duplicateCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('1 item is'), findsOneWidget);
      });
    });

    group('no token state', () {
      testWidgets('shows no token message', (tester) async {
        final useCase = _FakeUseCase(const FetchPreviewNoToken());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('No Discogs account connected'), findsOneWidget);
      });

      testWidgets('no token state has helpful instructions', (tester) async {
        final useCase = _FakeUseCase(const FetchPreviewNoToken());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(
          find.textContaining('Connect your Discogs account'),
          findsOneWidget,
        );
      });

      testWidgets('no token state does not show confirm button', (tester) async {
        final useCase = _FakeUseCase(const FetchPreviewNoToken());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.byType(FilledButton), findsNothing);
      });
    });

    group('rate limited state', () {
      testWidgets('shows rate limit message', (tester) async {
        final useCase = _FakeUseCase(const FetchPreviewRateLimited());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('rate-limiting'), findsOneWidget);
      });

      testWidgets('shows Try again button for rate limit', (tester) async {
        final useCase = _FakeUseCase(const FetchPreviewRateLimited());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('network error state', () {
      testWidgets('shows network error message', (tester) async {
        final useCase = _FakeUseCase(const FetchPreviewNetworkError());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('No internet connection'), findsOneWidget);
      });

      testWidgets('shows Try again button for network error', (tester) async {
        final useCase = _FakeUseCase(const FetchPreviewNetworkError());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('generic error state', () {
      testWidgets('shows error message', (tester) async {
        final useCase = _FakeUseCase(
          const FetchPreviewError(InvalidTokenError()),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });

      testWidgets('shows Try again button for generic error', (tester) async {
        final useCase = _FakeUseCase(
          const FetchPreviewError(DiscogsUnavailableError()),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('retry', () {
      testWidgets('tapping Try again triggers reload', (tester) async {
        int callCount = 0;
        final countingUseCase = _CountingFakeUseCase(
          firstResult: const FetchPreviewNetworkError(),
          secondResult: FetchPreviewReady(makePreview(newCount: 1)),
          onCall: () => callCount++,
        );
        await tester.pumpWidget(buildSubject(countingUseCase));
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
          FetchPreviewReady(makePreview(newCount: 2, duplicateCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Import from Discogs'), findsOneWidget);
        expect(find.text('Collection preview'), findsOneWidget);
      });

      testWidgets('shows summary card on wide screen', (tester) async {
        tester.view.physicalSize = const Size(2800, 2000);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // duplicateCount=1 keeps totalCount(6) != newCount(5) so '5' appears once.
        final useCase = _FakeUseCase(
          FetchPreviewReady(makePreview(newCount: 5, duplicateCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Collection preview'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });
    });

    group('security', () {
      testWidgets('no token state does not show any token value', (tester) async {
        final useCase = _FakeUseCase(const FetchPreviewNoToken());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .toList();
        for (final t in texts) {
          expect(t.toLowerCase(), isNot(contains('token')));
        }
      });

      testWidgets('error state does not show token or secret', (tester) async {
        final useCase = _FakeUseCase(
          const FetchPreviewError(InvalidTokenError()),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .toList();
        for (final t in texts) {
          expect(t.toLowerCase(), isNot(contains('secret')));
        }
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: counting fake use case for retry test
// ---------------------------------------------------------------------------

class _CountingFakeUseCase extends FetchCollectionImportPreviewUseCase {
  _CountingFakeUseCase({
    required this.firstResult,
    required this.secondResult,
    required this.onCall,
  }) : super(
          previewBuilder: BuildCollectionImportPreviewUseCase(
            _FakeCollectionRepository(),
          ),
        );

  final FetchCollectionImportPreviewResult firstResult;
  final FetchCollectionImportPreviewResult secondResult;
  final VoidCallback onCall;
  int _calls = 0;

  @override
  Future<FetchCollectionImportPreviewResult> execute() async {
    onCall();
    _calls++;
    return _calls == 1 ? firstResult : secondResult;
  }
}

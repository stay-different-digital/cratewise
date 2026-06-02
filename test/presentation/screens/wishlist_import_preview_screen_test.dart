import 'package:cratewise/application/use_cases/build_wishlist_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/fetch_wishlist_import_preview_use_case.dart';
import 'package:cratewise/domain/models/wishlist_import_preview.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/screens/wishlist_import_preview_screen.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake use case
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
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

class _FakeUseCase extends FetchWishlistImportPreviewUseCase {
  _FakeUseCase(this._result)
      : super(
          previewBuilder: BuildWishlistImportPreviewUseCase(
            _FakeWishlistRepository(),
          ),
        );

  final FetchWishlistImportPreviewResult _result;
  bool executeCalled = false;

  @override
  Future<FetchWishlistImportPreviewResult> execute() async {
    executeCalled = true;
    return _result;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WishlistImportPreview makePreview({
  int newCount = 0,
  int duplicateCount = 0,
  int invalidCount = 0,
}) {
  final rows = <WishlistImportRow>[
    for (int i = 0; i < newCount; i++)
      NewWishlistRow(
        releaseId: 100 + i,
        title: 'New Album $i',
        artist: 'Artist',
      ),
    for (int i = 0; i < duplicateCount; i++)
      DuplicateWishlistRow(
        releaseId: 200 + i,
        title: 'Duplicate $i',
        artist: 'Artist',
      ),
    for (int i = 0; i < invalidCount; i++)
      InvalidWishlistRow(
        releaseId: 0,
        title: '',
        artist: 'Artist',
        reason: 'Missing title',
      ),
  ];
  return WishlistImportPreview(rows: rows);
}

Widget buildSubject(FetchWishlistImportPreviewUseCase useCase) =>
    MaterialApp(
      home: WishlistImportPreviewScreen(useCase: useCase),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WishlistImportPreviewScreen', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while loading',
          (tester) async {
        final useCase = _FakeUseCase(FetchWishlistPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows Import Wishlist from Discogs in AppBar', (tester) async {
        final useCase = _FakeUseCase(FetchWishlistPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
      });

      testWidgets('calls execute on initState', (tester) async {
        final useCase = _FakeUseCase(FetchWishlistPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        expect(useCase.executeCalled, isTrue);
      });
    });

    group('preview ready state', () {
      testWidgets('shows Wishlist preview heading after load', (tester) async {
        final useCase =
            _FakeUseCase(FetchWishlistPreviewReady(makePreview(newCount: 3)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Wishlist preview'), findsOneWidget);
      });

      testWidgets('shows total count', (tester) async {
        final useCase = _FakeUseCase(
          FetchWishlistPreviewReady(
            makePreview(newCount: 2, duplicateCount: 1, invalidCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Total found'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
      });

      testWidgets('shows new count', (tester) async {
        final useCase = _FakeUseCase(
          FetchWishlistPreviewReady(
            makePreview(newCount: 5, duplicateCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('New items'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('shows duplicate count', (tester) async {
        final useCase = _FakeUseCase(
          FetchWishlistPreviewReady(
            makePreview(duplicateCount: 3, newCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Already in wishlist'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows invalid count', (tester) async {
        final useCase = _FakeUseCase(
          FetchWishlistPreviewReady(
            makePreview(invalidCount: 2, newCount: 1),
          ),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Cannot import'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('shows zero for all counts on empty wantlist', (tester) async {
        final useCase =
            _FakeUseCase(FetchWishlistPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('0'), findsNWidgets(4));
      });
    });

    group('confirm button', () {
      testWidgets('shows Nothing to import when newCount is 0', (tester) async {
        final useCase =
            _FakeUseCase(FetchWishlistPreviewReady(makePreview()));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Nothing to import'), findsOneWidget);
      });

      testWidgets('shows Import N records for newCount > 1', (tester) async {
        final useCase =
            _FakeUseCase(FetchWishlistPreviewReady(makePreview(newCount: 7)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Import 7 records'), findsOneWidget);
      });

      testWidgets('shows Import 1 record for newCount == 1', (tester) async {
        final useCase =
            _FakeUseCase(FetchWishlistPreviewReady(makePreview(newCount: 1)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Import 1 record'), findsOneWidget);
      });

      testWidgets('confirm button is always disabled (import not yet wired)',
          (tester) async {
        final useCase =
            _FakeUseCase(FetchWishlistPreviewReady(makePreview(newCount: 3)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Import 3 records'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('confirm button is disabled even when nothing to import',
          (tester) async {
        final useCase =
            _FakeUseCase(FetchWishlistPreviewReady(makePreview()));
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
          FetchWishlistPreviewReady(makePreview(duplicateCount: 2)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Notes'), findsOneWidget);
        expect(
          find.textContaining('already in your wishlist'),
          findsOneWidget,
        );
      });

      testWidgets('shows warning when invalid items exist', (tester) async {
        final useCase = _FakeUseCase(
          FetchWishlistPreviewReady(makePreview(invalidCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Notes'), findsOneWidget);
        expect(find.textContaining('cannot be imported'), findsOneWidget);
      });

      testWidgets('no warning card when all items are new', (tester) async {
        final useCase = _FakeUseCase(
            FetchWishlistPreviewReady(makePreview(newCount: 5)));
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Notes'), findsNothing);
      });

      testWidgets('plural wording for multiple duplicates', (tester) async {
        final useCase = _FakeUseCase(
          FetchWishlistPreviewReady(makePreview(duplicateCount: 3)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('3 items are'), findsOneWidget);
      });

      testWidgets('singular wording for one duplicate', (tester) async {
        final useCase = _FakeUseCase(
          FetchWishlistPreviewReady(makePreview(duplicateCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('1 item is'), findsOneWidget);
      });
    });

    group('no token state', () {
      testWidgets('shows no token message', (tester) async {
        final useCase = _FakeUseCase(const FetchWishlistPreviewNoToken());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('No Discogs account connected'), findsOneWidget);
      });

      testWidgets('no token state has helpful instructions', (tester) async {
        final useCase = _FakeUseCase(const FetchWishlistPreviewNoToken());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(
          find.textContaining('Connect your Discogs account'),
          findsOneWidget,
        );
      });

      testWidgets('no token state does not show confirm button', (tester) async {
        final useCase = _FakeUseCase(const FetchWishlistPreviewNoToken());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.byType(FilledButton), findsNothing);
      });
    });

    group('rate limited state', () {
      testWidgets('shows rate limit message', (tester) async {
        final useCase = _FakeUseCase(const FetchWishlistPreviewRateLimited());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('rate-limiting'), findsOneWidget);
      });

      testWidgets('shows Try again button for rate limit', (tester) async {
        final useCase = _FakeUseCase(const FetchWishlistPreviewRateLimited());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('network error state', () {
      testWidgets('shows network error message', (tester) async {
        final useCase =
            _FakeUseCase(const FetchWishlistPreviewNetworkError());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('No internet connection'), findsOneWidget);
      });

      testWidgets('shows Try again button for network error', (tester) async {
        final useCase =
            _FakeUseCase(const FetchWishlistPreviewNetworkError());
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('generic error state', () {
      testWidgets('shows error message', (tester) async {
        final useCase = _FakeUseCase(
          const FetchWishlistPreviewError(InvalidTokenError()),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });

      testWidgets('shows Try again button for generic error', (tester) async {
        final useCase = _FakeUseCase(
          const FetchWishlistPreviewError(DiscogsUnavailableError()),
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
          firstResult: const FetchWishlistPreviewNetworkError(),
          secondResult:
              FetchWishlistPreviewReady(makePreview(newCount: 1)),
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
          FetchWishlistPreviewReady(
              makePreview(newCount: 2, duplicateCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Import Wishlist from Discogs'), findsOneWidget);
        expect(find.text('Wishlist preview'), findsOneWidget);
      });

      testWidgets('shows summary card on wide screen', (tester) async {
        tester.view.physicalSize = const Size(2800, 2000);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // duplicateCount=1 keeps totalCount(6) != newCount(5) so '5' appears once.
        final useCase = _FakeUseCase(
          FetchWishlistPreviewReady(
              makePreview(newCount: 5, duplicateCount: 1)),
        );
        await tester.pumpWidget(buildSubject(useCase));
        await tester.pump();
        expect(find.text('Wishlist preview'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });
    });

    group('security', () {
      testWidgets('no token state does not show any token value', (tester) async {
        final useCase = _FakeUseCase(const FetchWishlistPreviewNoToken());
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
          const FetchWishlistPreviewError(InvalidTokenError()),
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

class _CountingFakeUseCase extends FetchWishlistImportPreviewUseCase {
  _CountingFakeUseCase({
    required this.firstResult,
    required this.secondResult,
    required this.onCall,
  }) : super(
          previewBuilder: BuildWishlistImportPreviewUseCase(
            _FakeWishlistRepository(),
          ),
        );

  final FetchWishlistImportPreviewResult firstResult;
  final FetchWishlistImportPreviewResult secondResult;
  final VoidCallback onCall;
  int _calls = 0;

  @override
  Future<FetchWishlistImportPreviewResult> execute() async {
    onCall();
    _calls++;
    return _calls == 1 ? firstResult : secondResult;
  }
}

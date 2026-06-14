import 'dart:async';

import 'package:cratewise/application/services/search_query_cache.dart';
import 'package:cratewise/application/use_cases/barcode_lookup_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/domain/models/search_result_page.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/presentation/screens/barcode_scan_screen.dart';
import 'package:cratewise/presentation/widgets/release_search_result_card.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => null;
  @override
  Future<String?> loadUsername() async => null;
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async {}
}

class _FakeLookupUseCase extends BarcodeLookupUseCase {
  _FakeLookupUseCase(this._result)
    : super(storage: _FakeStorage(), apiClient: DiscogsApiClient());

  final BarcodeLookupResult _result;
  String? lastBarcode;

  @override
  Future<BarcodeLookupResult> execute(String barcode, {int page = 1}) async {
    lastBarcode = barcode;
    return _result;
  }
}

class _BlockingLookupUseCase extends BarcodeLookupUseCase {
  _BlockingLookupUseCase()
    : super(storage: _FakeStorage(), apiClient: DiscogsApiClient());

  final _completer = Completer<BarcodeLookupResult>();

  void complete(BarcodeLookupResult result) => _completer.complete(result);

  @override
  Future<BarcodeLookupResult> execute(String barcode, {int page = 1}) =>
      _completer.future;
}

class _SequencedBlockingLookupUseCase extends BarcodeLookupUseCase {
  _SequencedBlockingLookupUseCase(this._completers)
    : super(storage: _FakeStorage(), apiClient: DiscogsApiClient());

  final List<Completer<BarcodeLookupResult>> _completers;
  int _callIndex = 0;

  @override
  Future<BarcodeLookupResult> execute(String barcode, {int page = 1}) =>
      _completers[_callIndex++].future;
}

// Membership fakes (US-80)

class _FakeCollectionRepository implements CollectionRepository {
  _FakeCollectionRepository({this.ids = const {}, this.throwOnGetAll = false});

  final Set<int> ids;
  final bool throwOnGetAll;

  @override
  Future<List<CollectionItem>> getAll() async {
    if (throwOnGetAll) throw const StorageError();
    return ids
        .map(
          (id) => CollectionItem(
            id: 'c$id',
            discogsReleaseId: id,
            artist: 'Artist',
            title: 'Title',
            mediaCondition: RecordCondition.notSet,
            sleeveCondition: RecordCondition.notSet,
            tags: const [],
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        )
        .toList();
  }

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      ids.contains(discogsReleaseId);
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
  _FakeWishlistRepository({this.ids = const {}, this.throwOnGetAll = false});

  final Set<int> ids;
  final bool throwOnGetAll;

  @override
  Future<List<WishlistItem>> getAll() async {
    if (throwOnGetAll) throw const StorageError();
    return ids
        .map(
          (id) => WishlistItem(
            id: 'w$id',
            discogsReleaseId: id,
            artist: 'Artist',
            title: 'Title',
            priority: WishlistPriority.medium,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        )
        .toList();
  }

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      ids.contains(discogsReleaseId);
  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _kResult = ReleaseSearchResult(
  id: 249504,
  artist: 'Miles Davis',
  title: 'Kind Of Blue',
  format: 'Vinyl',
  label: 'Columbia',
  country: 'US',
  year: 1959,
);

final _kSinglePage = SearchResultPage(
  items: const [_kResult],
  currentPage: 1,
  totalPages: 1,
  totalResults: 1,
);

BarcodeLookupSuccess get _kSuccess => BarcodeLookupSuccess(_kSinglePage);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BarcodeScanScreen — layout', () {
    testWidgets('shows scan area placeholder', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('scan-area-placeholder')), findsOneWidget);
    });

    testWidgets('shows barcode input field', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('barcode-input')), findsOneWidget);
    });

    testWidgets('shows Scan barcode button', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('scan-barcode-button')), findsOneWidget);
    });

    testWidgets('shows Search barcode button', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('search-barcode-button')), findsOneWidget);
    });
  });

  group('BarcodeScanScreen — idle state', () {
    testWidgets('shows empty state title initially', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.text('Scan or enter a barcode'), findsOneWidget);
    });

    testWidgets('shows empty state description', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(
        find.text('Point your camera at a barcode or type one above.'),
        findsOneWidget,
      );
    });

    testWidgets('does not show result cards while idle', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byType(ReleaseSearchResultCard), findsNothing);
    });

    testWidgets('Scan barcode button tap does not change idle state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.tap(find.byKey(const Key('scan-barcode-button')));
      await tester.pump();
      expect(find.text('Scan or enter a barcode'), findsOneWidget);
    });
  });

  group('BarcodeScanScreen — loading state', () {
    testWidgets('shows loading indicator while use case is pending', (
      tester,
    ) async {
      final useCase = _BlockingLookupUseCase();
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      useCase.complete(const BarcodeLookupNoResults());
      await tester.pumpAndSettle();
    });
  });

  group('BarcodeScanScreen — search results', () {
    testWidgets('shows result cards on success', (tester) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
    });

    testWidgets('result card shows artist', (tester) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('result card shows title', (tester) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Kind Of Blue'), findsOneWidget);
    });

    testWidgets('result card shows Discogs release ID', (tester) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('#249504'), findsOneWidget);
    });

    testWidgets('calls use case with trimmed barcode', (tester) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '  5099706035422  ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(useCase.lastBarcode, '5099706035422');
    });

    testWidgets('whitespace-only barcode keeps idle state', (tester) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(find.byKey(const Key('barcode-input')), '   ');
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Scan or enter a barcode'), findsOneWidget);
      expect(useCase.lastBarcode, isNull);
    });

    testWidgets('submitting keyboard triggers search', (tester) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
    });
  });

  group('BarcodeScanScreen — no results state', () {
    testWidgets('shows no results message', (tester) async {
      final useCase = _FakeLookupUseCase(const BarcodeLookupNoResults());
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '0000000000000',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('No releases found'), findsOneWidget);
    });
  });

  group('BarcodeScanScreen — no token state', () {
    testWidgets('shows no token state', (tester) async {
      final useCase = _FakeLookupUseCase(const BarcodeLookupNoToken());
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Discogs account not connected'), findsOneWidget);
    });

    testWidgets('no token message mentions Settings', (tester) async {
      final useCase = _FakeLookupUseCase(const BarcodeLookupNoToken());
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(
        find.text('Go to Settings to connect your Discogs account.'),
        findsOneWidget,
      );
    });
  });

  group('BarcodeScanScreen — rate limited state', () {
    testWidgets('shows rate limited state', (tester) async {
      final useCase = _FakeLookupUseCase(const BarcodeLookupRateLimited());
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Too many requests'), findsOneWidget);
    });
  });

  group('BarcodeScanScreen — error state', () {
    testWidgets('shows error state on lookup error', (tester) async {
      final useCase = _FakeLookupUseCase(
        const BarcodeLookupError(NetworkError()),
      );
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });

  group('BarcodeScanScreen — viewfinder overlay', () {
    testWidgets('viewfinder overlay is absent in initial placeholder state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('viewfinder-overlay')), findsNothing);
    });

    testWidgets(
      'viewfinder overlay remains absent after scan button tap on non-scanner platform',
      (tester) async {
        // On macOS/Linux test environments, _supportsScanner is false so the
        // scan button leaves the scan area in placeholder state.
        await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
        await tester.tap(find.byKey(const Key('scan-barcode-button')));
        await tester.pump();
        expect(find.byKey(const Key('viewfinder-overlay')), findsNothing);
        expect(find.byKey(const Key('scan-area-placeholder')), findsOneWidget);
      },
    );
  });

  group('BarcodeScanScreen — barcode validation', () {
    testWidgets('search button is disabled when input is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('search-barcode-button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('search button is enabled for a valid 13-digit barcode', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('search-barcode-button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('search button is enabled for a valid 12-digit barcode', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '012345678905',
      );
      await tester.pump();
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('search-barcode-button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('search button is enabled for a valid 8-digit barcode', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '01234565',
      );
      await tester.pump();
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('search-barcode-button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('non-numeric input shows a friendly error message', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        'https://example.com',
      );
      await tester.pump();
      expect(
        find.textContaining("This doesn't look like a barcode"),
        findsOneWidget,
      );
    });

    testWidgets('search button is disabled for non-numeric input', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        'not-a-barcode',
      );
      await tester.pump();
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('search-barcode-button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('numeric input with wrong length shows a length error', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(find.byKey(const Key('barcode-input')), '12345');
      await tester.pump();
      expect(
        find.textContaining('Barcode must be 8, 12, or 13 digits'),
        findsOneWidget,
      );
    });

    testWidgets(
      'search button is disabled for numeric input with wrong length',
      (tester) async {
        await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
        await tester.enterText(find.byKey(const Key('barcode-input')), '12345');
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.byKey(const Key('search-barcode-button')),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'keyboard submit with invalid input does not trigger a search',
      (tester) async {
        final useCase = _FakeLookupUseCase(_kSuccess);
        await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
        await tester.enterText(
          find.byKey(const Key('barcode-input')),
          'abc123',
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        expect(useCase.lastBarcode, isNull);
        expect(find.byType(ReleaseSearchResultCard), findsNothing);
      },
    );

    testWidgets('validation error clears when a valid barcode is entered', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.enterText(find.byKey(const Key('barcode-input')), 'abc');
      await tester.pump();
      expect(
        find.textContaining("This doesn't look like a barcode"),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      expect(
        find.textContaining("This doesn't look like a barcode"),
        findsNothing,
      );
    });

    testWidgets('blank input shows no validation error', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.pump();
      expect(
        find.textContaining("This doesn't look like a barcode"),
        findsNothing,
      );
      expect(find.textContaining('Barcode must be'), findsNothing);
    });
  });

  group('BarcodeScanScreen — torch toggle', () {
    testWidgets('torch toggle button is absent in initial placeholder state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byKey(const Key('torch-toggle-button')), findsNothing);
    });

    testWidgets(
      'torch toggle button remains absent after scan button tap on non-scanner platform',
      (tester) async {
        // On macOS/Linux, _supportsScanner is false so _CameraScanArea is never
        // shown and the torch button cannot appear.
        await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
        await tester.tap(find.byKey(const Key('scan-barcode-button')));
        await tester.pump();
        expect(find.byKey(const Key('torch-toggle-button')), findsNothing);
        expect(find.byKey(const Key('scan-area-placeholder')), findsOneWidget);
      },
    );
  });

  group('BarcodeScanScreen — wide layout', () {
    testWidgets('uses split view (VerticalDivider) at wide viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('no split view (no VerticalDivider) at narrow viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('left scan panel width is proportional to viewport width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      final widthAt800 = tester
          .getSize(find.byKey(const Key('scan-area-placeholder')))
          .width;

      await tester.binding.setSurfaceSize(const Size(1000, 600));
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      final widthAt1000 = tester
          .getSize(find.byKey(const Key('scan-area-placeholder')))
          .width;

      // Proportional panel: wider viewport → wider left panel
      expect(widthAt1000, greaterThan(widthAt800));
    });

    testWidgets('scan area and results panel are both visible after a search', (
      tester,
    ) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.byKey(const Key('scan-area-placeholder')), findsOneWidget);
      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
    });
  });

  group('BarcodeScanScreen — in-flight cancellation', () {
    testWidgets('second search supersedes an in-flight first search', (
      tester,
    ) async {
      final c1 = Completer<BarcodeLookupResult>();
      final c2 = Completer<BarcodeLookupResult>();
      final useCase = _SequencedBlockingLookupUseCase([c1, c2]);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));

      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();

      // First search
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();

      // Second search before first completes
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();

      // Complete first (stale) request — result must be discarded.
      const staleResult = ReleaseSearchResult(
        id: 99999,
        artist: 'The Beatles',
        title: 'Abbey Road',
        format: 'LP',
        label: 'Apple Records',
        country: 'UK',
        year: 1969,
      );
      c1.complete(
        BarcodeLookupSuccess(
          SearchResultPage(
            items: const [staleResult],
            currentPage: 1,
            totalPages: 1,
            totalResults: 1,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Abbey Road'), findsNothing);

      // Complete second (current) request — result must be shown.
      c2.complete(_kSuccess);
      await tester.pumpAndSettle();
      expect(find.text('Kind Of Blue'), findsOneWidget);
    });
  });

  group('BarcodeScanScreen — search caching', () {
    testWidgets(
      'cache hit shows results immediately without a loading indicator',
      (tester) async {
        // Pre-populate cache.
        final barcodeCache = SearchQueryCache();
        barcodeCache.put(
          SearchQueryCache.normalizeKey('5099706035422'),
          _kSinglePage,
        );

        // Service blocks forever — it should not be awaited before results show.
        final useCase = _BlockingLookupUseCase();
        await tester.pumpWidget(
          _wrap(
            BarcodeScanScreen(useCase: useCase, barcodeCache: barcodeCache),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('barcode-input')),
          '5099706035422',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('search-barcode-button')));
        await tester.pump();
        await tester.pump();

        // Cached result visible immediately, no spinner.
        expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byKey(const Key('cached-results-banner')), findsOneWidget);

        // Complete background refresh — banner should disappear.
        useCase.complete(_kSuccess);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('cached-results-banner')), findsNothing);
        expect(find.text('Kind Of Blue'), findsOneWidget);
      },
    );

    testWidgets(
      'banner persists when background refresh returns a non-success result',
      (tester) async {
        final barcodeCache = SearchQueryCache();
        barcodeCache.put(
          SearchQueryCache.normalizeKey('5099706035422'),
          _kSinglePage,
        );

        // Simulate a network error response (BarcodeLookupError).
        final useCase = _FakeLookupUseCase(
          BarcodeLookupError(const NetworkError()),
        );
        await tester.pumpWidget(
          _wrap(
            BarcodeScanScreen(useCase: useCase, barcodeCache: barcodeCache),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('barcode-input')),
          '5099706035422',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('search-barcode-button')));
        await tester.pumpAndSettle();

        // Cached result and banner remain; no error state shown.
        expect(find.byKey(const Key('cached-results-banner')), findsOneWidget);
        expect(find.text('Kind Of Blue'), findsOneWidget);
        expect(find.text('Something went wrong'), findsNothing);
      },
    );
  });

  group('BarcodeScanScreen — membership icons (US-80)', () {
    Future<void> searchBarcode(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '5099706035422',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
    }

    testWidgets('shows the collection icon for a collected release', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BarcodeScanScreen(
            useCase: _FakeLookupUseCase(_kSuccess),
            collectionRepository: _FakeCollectionRepository(ids: {_kResult.id}),
            wishlistRepository: _FakeWishlistRepository(),
          ),
        ),
      );
      await searchBarcode(tester);

      expect(find.byKey(const Key('in-collection-icon')), findsOneWidget);
      expect(find.byKey(const Key('on-wishlist-icon')), findsNothing);
    });

    testWidgets('shows both icons for a collected and wishlisted release', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BarcodeScanScreen(
            useCase: _FakeLookupUseCase(_kSuccess),
            collectionRepository: _FakeCollectionRepository(ids: {_kResult.id}),
            wishlistRepository: _FakeWishlistRepository(ids: {_kResult.id}),
          ),
        ),
      );
      await searchBarcode(tester);

      expect(find.byKey(const Key('in-collection-icon')), findsOneWidget);
      expect(find.byKey(const Key('on-wishlist-icon')), findsOneWidget);
    });

    testWidgets('shows no icons for an unknown release', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BarcodeScanScreen(
            useCase: _FakeLookupUseCase(_kSuccess),
            collectionRepository: _FakeCollectionRepository(),
            wishlistRepository: _FakeWishlistRepository(),
          ),
        ),
      );
      await searchBarcode(tester);

      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
      expect(find.byKey(const Key('in-collection-icon')), findsNothing);
      expect(find.byKey(const Key('on-wishlist-icon')), findsNothing);
    });

    testWidgets('degrades to no icons when membership storage fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BarcodeScanScreen(
            useCase: _FakeLookupUseCase(_kSuccess),
            collectionRepository: _FakeCollectionRepository(
              throwOnGetAll: true,
            ),
            wishlistRepository: _FakeWishlistRepository(throwOnGetAll: true),
          ),
        ),
      );
      await searchBarcode(tester);

      expect(find.byType(ReleaseSearchResultCard), findsOneWidget);
      expect(find.byKey(const Key('in-collection-icon')), findsNothing);
      expect(find.byKey(const Key('on-wishlist-icon')), findsNothing);
    });
  });
}

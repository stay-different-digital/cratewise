import 'dart:async';

import 'package:cratewise/application/use_cases/barcode_lookup_use_case.dart';
import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/domain/models/search_result_page.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
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
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(useCase.lastBarcode, '5099706035422');
    });

    testWidgets('whitespace-only barcode keeps idle state', (tester) async {
      final useCase = _FakeLookupUseCase(_kSuccess);
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(find.byKey(const Key('barcode-input')), '   ');
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
        '1234567890',
      );
      await tester.tap(find.byKey(const Key('search-barcode-button')));
      await tester.pump();
      expect(find.text('Discogs account not connected'), findsOneWidget);
    });

    testWidgets('no token message mentions Settings', (tester) async {
      final useCase = _FakeLookupUseCase(const BarcodeLookupNoToken());
      await tester.pumpWidget(_wrap(BarcodeScanScreen(useCase: useCase)));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '1234567890',
      );
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
        '1234567890',
      );
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
        '1234567890',
      );
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
}

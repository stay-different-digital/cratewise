import 'dart:async';

import 'package:cratewise/application/services/discogs_release_detail_service.dart';
import 'package:cratewise/application/use_cases/add_to_collection_use_case.dart';
import 'package:cratewise/application/use_cases/add_to_wishlist_use_case.dart';
import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/release_detail.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/cached_release_metadata_repository.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/presentation/screens/release_detail_screen.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => 'fake_token';
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

class _LoadedService extends DiscogsReleaseDetailService {
  _LoadedService({required this.detail})
      : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());
  final ReleaseDetail detail;

  @override
  Future<ReleaseDetail> fetchDetail(int _) async => detail;
}

class _ErrorService extends DiscogsReleaseDetailService {
  _ErrorService({required this.error})
      : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());
  final AppError error;

  @override
  Future<ReleaseDetail> fetchDetail(int _) async => throw error;
}

class _BlockingService extends DiscogsReleaseDetailService {
  _BlockingService()
      : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  @override
  Future<ReleaseDetail> fetchDetail(int _) => Completer<ReleaseDetail>().future;
}

class _FakeCacheRepository implements CachedReleaseMetadataRepository {
  _FakeCacheRepository({this.cachedMetadata});
  final CachedReleaseMetadata? cachedMetadata;

  @override
  Future<CachedReleaseMetadata?> getByReleaseId(int id) async => cachedMetadata;

  @override
  Future<void> save(CachedReleaseMetadata metadata) async {}

  @override
  Future<void> remove(int id) async {}
}

// Fails on the first call, returns detail on subsequent calls.
class _FailThenSucceedService extends DiscogsReleaseDetailService {
  _FailThenSucceedService({required this.detail})
      : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final ReleaseDetail detail;
  int _calls = 0;

  @override
  Future<ReleaseDetail> fetchDetail(int _) async {
    _calls++;
    if (_calls == 1) throw const NetworkError();
    return detail;
  }
}

// ---------------------------------------------------------------------------
// Fixture
// ---------------------------------------------------------------------------

const _kindOfBlue = ReleaseDetail(
  id: 249504,
  title: 'Kind Of Blue',
  artist: 'Miles Davis',
  label: 'Columbia',
  catno: 'CL 1355',
  format: 'Vinyl, LP, Album',
  country: 'US',
  year: 1959,
  genres: ['Jazz'],
  styles: ['Modal', 'Bop'],
  tracklist: [
    ReleaseTrack(position: 'A1', title: 'So What', duration: '9:22'),
    ReleaseTrack(position: 'A2', title: 'Freddie Freeloader', duration: '9:46'),
  ],
  notes: 'A seminal jazz album.',
  coverUrl: 'https://i.discogs.com/cover.jpg',
  identifiers: [
    ReleaseIdentifier(type: 'Barcode', value: '074643602222'),
  ],
);

class _FakeCollectionRepository implements CollectionRepository {
  const _FakeCollectionRepository({this.alreadyContains = false});

  final bool alreadyContains;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => alreadyContains;

  @override
  Future<void> add(CollectionItem item) async {}

  @override
  Future<List<CollectionItem>> getAll() async => [];

  @override
  Future<CollectionItem?> getById(String id) async => null;

  @override
  Future<void> update(CollectionItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

AddToCollectionUseCase _newUseCase({bool alreadyContains = false}) =>
    AddToCollectionUseCase(_FakeCollectionRepository(
      alreadyContains: alreadyContains,
    ));

class _FakeWishlistRepository implements WishlistRepository {
  const _FakeWishlistRepository({this.alreadyContains = false});

  final bool alreadyContains;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => alreadyContains;

  @override
  Future<void> add(WishlistItem item) async {}

  @override
  Future<List<WishlistItem>> getAll() async => [];

  @override
  Future<WishlistItem?> getById(String id) async => null;

  @override
  Future<void> update(WishlistItem item) async {}

  @override
  Future<void> remove(String id) async {}
}

AddToWishlistUseCase _newWishlistUseCase({bool alreadyContains = false}) =>
    AddToWishlistUseCase(_FakeWishlistRepository(
      alreadyContains: alreadyContains,
    ));

final _cachedKindOfBlue = CachedReleaseMetadata(
  discogsReleaseId: 249504,
  artist: 'Miles Davis',
  title: 'Kind Of Blue',
  label: 'Columbia',
  catno: 'CL 1355',
  format: 'Vinyl',
  country: 'US',
  year: 1959,
  genres: const ['Jazz'],
  styles: const ['Modal', 'Bop'],
  tracklist: const ['So What', 'Freddie Freeloader'],
  barcodes: const ['074643602222'],
  coverUrl: null,
  notes: 'A seminal jazz album.',
  fetchedAt: DateTime(2026, 1, 15),
  cacheSource: 'discogs_api',
  syncStatus: SyncStatus.localOnly,
);

class _FakeThumbnailRepository implements ThumbnailRepository {
  int getLocalPathCallCount = 0;

  @override
  Future<String?> getLocalPath(int releaseId) async {
    getLocalPathCallCount++;
    return null;
  }

  @override
  Future<void> save(int releaseId, List<int> bytes) async {}

  @override
  Future<void> remove(int releaseId) async {}

  @override
  Future<bool> exists(int releaseId) async => false;
}

Widget _wrap(Widget child) => MaterialApp(home: child);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReleaseDetailScreen', () {
    group('loading state', () {
      testWidgets('shows loading skeleton while fetching', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _BlockingService(),
          ),
        ));
        expect(find.byKey(const Key('release-detail-loading')), findsOneWidget);
      });

      testWidgets('shows app bar title while loading', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _BlockingService(),
          ),
        ));
        expect(find.text('Release Detail'), findsOneWidget);
      });
    });

    group('loaded state', () {
      testWidgets('shows release title when loaded', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        // Title appears in both the app bar and the detail body.
        expect(find.text('Kind Of Blue'), findsWidgets);
      });

      testWidgets('shows artist when loaded', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Miles Davis'), findsOneWidget);
      });

      testWidgets('shows label and catalog number when loaded', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('Columbia'), findsOneWidget);
        expect(find.textContaining('CL 1355'), findsOneWidget);
      });

      testWidgets('shows tracklist track titles when loaded', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('So What'), findsOneWidget);
        expect(find.text('Freddie Freeloader'), findsOneWidget);
      });

      testWidgets('shows notes when available', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('seminal jazz'), findsOneWidget);
      });

      testWidgets('shows identifiers when available', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Barcode'), findsOneWidget);
        expect(find.text('074643602222'), findsOneWidget);
      });

      testWidgets('shows cover image widget when coverUrl is present',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('release-cover-image')), findsOneWidget);
      });

      testWidgets('hides cover image widget when coverUrl is null',
          (tester) async {
        const noCover = ReleaseDetail(
          id: 1,
          title: 'Untitled',
          artist: 'Unknown',
          label: '',
          catno: '',
          format: '',
          country: '',
          genres: [],
          styles: [],
          tracklist: [],
          identifiers: [],
        );
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _LoadedService(detail: noCover),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('release-cover-image')), findsNothing);
      });

      testWidgets('shows Discogs release ID', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('249504'), findsOneWidget);
      });

      testWidgets('hides notes section when notes is null', (tester) async {
        const noNotes = ReleaseDetail(
          id: 1,
          title: 'Untitled',
          artist: '',
          label: '',
          catno: '',
          format: '',
          country: '',
          genres: [],
          styles: [],
          tracklist: [],
          identifiers: [],
        );
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _LoadedService(detail: noNotes),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Notes'), findsNothing);
      });
    });

    group('error state', () {
      testWidgets('shows no-token error message', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const NoTokenError()),
            cacheRepository: _FakeCacheRepository(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('Connect a Discogs token'), findsOneWidget);
      });

      testWidgets('shows network error message', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const NetworkError()),
            cacheRepository: _FakeCacheRepository(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('No internet'), findsOneWidget);
      });

      testWidgets('shows rate limit error message', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const RateLimitedError()),
            cacheRepository: _FakeCacheRepository(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('Too many requests'), findsOneWidget);
      });
    });

    group('retry', () {
      testWidgets('shows retry button for network error', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const NetworkError()),
            cacheRepository: _FakeCacheRepository(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
      });

      testWidgets('does not show retry button for no-token error',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const NoTokenError()),
            cacheRepository: _FakeCacheRepository(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
      });

      testWidgets('retry button refetches and shows loaded state on success',
          (tester) async {
        final service = _FailThenSucceedService(detail: _kindOfBlue);
        await tester.pumpWidget(_wrap(ReleaseDetailScreen(
          releaseId: 1,
          detailService: service,
          cacheRepository: _FakeCacheRepository(),
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('No internet'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
        await tester.pumpAndSettle();

        expect(find.text('Kind Of Blue'), findsWidgets);
      });
    });

    group('navigation', () {
      testWidgets('shows back button when pushed onto the stack', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReleaseDetailScreen(
                      releaseId: 249504,
                      detailService: _BlockingService(),
                    ),
                  ),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('Go'));
        // _BlockingService never resolves; use pump(duration) to advance past
        // the navigation animation without waiting for the fetch to complete.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(BackButton), findsOneWidget);
      });

      testWidgets('back button returns to previous screen', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReleaseDetailScreen(
                      releaseId: 249504,
                      detailService: _LoadedService(detail: _kindOfBlue),
                    ),
                  ),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();
        expect(find.byType(ReleaseDetailScreen), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(ReleaseDetailScreen), findsNothing);
        expect(find.text('Go'), findsOneWidget);
      });
    });

    group('add to collection', () {
      testWidgets('shows Add to Collection button when release is loaded',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Add to Collection'), findsOneWidget);
      });

      testWidgets('does not show Add to Collection button while loading',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _BlockingService(),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        expect(find.text('Add to Collection'), findsNothing);
      });

      testWidgets('does not show Add to Collection button in error state',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Add to Collection'), findsNothing);
      });

      testWidgets('tapping button shows added snackbar', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add to Collection'));
        await tester.pumpAndSettle();

        expect(find.text('Added to your collection'), findsOneWidget);
      });

      testWidgets('tapping button when already in collection shows duplicate snackbar',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(alreadyContains: true),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add to Collection'));
        await tester.pumpAndSettle();

        expect(find.text('Already in your collection'), findsOneWidget);
      });

      testWidgets('button changes to In Collection after successful add',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add to Collection'));
        await tester.pumpAndSettle();

        expect(find.text('In Collection'), findsOneWidget);
        expect(find.text('Add to Collection'), findsNothing);
      });

      testWidgets('button changes to In Collection when release is duplicate',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(alreadyContains: true),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add to Collection'));
        await tester.pumpAndSettle();

        expect(find.text('In Collection'), findsOneWidget);
      });

      testWidgets('In Collection button is disabled after add', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add to Collection'));
        await tester.pumpAndSettle();

        final button = tester.widget<FilledButton>(
          find.byKey(const Key('add-to-collection-button')),
        );
        expect(button.onPressed, isNull);
      });
    });

    group('add to wishlist', () {
      testWidgets('shows Add to Wishlist button when release is loaded',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Add to Wishlist'), findsOneWidget);
      });

      testWidgets('does not show Add to Wishlist button while loading',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _BlockingService(),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        expect(find.text('Add to Wishlist'), findsNothing);
      });

      testWidgets('does not show Add to Wishlist button in error state',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Add to Wishlist'), findsNothing);
      });

      testWidgets('tapping button shows added snackbar', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
        await tester.pumpAndSettle();

        expect(find.text('Added to your wishlist'), findsOneWidget);
      });

      testWidgets(
          'tapping button when already in wishlist shows duplicate snackbar',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(alreadyContains: true),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
        await tester.pumpAndSettle();

        expect(find.text('Already in your wishlist'), findsOneWidget);
      });

      testWidgets('button changes to In Wishlist after successful add',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
        await tester.pumpAndSettle();

        expect(find.text('In Wishlist'), findsOneWidget);
        expect(find.text('Add to Wishlist'), findsNothing);
      });

      testWidgets('button changes to In Wishlist when release is duplicate',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(alreadyContains: true),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
        await tester.pumpAndSettle();

        expect(find.text('In Wishlist'), findsOneWidget);
      });

      testWidgets('In Wishlist button is disabled after add', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
        await tester.pumpAndSettle();

        final button = tester.widget<OutlinedButton>(
          find.byKey(const Key('add-to-wishlist-button')),
        );
        expect(button.onPressed, isNull);
      });
    });

    group('offline cache fallback', () {
      testWidgets('shows cached banner when API fails and cache has data',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('Showing saved data'), findsOneWidget);
      });

      testWidgets('cached banner shows last updated date', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('15 Jan 2026'), findsOneWidget);
      });

      testWidgets('shows title from cache when API fails', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Kind Of Blue'), findsWidgets);
      });

      testWidgets('shows artist from cache when API fails', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Miles Davis'), findsOneWidget);
      });

      testWidgets('app bar shows title from cache when API fails',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        // Title appears in app bar
        expect(find.text('Kind Of Blue'), findsWidgets);
      });

      testWidgets('shows error state when API fails and cache is empty',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: null),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('No internet'), findsOneWidget);
        expect(find.textContaining('Showing saved data'), findsNothing);
      });

      testWidgets('shows cached data for NoTokenError when cache is available',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NoTokenError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('Showing saved data'), findsOneWidget);
        expect(find.text('Kind Of Blue'), findsWidgets);
      });

      testWidgets('shows Add to Collection button when showing cached data',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Add to Collection'), findsOneWidget);
      });

      testWidgets('shows Add to Wishlist button when showing cached data',
          (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Add to Wishlist'), findsOneWidget);
      });

      testWidgets('cached banner does not contain token text', (tester) async {
        await tester.pumpWidget(_wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('token'), findsNothing);
        expect(find.textContaining('secret'), findsNothing);
      });
    });
  });

  group('ReleaseDetailScreen — offline wording', () {
    testWidgets('network error message mentions offline viewing hint',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ReleaseDetailScreen(
          releaseId: 249504,
          detailService: _ErrorService(error: const NetworkError()),
          addToCollectionUseCase: _newUseCase(),
          addToWishlistUseCase: _newWishlistUseCase(),
          cacheRepository: _FakeCacheRepository(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('offline viewing'), findsOneWidget);
    });

    testWidgets('network error message does not contain token or secret',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ReleaseDetailScreen(
          releaseId: 249504,
          detailService: _ErrorService(error: const NetworkError()),
          addToCollectionUseCase: _newUseCase(),
          addToWishlistUseCase: _newWishlistUseCase(),
          cacheRepository: _FakeCacheRepository(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('token'), findsNothing);
      expect(find.textContaining('secret'), findsNothing);
    });
  });

  group('ReleaseDetailScreen — cached thumbnail in offline fallback', () {
    testWidgets('calls thumbnailRepository.getLocalPath when showing cached view',
        (tester) async {
      final thumbRepo = _FakeThumbnailRepository();
      await tester.pumpWidget(_wrap(
        ReleaseDetailScreen(
          releaseId: 249504,
          detailService: _ErrorService(error: const NetworkError()),
          addToCollectionUseCase: _newUseCase(),
          addToWishlistUseCase: _newWishlistUseCase(),
          cacheRepository:
              _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          thumbnailRepository: thumbRepo,
        ),
      ));
      await tester.pumpAndSettle();
      expect(thumbRepo.getLocalPathCallCount, greaterThan(0));
    });

    testWidgets('does not call thumbnailRepository when showing live data',
        (tester) async {
      final thumbRepo = _FakeThumbnailRepository();
      await tester.pumpWidget(_wrap(
        ReleaseDetailScreen(
          releaseId: 249504,
          detailService: _LoadedService(detail: _kindOfBlue),
          addToCollectionUseCase: _newUseCase(),
          addToWishlistUseCase: _newWishlistUseCase(),
          thumbnailRepository: thumbRepo,
        ),
      ));
      await tester.pumpAndSettle();
      expect(thumbRepo.getLocalPathCallCount, 0);
    });

    testWidgets(
        'cached view renders without crash when thumbnailRepository returns null path',
        (tester) async {
      final thumbRepo = _FakeThumbnailRepository();
      await tester.pumpWidget(_wrap(
        ReleaseDetailScreen(
          releaseId: 249504,
          detailService: _ErrorService(error: const NetworkError()),
          addToCollectionUseCase: _newUseCase(),
          addToWishlistUseCase: _newWishlistUseCase(),
          cacheRepository:
              _FakeCacheRepository(cachedMetadata: _cachedKindOfBlue),
          thumbnailRepository: thumbRepo,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Showing saved data'), findsOneWidget);
    });
  });
}

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

class _CountingService extends DiscogsReleaseDetailService {
  _CountingService({required this.detail})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final ReleaseDetail detail;
  int callCount = 0;

  @override
  Future<ReleaseDetail> fetchDetail(int _) async {
    callCount++;
    return detail;
  }
}

class _UpdatingService extends DiscogsReleaseDetailService {
  _UpdatingService({required this.first, required this.second})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final ReleaseDetail first;
  final ReleaseDetail second;
  int _calls = 0;

  @override
  Future<ReleaseDetail> fetchDetail(int _) async {
    _calls++;
    return _calls == 1 ? first : second;
  }
}

class _SuccessThenErrorService extends DiscogsReleaseDetailService {
  _SuccessThenErrorService({required this.detail, required this.error})
    : super(storage: _FakeTokenStorage(), apiClient: DiscogsApiClient());

  final ReleaseDetail detail;
  final AppError error;
  int _calls = 0;

  @override
  Future<ReleaseDetail> fetchDetail(int _) async {
    _calls++;
    if (_calls == 1) return detail;
    throw error;
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
  identifiers: [ReleaseIdentifier(type: 'Barcode', value: '074643602222')],
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

class _TrackingCollectionRepository extends _FakeCollectionRepository {
  _TrackingCollectionRepository({super.alreadyContains = false});

  final List<CollectionItem> updates = [];

  @override
  Future<void> update(CollectionItem item) async => updates.add(item);
}

AddToCollectionUseCase _newUseCase({bool alreadyContains = false}) =>
    AddToCollectionUseCase(
      _FakeCollectionRepository(alreadyContains: alreadyContains),
    );

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
    AddToWishlistUseCase(
      _FakeWishlistRepository(alreadyContains: alreadyContains),
    );

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
  tracklist: const [
    ReleaseTrack(position: 'A1', title: 'So What', duration: '9:22'),
    ReleaseTrack(position: 'A2', title: 'Freddie Freeloader', duration: '9:46'),
  ],
  identifiers: const [
    ReleaseIdentifier(type: 'Barcode', value: '074643602222'),
    ReleaseIdentifier(type: 'Matrix / Runout', value: 'CL 1355-A'),
  ],
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
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _BlockingService(),
            ),
          ),
        );
        expect(find.byKey(const Key('release-detail-loading')), findsOneWidget);
      });

      testWidgets('shows app bar title while loading', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _BlockingService(),
            ),
          ),
        );
        expect(find.text('Release Detail'), findsOneWidget);
      });
    });

    group('loaded state', () {
      testWidgets('shows release title when loaded', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Title appears in both the app bar and the detail body.
        expect(find.text('Kind Of Blue'), findsWidgets);
      });

      testWidgets('shows artist when loaded', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Miles Davis'), findsOneWidget);
      });

      testWidgets('shows label and catalog number when loaded', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Columbia'), findsOneWidget);
        expect(find.textContaining('CL 1355'), findsOneWidget);
      });

      testWidgets('shows tracklist track titles when loaded', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('So What'), findsOneWidget);
        expect(find.text('Freddie Freeloader'), findsOneWidget);
      });

      testWidgets('shows notes when available', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('seminal jazz'), findsOneWidget);
      });

      testWidgets('shows identifiers when available', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Barcode'), findsOneWidget);
        expect(find.text('074643602222'), findsOneWidget);
      });

      testWidgets('shows cover image widget when coverUrl is present', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('release-cover-image')), findsOneWidget);
      });

      testWidgets('hides cover image widget when coverUrl is null', (
        tester,
      ) async {
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
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _LoadedService(detail: noCover),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('release-cover-image')), findsNothing);
      });

      testWidgets('shows Discogs release ID', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
            ),
          ),
        );
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
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _LoadedService(detail: noNotes),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Notes'), findsNothing);
      });
    });

    group('error state', () {
      testWidgets('shows no-token error message', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _ErrorService(error: const NoTokenError()),
              cacheRepository: _FakeCacheRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Connect a Discogs token'), findsOneWidget);
      });

      testWidgets('shows network error message', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _ErrorService(error: const NetworkError()),
              cacheRepository: _FakeCacheRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('No internet'), findsOneWidget);
      });

      testWidgets('shows rate limit error message', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _ErrorService(error: const RateLimitedError()),
              cacheRepository: _FakeCacheRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Too many requests'), findsOneWidget);
      });
    });

    group('retry', () {
      testWidgets('shows retry button for network error', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _ErrorService(error: const NetworkError()),
              cacheRepository: _FakeCacheRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
      });

      testWidgets('does not show retry button for no-token error', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _ErrorService(error: const NoTokenError()),
              cacheRepository: _FakeCacheRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
      });

      testWidgets('retry button refetches and shows loaded state on success', (
        tester,
      ) async {
        final service = _FailThenSucceedService(detail: _kindOfBlue);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: service,
              cacheRepository: _FakeCacheRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('No internet'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
        await tester.pumpAndSettle();

        expect(find.text('Kind Of Blue'), findsWidgets);
      });
    });

    group('navigation', () {
      testWidgets('shows back button when pushed onto the stack', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
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
          ),
        );
        await tester.tap(find.text('Go'));
        // _BlockingService never resolves; use pump(duration) to advance past
        // the navigation animation without waiting for the fetch to complete.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(BackButton), findsOneWidget);
      });

      testWidgets('back button returns to previous screen', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
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
          ),
        );
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
      testWidgets('shows Add to Collection button when release is loaded', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add to Collection'), findsOneWidget);
      });

      testWidgets('does not show Add to Collection button while loading', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _BlockingService(),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        expect(find.text('Add to Collection'), findsNothing);
      });

      testWidgets('does not show Add to Collection button in error state', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add to Collection'), findsNothing);
      });

      testWidgets(
        'tapping button shows added snackbar after dismissing prompt',
        (tester) async {
          final repo = _TrackingCollectionRepository();
          await tester.pumpWidget(
            _wrap(
              ReleaseDetailScreen(
                releaseId: 249504,
                detailService: _LoadedService(detail: _kindOfBlue),
                addToCollectionUseCase: AddToCollectionUseCase(repo),
                addToWishlistUseCase: _newWishlistUseCase(),
                collectionRepository: repo,
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Add to Collection'));
          await tester.pumpAndSettle();
          // Condition prompt is open; dismiss it.
          await tester.tap(find.byKey(const Key('condition-skip-button')));
          await tester.pumpAndSettle();

          expect(find.text('Added to your collection'), findsOneWidget);
        },
      );

      testWidgets(
        'tapping button when already in collection shows duplicate snackbar',
        (tester) async {
          await tester.pumpWidget(
            _wrap(
              ReleaseDetailScreen(
                releaseId: 249504,
                detailService: _LoadedService(detail: _kindOfBlue),
                addToCollectionUseCase: _newUseCase(alreadyContains: true),
                addToWishlistUseCase: _newWishlistUseCase(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Add to Collection'));
          await tester.pumpAndSettle();

          expect(find.text('Already in your collection'), findsOneWidget);
        },
      );

      testWidgets('button changes to In Collection after successful add', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add to Collection'));
        await tester.pumpAndSettle();

        expect(find.text('In Collection'), findsOneWidget);
        expect(find.text('Add to Collection'), findsNothing);
      });

      testWidgets('button changes to In Collection when release is duplicate', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(alreadyContains: true),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add to Collection'));
        await tester.pumpAndSettle();

        expect(find.text('In Collection'), findsOneWidget);
      });

      testWidgets('In Collection button is disabled after add', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
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
      testWidgets('shows Add to Wishlist button when release is loaded', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add to Wishlist'), findsOneWidget);
      });

      testWidgets('does not show Add to Wishlist button while loading', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _BlockingService(),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        expect(find.text('Add to Wishlist'), findsNothing);
      });

      testWidgets('does not show Add to Wishlist button in error state', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add to Wishlist'), findsNothing);
      });

      testWidgets('tapping button shows added snackbar', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
        await tester.pumpAndSettle();

        expect(find.text('Added to your wishlist'), findsOneWidget);
      });

      testWidgets(
        'tapping button when already in wishlist shows duplicate snackbar',
        (tester) async {
          await tester.pumpWidget(
            _wrap(
              ReleaseDetailScreen(
                releaseId: 249504,
                detailService: _LoadedService(detail: _kindOfBlue),
                addToCollectionUseCase: _newUseCase(),
                addToWishlistUseCase: _newWishlistUseCase(
                  alreadyContains: true,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
          await tester.pumpAndSettle();

          expect(find.text('Already in your wishlist'), findsOneWidget);
        },
      );

      testWidgets('button changes to In Wishlist after successful add', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
        await tester.pumpAndSettle();

        expect(find.text('In Wishlist'), findsOneWidget);
        expect(find.text('Add to Wishlist'), findsNothing);
      });

      testWidgets('button changes to In Wishlist when release is duplicate', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(alreadyContains: true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add-to-wishlist-button')));
        await tester.pumpAndSettle();

        expect(find.text('In Wishlist'), findsOneWidget);
      });

      testWidgets('In Wishlist button is disabled after add', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
            ),
          ),
        );
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
      testWidgets('shows cached banner when API fails and cache has data', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Showing saved data'), findsOneWidget);
      });

      testWidgets('cached banner shows last updated date', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('15 Jan 2026'), findsOneWidget);
      });

      testWidgets('shows title from cache when API fails', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Kind Of Blue'), findsWidgets);
      });

      testWidgets('shows artist from cache when API fails', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Miles Davis'), findsOneWidget);
      });

      testWidgets('app bar shows title from cache when API fails', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Title appears in app bar
        expect(find.text('Kind Of Blue'), findsWidgets);
      });

      testWidgets('shows error state when API fails and cache is empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 1,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(cachedMetadata: null),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('No internet'), findsOneWidget);
        expect(find.textContaining('Showing saved data'), findsNothing);
      });

      testWidgets(
        'shows cached data for NoTokenError when cache is available',
        (tester) async {
          await tester.pumpWidget(
            _wrap(
              ReleaseDetailScreen(
                releaseId: 249504,
                detailService: _ErrorService(error: const NoTokenError()),
                addToCollectionUseCase: _newUseCase(),
                addToWishlistUseCase: _newWishlistUseCase(),
                cacheRepository: _FakeCacheRepository(
                  cachedMetadata: _cachedKindOfBlue,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.textContaining('Showing saved data'), findsOneWidget);
          expect(find.text('Kind Of Blue'), findsWidgets);
        },
      );

      testWidgets('shows Add to Collection button when showing cached data', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add to Collection'), findsOneWidget);
      });

      testWidgets('shows Add to Wishlist button when showing cached data', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add to Wishlist'), findsOneWidget);
      });

      testWidgets('cached banner does not contain token text', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('token'), findsNothing);
        expect(find.textContaining('secret'), findsNothing);
      });

      testWidgets('shows full tracklist titles from cache when API fails', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('So What'), findsOneWidget);
        expect(find.text('Freddie Freeloader'), findsOneWidget);
      });

      testWidgets('shows track positions from cache when API fails', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('A1'), findsOneWidget);
        expect(find.text('A2'), findsOneWidget);
      });

      testWidgets('shows track durations from cache when API fails', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('9:22'), findsOneWidget);
        expect(find.text('9:46'), findsOneWidget);
      });

      testWidgets('shows all identifiers from cache when API fails', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Barcode'), findsOneWidget);
        expect(find.text('074643602222'), findsOneWidget);
        expect(find.text('Matrix / Runout'), findsOneWidget);
        expect(find.text('CL 1355-A'), findsOneWidget);
      });

      testWidgets('shows notes from cache when API fails', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('seminal jazz'), findsOneWidget);
      });

      testWidgets(
        'cached view omits tracklist section when cache has no tracks',
        (tester) async {
          final noTracks = _cachedKindOfBlue.copyWith(tracklist: []);
          await tester.pumpWidget(
            _wrap(
              ReleaseDetailScreen(
                releaseId: 249504,
                detailService: _ErrorService(error: const NetworkError()),
                addToCollectionUseCase: _newUseCase(),
                addToWishlistUseCase: _newWishlistUseCase(),
                cacheRepository: _FakeCacheRepository(cachedMetadata: noTracks),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Tracklist'), findsNothing);
        },
      );

      testWidgets(
        'cached view omits identifiers section when cache has no identifiers',
        (tester) async {
          final noIds = _cachedKindOfBlue.copyWith(identifiers: []);
          await tester.pumpWidget(
            _wrap(
              ReleaseDetailScreen(
                releaseId: 249504,
                detailService: _ErrorService(error: const NetworkError()),
                addToCollectionUseCase: _newUseCase(),
                addToWishlistUseCase: _newWishlistUseCase(),
                cacheRepository: _FakeCacheRepository(cachedMetadata: noIds),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Identifiers'), findsNothing);
        },
      );
    });
  });

  group('ReleaseDetailScreen — offline wording', () {
    testWidgets('network error message mentions offline viewing hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('offline viewing'), findsOneWidget);
    });

    testWidgets('network error message does not contain token or secret', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('token'), findsNothing);
      expect(find.textContaining('secret'), findsNothing);
    });
  });

  group('ReleaseDetailScreen — cached thumbnail in offline fallback', () {
    testWidgets(
      'calls thumbnailRepository.getLocalPath when showing cached view',
      (tester) async {
        final thumbRepo = _FakeThumbnailRepository();
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
              thumbnailRepository: thumbRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(thumbRepo.getLocalPathCallCount, greaterThan(0));
      },
    );

    testWidgets('does not call thumbnailRepository when showing live data', (
      tester,
    ) async {
      final thumbRepo = _FakeThumbnailRepository();
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            thumbnailRepository: thumbRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(thumbRepo.getLocalPathCallCount, 0);
    });

    testWidgets(
      'cached view renders without crash when thumbnailRepository returns null path',
      (tester) async {
        final thumbRepo = _FakeThumbnailRepository();
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: _newWishlistUseCase(),
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
              thumbnailRepository: thumbRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Showing saved data'), findsOneWidget);
      },
    );
  });

  group('ReleaseDetailScreen — search context', () {
    testWidgets('app bar shows artist and title from context while loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _BlockingService(),
            initialArtist: 'Miles Davis',
            initialTitle: 'Kind Of Blue',
          ),
        ),
      );
      // Single pump keeps the screen in _Loading state.
      await tester.pump();
      expect(find.text('Miles Davis — Kind Of Blue'), findsOneWidget);
    });

    testWidgets(
      'skeleton body shows title and artist from context while loading',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _BlockingService(),
              initialArtist: 'Miles Davis',
              initialTitle: 'Kind Of Blue',
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('release-detail-loading')), findsOneWidget);
        expect(find.text('Kind Of Blue'), findsOneWidget);
        expect(find.text('Miles Davis'), findsOneWidget);
      },
    );

    testWidgets('app bar shows only title when initialArtist is absent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _BlockingService(),
            initialTitle: 'Kind Of Blue',
          ),
        ),
      );
      await tester.pump();
      // Title appears in both app bar and skeleton body.
      expect(find.text('Kind Of Blue'), findsWidgets);
      expect(find.textContaining(' — '), findsNothing);
    });

    testWidgets('authoritative API data replaces search context after load', (
      tester,
    ) async {
      const live = ReleaseDetail(
        id: 249504,
        title: 'Live Evil',
        artist: 'Miles Davis',
        label: 'Columbia',
        catno: '',
        format: 'Vinyl',
        country: 'US',
        genres: [],
        styles: [],
        tracklist: [],
        identifiers: [],
      );
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: live),
            initialArtist: 'Miles Davis',
            initialTitle: 'Kind Of Blue',
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Authoritative data from the API is shown.
      expect(find.text('Miles Davis — Live Evil'), findsOneWidget);
      expect(find.textContaining('Kind Of Blue'), findsNothing);
    });
  });

  group('ReleaseDetailScreen — app bar title', () {
    testWidgets('shows artist and title combined in app bar when loaded', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Combined string only exists in the app bar; body renders artist and
      // title as separate widgets.
      expect(find.text('Miles Davis — Kind Of Blue'), findsOneWidget);
    });

    testWidgets('shows only title in app bar when artist is empty', (
      tester,
    ) async {
      const noArtist = ReleaseDetail(
        id: 1,
        title: 'Untitled Album',
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
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _LoadedService(detail: noArtist),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // No "—" separator when artist is absent.
      expect(find.textContaining(' — '), findsNothing);
      expect(find.text('Untitled Album'), findsWidgets);
    });

    testWidgets('shows Release Detail in app bar on error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 1,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Release Detail'), findsOneWidget);
    });

    testWidgets('shows artist and title combined in app bar from cache', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
            cacheRepository: _FakeCacheRepository(
              cachedMetadata: _cachedKindOfBlue,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Miles Davis — Kind Of Blue'), findsOneWidget);
    });
  });

  group('ReleaseDetailScreen — pull-to-refresh', () {
    testWidgets('RefreshIndicator present on loaded state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _LoadedService(detail: _kindOfBlue),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('PTR triggers fetchDetail again', (tester) async {
      final service = _CountingService(detail: _kindOfBlue);
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: service,
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.callCount, 1);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      expect(service.callCount, 2);
    });

    testWidgets('PTR updates displayed data', (tester) async {
      const updated = ReleaseDetail(
        id: 249504,
        title: 'Updated Title',
        artist: 'Miles Davis',
        label: 'Columbia',
        catno: 'CL 1355',
        format: 'Vinyl, LP',
        country: 'US',
        year: 1959,
        genres: ['Jazz'],
        styles: [],
        tracklist: [],
        identifiers: [],
      );
      final service = _UpdatingService(first: _kindOfBlue, second: updated);
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: service,
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kind Of Blue'), findsWidgets);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      expect(find.text('Updated Title'), findsWidgets);
    });

    testWidgets('network error during PTR keeps existing content visible', (
      tester,
    ) async {
      final service = _SuccessThenErrorService(
        detail: _kindOfBlue,
        error: const NetworkError(),
      );
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: service,
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kind Of Blue'), findsWidgets);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      // Content still visible — no full-screen error
      expect(find.text('Kind Of Blue'), findsWidgets);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('rate-limit error during PTR keeps existing content visible', (
      tester,
    ) async {
      final service = _SuccessThenErrorService(
        detail: _kindOfBlue,
        error: const RateLimitedError(),
      );
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: service,
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();

      // Still on loaded state — no transition to error screen
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('no RefreshIndicator in error state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _ErrorService(error: const NetworkError()),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsNothing);
    });

    testWidgets('no RefreshIndicator during initial loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReleaseDetailScreen(
            releaseId: 249504,
            detailService: _BlockingService(),
            addToCollectionUseCase: _newUseCase(),
            addToWishlistUseCase: _newWishlistUseCase(),
          ),
        ),
      );
      // Don't settle — stay in loading state
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });

  group('ReleaseDetailScreen — already in collection indicator', () {
    testWidgets(
      'shows In Collection on load when release is already in collection',
      (tester) async {
        final repo = _FakeCollectionRepository(alreadyContains: true);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: AddToCollectionUseCase(repo),
              addToWishlistUseCase: _newWishlistUseCase(),
              collectionRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('In Collection'), findsOneWidget);
        expect(find.text('Add to Collection'), findsNothing);
      },
    );

    testWidgets(
      'In Collection button is disabled on load when already in collection',
      (tester) async {
        final repo = _FakeCollectionRepository(alreadyContains: true);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: AddToCollectionUseCase(repo),
              addToWishlistUseCase: _newWishlistUseCase(),
              collectionRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = tester.widget<FilledButton>(
          find.byKey(const Key('add-to-collection-button')),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'shows Add to Collection on load when release is not in collection',
      (tester) async {
        final repo = _FakeCollectionRepository(alreadyContains: false);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: AddToCollectionUseCase(repo),
              addToWishlistUseCase: _newWishlistUseCase(),
              collectionRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add to Collection'), findsOneWidget);
        expect(find.text('In Collection'), findsNothing);
      },
    );

    testWidgets(
      'shows In Collection on load in cached state when already in collection',
      (tester) async {
        final repo = _FakeCollectionRepository(alreadyContains: true);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: AddToCollectionUseCase(repo),
              addToWishlistUseCase: _newWishlistUseCase(),
              collectionRepository: repo,
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('In Collection'), findsOneWidget);
        expect(find.text('Add to Collection'), findsNothing);
      },
    );
  });

  group('ReleaseDetailScreen — already in wishlist indicator', () {
    testWidgets(
      'shows In Wishlist on load when release is already in wishlist',
      (tester) async {
        final repo = _FakeWishlistRepository(alreadyContains: true);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: AddToWishlistUseCase(repo),
              wishlistRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('In Wishlist'), findsOneWidget);
        expect(find.text('Add to Wishlist'), findsNothing);
      },
    );

    testWidgets(
      'In Wishlist button is disabled on load when already in wishlist',
      (tester) async {
        final repo = _FakeWishlistRepository(alreadyContains: true);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: AddToWishlistUseCase(repo),
              wishlistRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = tester.widget<OutlinedButton>(
          find.byKey(const Key('add-to-wishlist-button')),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'shows Add to Wishlist on load when release is not in wishlist',
      (tester) async {
        final repo = _FakeWishlistRepository(alreadyContains: false);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _LoadedService(detail: _kindOfBlue),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: AddToWishlistUseCase(repo),
              wishlistRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add to Wishlist'), findsOneWidget);
        expect(find.text('In Wishlist'), findsNothing);
      },
    );

    testWidgets(
      'shows In Wishlist on load in cached state when already in wishlist',
      (tester) async {
        final repo = _FakeWishlistRepository(alreadyContains: true);
        await tester.pumpWidget(
          _wrap(
            ReleaseDetailScreen(
              releaseId: 249504,
              detailService: _ErrorService(error: const NetworkError()),
              addToCollectionUseCase: _newUseCase(),
              addToWishlistUseCase: AddToWishlistUseCase(repo),
              wishlistRepository: repo,
              cacheRepository: _FakeCacheRepository(
                cachedMetadata: _cachedKindOfBlue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('In Wishlist'), findsOneWidget);
        expect(find.text('Add to Wishlist'), findsNothing);
      },
    );
  });

  group('ReleaseDetailScreen — condition prompt', () {
    Widget _buildScreen({required CollectionRepository repo}) => _wrap(
      ReleaseDetailScreen(
        releaseId: 249504,
        detailService: _LoadedService(detail: _kindOfBlue),
        addToCollectionUseCase: AddToCollectionUseCase(repo),
        addToWishlistUseCase: _newWishlistUseCase(),
        collectionRepository: repo,
      ),
    );

    testWidgets('condition prompt sheet appears after successful add', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(repo: _TrackingCollectionRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Collection'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('condition-prompt-sheet')), findsOneWidget);
    });

    testWidgets('condition prompt does not appear when item is a duplicate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          repo: _TrackingCollectionRepository(alreadyContains: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-to-collection-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('condition-prompt-sheet')), findsNothing);
    });

    testWidgets('condition prompt shows default media and sleeve conditions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(repo: _TrackingCollectionRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Collection'));
      await tester.pumpAndSettle();

      // AddToCollectionUseCase defaults both to VeryGood.
      expect(find.text(RecordCondition.veryGood.label), findsNWidgets(2));
    });

    testWidgets('tapping Skip closes prompt and shows snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(repo: _TrackingCollectionRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Collection'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('condition-skip-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('condition-prompt-sheet')), findsNothing);
      expect(find.text('Added to your collection'), findsOneWidget);
    });

    testWidgets('tapping Skip does not call repository.update', (tester) async {
      final repo = _TrackingCollectionRepository();
      await tester.pumpWidget(_buildScreen(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Collection'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('condition-skip-button')));
      await tester.pumpAndSettle();

      expect(repo.updates, isEmpty);
    });

    testWidgets('tapping Save closes prompt and shows snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(repo: _TrackingCollectionRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Collection'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('condition-save-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('condition-prompt-sheet')), findsNothing);
      expect(find.text('Added to your collection'), findsOneWidget);
    });

    testWidgets(
      'tapping Save calls repository.update with selected conditions',
      (tester) async {
        final repo = _TrackingCollectionRepository();
        await tester.pumpWidget(_buildScreen(repo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add to Collection'));
        await tester.pumpAndSettle();

        // Change media condition to Near Mint via the dropdown.
        await tester.tap(find.byKey(const Key('media-condition-dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(RecordCondition.nearMint.label).last);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('condition-save-button')));
        await tester.pumpAndSettle();

        expect(repo.updates, hasLength(1));
        expect(repo.updates.first.mediaCondition, RecordCondition.nearMint);
        expect(repo.updates.first.sleeveCondition, RecordCondition.veryGood);
      },
    );
  });
}

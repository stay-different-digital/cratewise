import 'package:cratewise/application/use_cases/build_wishlist_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/fetch_wishlist_import_preview_use_case.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/infrastructure/discogs/dto/discogs_wantlist_item.dart';
import 'package:cratewise/shared/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake token storage
// ---------------------------------------------------------------------------

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.token, this.username});

  final String? token;
  final String? username;

  @override
  Future<String?> loadToken() async => token;

  @override
  Future<String?> loadUsername() async => username;

  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}

  @override
  Future<void> deleteCredentials() async {}
}

class _SpyTokenStorage implements TokenStorage {
  _SpyTokenStorage({this.token = 'fake_token', this.username = 'testuser'});
  final String? token;
  final String? username;
  int deleteCallCount = 0;

  @override
  Future<String?> loadToken() async => token;
  @override
  Future<String?> loadUsername() async => username;
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async => deleteCallCount++;
}

// ---------------------------------------------------------------------------
// Fake API client
// ---------------------------------------------------------------------------

class _FakeApiClient extends DiscogsApiClient {
  _FakeApiClient(this._pages);

  final List<DiscogsWantlistPageDto> _pages;
  int _callIndex = 0;
  final List<int> requestedPages = [];

  @override
  Future<DiscogsWantlistPageDto> fetchWantlistPage(
    String username,
    String token, {
    int page = 1,
    int perPage = 50,
  }) async {
    requestedPages.add(page);
    return _pages[_callIndex++];
  }
}

class _ThrowingApiClient extends DiscogsApiClient {
  _ThrowingApiClient(this._error);

  final AppError _error;

  @override
  Future<DiscogsWantlistPageDto> fetchWantlistPage(
    String username,
    String token, {
    int page = 1,
    int perPage = 50,
  }) async => throw _error;
}

// ---------------------------------------------------------------------------
// Fake wishlist repository
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  _FakeWishlistRepository({Set<int>? existingIds}) : _ids = existingIds ?? {};

  final Set<int> _ids;

  @override
  Future<bool> containsRelease(int discogsReleaseId) async =>
      _ids.contains(discogsReleaseId);

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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DiscogsWantlistItemDto makeDto({
  int releaseId = 100,
  String title = 'Test Album',
  String artist = 'Test Artist',
}) => DiscogsWantlistItemDto(
  releaseId: releaseId,
  dateAdded: '2023-01-01T00:00:00-08:00',
  rating: 0,
  title: title,
  artist: artist,
  label: 'Test Label',
  catno: 'TL001',
  format: 'Vinyl, LP',
  genres: const ['Rock'],
  year: 2000,
  thumbUrl: null,
);

DiscogsWantlistPageDto makePage({
  int page = 1,
  int totalPages = 1,
  int totalItems = 1,
  List<DiscogsWantlistItemDto>? items,
}) => DiscogsWantlistPageDto(
  page: page,
  totalPages: totalPages,
  totalItems: totalItems,
  items: items ?? [makeDto()],
);

FetchWishlistImportPreviewUseCase makeUseCase({
  TokenStorage? storage,
  DiscogsApiClient? apiClient,
  Set<int>? existingIds,
}) {
  final repo = _FakeWishlistRepository(existingIds: existingIds);
  return FetchWishlistImportPreviewUseCase(
    previewBuilder: BuildWishlistImportPreviewUseCase(repo),
    storage:
        storage ?? _FakeTokenStorage(token: 'fake-token', username: 'fakeuser'),
    apiClient: apiClient ?? _FakeApiClient([makePage()]),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FetchWishlistImportPreviewUseCase', () {
    group('no token', () {
      test('returns FetchWishlistPreviewNoToken when token is null', () async {
        final useCase = makeUseCase(
          storage: _FakeTokenStorage(token: null, username: 'user'),
        );
        final result = await useCase.execute();
        expect(result, isA<FetchWishlistPreviewNoToken>());
      });

      test(
        'returns FetchWishlistPreviewNoToken when username is null',
        () async {
          final useCase = makeUseCase(
            storage: _FakeTokenStorage(token: 'tok', username: null),
          );
          final result = await useCase.execute();
          expect(result, isA<FetchWishlistPreviewNoToken>());
        },
      );

      test('returns FetchWishlistPreviewNoToken when both are null', () async {
        final useCase = makeUseCase(
          storage: _FakeTokenStorage(token: null, username: null),
        );
        final result = await useCase.execute();
        expect(result, isA<FetchWishlistPreviewNoToken>());
      });
    });

    group('single-page success', () {
      test('returns FetchWishlistPreviewReady on success', () async {
        final useCase = makeUseCase();
        final result = await useCase.execute();
        expect(result, isA<FetchWishlistPreviewReady>());
      });

      test('preview contains items from single page', () async {
        final page = makePage(
          items: [
            makeDto(releaseId: 1, title: 'Album A'),
            makeDto(releaseId: 2, title: 'Album B'),
          ],
        );
        final useCase = makeUseCase(apiClient: _FakeApiClient([page]));
        final result = await useCase.execute() as FetchWishlistPreviewReady;
        expect(result.preview.totalCount, 2);
      });

      test('empty wantlist returns preview with zero counts', () async {
        final page = makePage(totalItems: 0, items: []);
        final useCase = makeUseCase(apiClient: _FakeApiClient([page]));
        final result = await useCase.execute() as FetchWishlistPreviewReady;
        expect(result.preview.totalCount, 0);
        expect(result.preview.newCount, 0);
        expect(result.preview.duplicateCount, 0);
        expect(result.preview.invalidCount, 0);
      });

      test('classifies new items correctly', () async {
        final page = makePage(items: [makeDto(releaseId: 999)]);
        final useCase = makeUseCase(apiClient: _FakeApiClient([page]));
        final result = await useCase.execute() as FetchWishlistPreviewReady;
        expect(result.preview.newCount, 1);
      });

      test('classifies duplicate items via existing repo', () async {
        final page = makePage(items: [makeDto(releaseId: 42)]);
        final useCase = makeUseCase(
          apiClient: _FakeApiClient([page]),
          existingIds: {42},
        );
        final result = await useCase.execute() as FetchWishlistPreviewReady;
        expect(result.preview.duplicateCount, 1);
        expect(result.preview.newCount, 0);
      });

      test('classifies invalid item with zero releaseId', () async {
        final page = makePage(items: [makeDto(releaseId: 0)]);
        final useCase = makeUseCase(apiClient: _FakeApiClient([page]));
        final result = await useCase.execute() as FetchWishlistPreviewReady;
        expect(result.preview.invalidCount, 1);
      });
    });

    group('pagination', () {
      test('fetches all pages for multi-page wantlist', () async {
        final page1 = makePage(
          page: 1,
          totalPages: 2,
          items: [makeDto(releaseId: 1)],
        );
        final page2 = makePage(
          page: 2,
          totalPages: 2,
          items: [makeDto(releaseId: 2)],
        );
        final client = _FakeApiClient([page1, page2]);
        final useCase = makeUseCase(apiClient: client);
        final result = await useCase.execute() as FetchWishlistPreviewReady;
        expect(result.preview.totalCount, 2);
      });

      test('requests pages 1 and 2 for two-page wantlist', () async {
        final page1 = makePage(
          page: 1,
          totalPages: 2,
          items: [makeDto(releaseId: 1)],
        );
        final page2 = makePage(
          page: 2,
          totalPages: 2,
          items: [makeDto(releaseId: 2)],
        );
        final client = _FakeApiClient([page1, page2]);
        final useCase = makeUseCase(apiClient: client);
        await useCase.execute();
        expect(client.requestedPages, [1, 2]);
      });

      test('fetches three pages when totalPages is 3', () async {
        final pages = List.generate(
          3,
          (i) => makePage(
            page: i + 1,
            totalPages: 3,
            items: [makeDto(releaseId: i + 1)],
          ),
        );
        final client = _FakeApiClient(pages);
        final useCase = makeUseCase(apiClient: client);
        final result = await useCase.execute() as FetchWishlistPreviewReady;
        expect(result.preview.totalCount, 3);
        expect(client.requestedPages, [1, 2, 3]);
      });

      test('stops after single page when totalPages is 1', () async {
        final client = _FakeApiClient([makePage(page: 1, totalPages: 1)]);
        final useCase = makeUseCase(apiClient: client);
        await useCase.execute();
        expect(client.requestedPages.length, 1);
      });
    });

    group('error handling', () {
      test(
        'returns FetchWishlistPreviewRateLimited on RateLimitedError',
        () async {
          final useCase = makeUseCase(
            apiClient: _ThrowingApiClient(const RateLimitedError()),
          );
          final result = await useCase.execute();
          expect(result, isA<FetchWishlistPreviewRateLimited>());
        },
      );

      test(
        'returns FetchWishlistPreviewNetworkError on NetworkError',
        () async {
          final useCase = makeUseCase(
            apiClient: _ThrowingApiClient(const NetworkError()),
          );
          final result = await useCase.execute();
          expect(result, isA<FetchWishlistPreviewNetworkError>());
        },
      );

      test('returns FetchWishlistPreviewError on InvalidTokenError', () async {
        final useCase = makeUseCase(
          apiClient: _ThrowingApiClient(const InvalidTokenError()),
        );
        final result = await useCase.execute();
        expect(result, isA<FetchWishlistPreviewError>());
      });

      test(
        'returns FetchWishlistPreviewError on DiscogsUnavailableError',
        () async {
          final useCase = makeUseCase(
            apiClient: _ThrowingApiClient(const DiscogsUnavailableError()),
          );
          final result = await useCase.execute();
          expect(result, isA<FetchWishlistPreviewError>());
        },
      );

      test('FetchWishlistPreviewError carries the original AppError', () async {
        const expectedError = InvalidTokenError();
        final useCase = makeUseCase(
          apiClient: _ThrowingApiClient(expectedError),
        );
        final result = await useCase.execute() as FetchWishlistPreviewError;
        expect(result.error, isA<InvalidTokenError>());
      });
    });

    group('security', () {
      test('result does not expose token value', () async {
        const token = 'super-secret-token-12345';
        final storage = _FakeTokenStorage(token: token, username: 'testuser');
        final useCase = makeUseCase(storage: storage);
        final result = await useCase.execute();
        final resultStr = result.toString();
        expect(resultStr, isNot(contains(token)));
      });
    });

    group('revoked token', () {
      test('clears credentials when API returns 401', () async {
        final spy = _SpyTokenStorage();
        final useCase = makeUseCase(
          storage: spy,
          apiClient: _ThrowingApiClient(const InvalidTokenError()),
        );
        final result = await useCase.execute();
        expect(result, isA<FetchWishlistPreviewError>());
        expect(
          (result as FetchWishlistPreviewError).error,
          isA<InvalidTokenError>(),
        );
        expect(spy.deleteCallCount, 1);
      });

      test('does not clear credentials on non-401 error', () async {
        final spy = _SpyTokenStorage();
        final useCase = makeUseCase(
          storage: spy,
          apiClient: _ThrowingApiClient(const NetworkError()),
        );
        final result = await useCase.execute();
        expect(result, isA<FetchWishlistPreviewNetworkError>());
        expect(spy.deleteCallCount, 0);
      });
    });
  });
}

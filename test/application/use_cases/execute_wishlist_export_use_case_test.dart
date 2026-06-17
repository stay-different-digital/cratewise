import 'dart:convert';

import 'package:cratewise/application/use_cases/check_wishlist_export_capability_use_case.dart';
import 'package:cratewise/application/use_cases/execute_wishlist_export_use_case.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:cratewise/domain/models/import_export_row_result.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_export_preview.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Capability fakes
// ---------------------------------------------------------------------------

class _SupportedCapabilityUseCase extends CheckWishlistExportCapabilityUseCase {
  const _SupportedCapabilityUseCase();

  @override
  CheckWishlistExportCapabilityResult execute() =>
      const WishlistExportSupported();
}

class _NotSupportedCapabilityUseCase
    extends CheckWishlistExportCapabilityUseCase {
  const _NotSupportedCapabilityUseCase();

  @override
  CheckWishlistExportCapabilityResult execute() =>
      const WishlistExportNotSupported('Export not available.');
}

// ---------------------------------------------------------------------------
// Token storage fakes
// ---------------------------------------------------------------------------

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.token, this.username});

  final String? token;
  final String? username;
  bool loadTokenCalled = false;
  bool loadUsernameCalled = false;

  @override
  Future<String?> loadToken() async {
    loadTokenCalled = true;
    return token;
  }

  @override
  Future<String?> loadUsername() async {
    loadUsernameCalled = true;
    return username;
  }

  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}

  @override
  Future<void> deleteCredentials() async {}
}

class _ThrowingTokenStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => throw Exception('Storage error');

  @override
  Future<String?> loadUsername() async => throw Exception('Storage error');

  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}

  @override
  Future<void> deleteCredentials() async {}
}

class _SpyTokenStorage implements TokenStorage {
  final String? token = 'tok';
  final String? username = 'user123';
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
// Wishlist repository fake
// ---------------------------------------------------------------------------

class _FakeWishlistRepository implements WishlistRepository {
  @override
  Future<void> deleteAll() async {}
  _FakeWishlistRepository(this._items);

  final List<WishlistItem> _items;
  final List<WishlistItem> updatedItems = [];

  @override
  Future<List<WishlistItem>> getAll() async => _items;

  @override
  Future<WishlistItem?> getById(String id) async {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;

  @override
  Future<void> add(WishlistItem item) async {}

  @override
  Future<void> update(WishlistItem item) async {
    updatedItems.add(item);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) _items[index] = item;
  }

  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Job repository fakes
// ---------------------------------------------------------------------------

class _FakeJobRepository implements ImportExportJobRepository {
  final List<ImportExportJob> added = [];
  final List<ImportExportJob> updated = [];

  @override
  Future<void> add(ImportExportJob job) async => added.add(job);

  @override
  Future<void> update(ImportExportJob job) async => updated.add(job);

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

class _ThrowingJobRepository implements ImportExportJobRepository {
  @override
  Future<void> add(ImportExportJob job) async => throw Exception('DB error');

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

// ---------------------------------------------------------------------------
// Row result repository fake
// ---------------------------------------------------------------------------

class _FakeRowResultRepository implements ImportExportRowResultRepository {
  final Map<String, List<ImportExportRowResult>> results = {};

  @override
  Future<void> addResult(String jobId, ImportExportRowResult result) async {
    results.putIfAbsent(jobId, () => []).add(result);
  }

  @override
  Future<List<ImportExportRowResult>> getResults(String jobId) async =>
      results[jobId] ?? [];

  @override
  Future<void> removeAllForJob(String jobId) async => results.remove(jobId);
}

// ---------------------------------------------------------------------------
// HTTP helpers
// ---------------------------------------------------------------------------

DiscogsApiClient _apiClientReturning(int statusCode) {
  return DiscogsApiClient(
    httpClient: MockClient(
      (_) async => http.Response(jsonEncode({}), statusCode),
    ),
  );
}

DiscogsApiClient _apiClientThrowing() {
  return DiscogsApiClient(
    httpClient: MockClient((_) async => throw Exception('no internet')),
  );
}

// ---------------------------------------------------------------------------
// Domain helpers
// ---------------------------------------------------------------------------

WishlistItem makeItem({
  String id = 'item-1',
  int releaseId = 12345,
  String artist = 'Artist',
  String title = 'Album',
  SyncStatus syncStatus = SyncStatus.localOnly,
}) {
  final now = DateTime(2024);
  return WishlistItem(
    id: id,
    discogsReleaseId: releaseId,
    artist: artist,
    title: title,
    priority: WishlistPriority.medium,
    createdAt: now,
    updatedAt: now,
    syncStatus: syncStatus,
  );
}

WishlistExportPreview makePreview({
  int eligibleCount = 0,
  int alreadySyncedCount = 0,
  int invalidCount = 0,
}) {
  final rows = <WishlistExportRow>[
    for (int i = 0; i < eligibleCount; i++)
      EligibleWishlistExportRow(
        itemId: 'e-$i',
        releaseId: 100 + i,
        artist: 'Artist',
        title: 'Eligible $i',
      ),
    for (int i = 0; i < alreadySyncedCount; i++)
      AlreadySyncedWishlistExportRow(
        itemId: 's-$i',
        releaseId: 200 + i,
        artist: 'Artist',
        title: 'Synced $i',
      ),
    for (int i = 0; i < invalidCount; i++)
      InvalidWishlistExportRow(
        itemId: 'x-$i',
        releaseId: 0,
        artist: 'Artist',
        title: 'Invalid $i',
        reason: 'Missing Discogs release ID',
      ),
  ];
  return WishlistExportPreview(rows: rows);
}

ExecuteWishlistExportUseCase makeUseCase({
  CheckWishlistExportCapabilityUseCase? capabilityUseCase,
  TokenStorage? tokenStorage,
  DiscogsApiClient? apiClient,
  WishlistRepository? wishlistRepository,
  ImportExportJobRepository? jobRepository,
  ImportExportRowResultRepository? rowResultRepository,
  List<WishlistItem> items = const [],
  String Function()? idGenerator,
  Future<void> Function(Duration)? delay,
  int maxItemRetries = 0,
}) {
  return ExecuteWishlistExportUseCase(
    capabilityUseCase: capabilityUseCase ?? const _SupportedCapabilityUseCase(),
    tokenStorage:
        tokenStorage ?? _FakeTokenStorage(token: 'tok', username: 'user123'),
    apiClient: apiClient ?? _apiClientReturning(201),
    wishlistRepository: wishlistRepository ?? _FakeWishlistRepository(items),
    jobRepository: jobRepository ?? _FakeJobRepository(),
    rowResultRepository: rowResultRepository ?? _FakeRowResultRepository(),
    idGenerator: idGenerator,
    delay: delay,
    maxItemRetries: maxItemRetries,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExecuteWishlistExportUseCase', () {
    group('capability not supported', () {
      test('returns ExecuteWishlistExportNotSupported', () async {
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        final result = await uc.execute(makePreview(eligibleCount: 2));
        expect(result, isA<ExecuteWishlistExportNotSupported>());
      });

      test('not supported result forwards the capability reason', () async {
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        final result =
            await uc.execute(makePreview())
                as ExecuteWishlistExportNotSupported;
        expect(result.reason, 'Export not available.');
      });

      test('does not call token storage when not supported', () async {
        final tokenStorage = _FakeTokenStorage(token: 'tok', username: 'user');
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
          tokenStorage: tokenStorage,
        );
        await uc.execute(makePreview(eligibleCount: 1));
        expect(tokenStorage.loadTokenCalled, isFalse);
        expect(tokenStorage.loadUsernameCalled, isFalse);
      });

      test('does not call the API when not supported', () async {
        var apiCalled = false;
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
          apiClient: DiscogsApiClient(
            httpClient: MockClient((_) async {
              apiCalled = true;
              return http.Response('', 201);
            }),
          ),
        );
        await uc.execute(makePreview(eligibleCount: 1));
        expect(apiCalled, isFalse);
      });
    });

    group('no token', () {
      test('returns ExecuteWishlistExportNoToken when token is null', () async {
        final uc = makeUseCase(
          tokenStorage: _FakeTokenStorage(token: null, username: 'user'),
        );
        final result = await uc.execute(makePreview(eligibleCount: 1));
        expect(result, isA<ExecuteWishlistExportNoToken>());
      });

      test(
        'returns ExecuteWishlistExportNoToken when token is empty',
        () async {
          final uc = makeUseCase(
            tokenStorage: _FakeTokenStorage(token: '', username: 'user'),
          );
          final result = await uc.execute(makePreview(eligibleCount: 1));
          expect(result, isA<ExecuteWishlistExportNoToken>());
        },
      );

      test(
        'returns ExecuteWishlistExportNoToken when username is null',
        () async {
          final uc = makeUseCase(
            tokenStorage: _FakeTokenStorage(token: 'tok', username: null),
          );
          final result = await uc.execute(makePreview(eligibleCount: 1));
          expect(result, isA<ExecuteWishlistExportNoToken>());
        },
      );

      test(
        'returns ExecuteWishlistExportNoToken when username is empty',
        () async {
          final uc = makeUseCase(
            tokenStorage: _FakeTokenStorage(token: 'tok', username: ''),
          );
          final result = await uc.execute(makePreview(eligibleCount: 1));
          expect(result, isA<ExecuteWishlistExportNoToken>());
        },
      );

      test(
        'returns ExecuteWishlistExportNoToken when token storage throws',
        () async {
          final uc = makeUseCase(tokenStorage: _ThrowingTokenStorage());
          final result = await uc.execute(makePreview(eligibleCount: 1));
          expect(result, isA<ExecuteWishlistExportNoToken>());
        },
      );
    });

    group('successful export', () {
      test('returns ExecuteWishlistExportCompleted', () async {
        final uc = makeUseCase();
        final result = await uc.execute(makePreview());
        expect(result, isA<ExecuteWishlistExportCompleted>());
      });

      test('exported count matches eligible rows', () async {
        final items = [
          makeItem(id: 'e-0', releaseId: 100),
          makeItem(id: 'e-1', releaseId: 101),
        ];
        final uc = makeUseCase(
          items: items,
          wishlistRepository: _FakeWishlistRepository(items),
        );
        final result =
            await uc.execute(makePreview(eligibleCount: 2))
                as ExecuteWishlistExportCompleted;
        expect(result.exported, 2);
        expect(result.skipped, 0);
        expect(result.failed, 0);
      });

      test('skipped count matches already-synced and invalid rows', () async {
        final uc = makeUseCase();
        final result =
            await uc.execute(
                  makePreview(alreadySyncedCount: 2, invalidCount: 1),
                )
                as ExecuteWishlistExportCompleted;
        expect(result.exported, 0);
        expect(result.skipped, 3);
        expect(result.failed, 0);
      });

      test('updates sync status to synced for exported items', () async {
        final items = [makeItem(id: 'e-0', releaseId: 100)];
        final repo = _FakeWishlistRepository(items);
        final uc = makeUseCase(items: items, wishlistRepository: repo);
        await uc.execute(makePreview(eligibleCount: 1));
        expect(repo.updatedItems, hasLength(1));
        expect(repo.updatedItems.first.syncStatus, SyncStatus.synced);
      });

      test('does not update sync status for skipped items', () async {
        final repo = _FakeWishlistRepository([]);
        final uc = makeUseCase(wishlistRepository: repo);
        await uc.execute(makePreview(alreadySyncedCount: 1, invalidCount: 1));
        expect(repo.updatedItems, isEmpty);
      });

      test('saves a job with exportWishlistToDiscogs type', () async {
        final jobRepo = _FakeJobRepository();
        final uc = makeUseCase(jobRepository: jobRepo);
        await uc.execute(makePreview(eligibleCount: 1));
        expect(jobRepo.added, hasLength(1));
        expect(
          jobRepo.added.first.jobType,
          ImportExportJobType.exportWishlistToDiscogs,
        );
      });

      test('saves final completed status for zero failures', () async {
        final jobRepo = _FakeJobRepository();
        final uc = makeUseCase(jobRepository: jobRepo);
        await uc.execute(makePreview(eligibleCount: 1));
        final finalJob = jobRepo.updated.last;
        expect(finalJob.status, ImportExportStatus.completed);
      });

      test('saves row result for each eligible item', () async {
        final rowRepo = _FakeRowResultRepository();
        final uc = makeUseCase(rowResultRepository: rowRepo);
        await uc.execute(makePreview(eligibleCount: 2));
        final results = rowRepo.results.values.first;
        final validRows = results.whereType<ValidRow>().toList();
        expect(validRows, hasLength(2));
      });

      test('saves SkippedRow for already-synced items', () async {
        final rowRepo = _FakeRowResultRepository();
        final uc = makeUseCase(rowResultRepository: rowRepo);
        await uc.execute(makePreview(alreadySyncedCount: 1));
        final results = rowRepo.results.values.first;
        expect(results.whereType<SkippedRow>(), hasLength(1));
      });

      test('saves SkippedRow for invalid items', () async {
        final rowRepo = _FakeRowResultRepository();
        final uc = makeUseCase(rowResultRepository: rowRepo);
        await uc.execute(makePreview(invalidCount: 2));
        final results = rowRepo.results.values.first;
        expect(results.whereType<SkippedRow>(), hasLength(2));
      });

      test('uses provided idGenerator for job ID', () async {
        const fixedId = 'fixed-job-id';
        final jobRepo = _FakeJobRepository();
        final uc = makeUseCase(
          jobRepository: jobRepo,
          idGenerator: () => fixedId,
        );
        final result =
            await uc.execute(makePreview()) as ExecuteWishlistExportCompleted;
        expect(result.jobId, fixedId);
        expect(jobRepo.added.first.id, fixedId);
      });
    });

    group('partial failure', () {
      test(
        'failed items are counted and do not affect skipped count',
        () async {
          final repo = _FakeWishlistRepository([
            makeItem(id: 'e-0', releaseId: 100),
            makeItem(id: 'e-1', releaseId: 101),
          ]);
          int callCount = 0;
          final apiClient = DiscogsApiClient(
            httpClient: MockClient((_) async {
              callCount++;
              return http.Response('', callCount == 1 ? 201 : 401);
            }),
          );
          final uc = makeUseCase(
            wishlistRepository: repo,
            apiClient: apiClient,
          );
          final result =
              await uc.execute(makePreview(eligibleCount: 2))
                  as ExecuteWishlistExportCompleted;
          expect(result.exported, 1);
          expect(result.failed, 1);
          expect(result.skipped, 0);
        },
      );

      test('saves completedWithErrors status when any items fail', () async {
        final jobRepo = _FakeJobRepository();
        final uc = makeUseCase(
          jobRepository: jobRepo,
          apiClient: _apiClientReturning(401),
        );
        await uc.execute(makePreview(eligibleCount: 1));
        expect(
          jobRepo.updated.last.status,
          ImportExportStatus.completedWithErrors,
        );
      });

      test('saves FailedRow for each failed item', () async {
        final rowRepo = _FakeRowResultRepository();
        final uc = makeUseCase(
          rowResultRepository: rowRepo,
          apiClient: _apiClientReturning(500),
        );
        await uc.execute(makePreview(eligibleCount: 3));
        final results = rowRepo.results.values.first;
        expect(results.whereType<FailedRow>(), hasLength(3));
      });

      test('failed export updates sync status to failed', () async {
        final items = [makeItem(id: 'e-0', releaseId: 100)];
        final repo = _FakeWishlistRepository(items);
        final uc = makeUseCase(
          items: items,
          wishlistRepository: repo,
          apiClient: _apiClientReturning(401),
        );
        await uc.execute(makePreview(eligibleCount: 1));
        expect(repo.updatedItems, hasLength(1));
        expect(repo.updatedItems.first.syncStatus, SyncStatus.failed);
      });

      test('network error on one item counts as failure', () async {
        final uc = makeUseCase(apiClient: _apiClientThrowing());
        final result =
            await uc.execute(makePreview(eligibleCount: 2))
                as ExecuteWishlistExportCompleted;
        expect(result.failed, 2);
      });
    });

    group('infrastructure failure', () {
      test(
        'returns ExecuteWishlistExportFailed when job repository throws',
        () async {
          final uc = makeUseCase(jobRepository: _ThrowingJobRepository());
          final result = await uc.execute(makePreview(eligibleCount: 1));
          expect(result, isA<ExecuteWishlistExportFailed>());
        },
      );

      test('safe message does not contain token or secret', () async {
        final uc = makeUseCase(jobRepository: _ThrowingJobRepository());
        final result =
            await uc.execute(makePreview()) as ExecuteWishlistExportFailed;
        expect(result.safeMessage.toLowerCase(), isNot(contains('token')));
        expect(result.safeMessage.toLowerCase(), isNot(contains('secret')));
      });
    });

    group('security', () {
      test('not-supported reason does not contain token or secret', () async {
        final uc = makeUseCase(
          capabilityUseCase: const _NotSupportedCapabilityUseCase(),
        );
        final result =
            await uc.execute(makePreview())
                as ExecuteWishlistExportNotSupported;
        expect(result.reason.toLowerCase(), isNot(contains('token')));
        expect(result.reason.toLowerCase(), isNot(contains('secret')));
      });

      test('row result descriptions do not contain token', () async {
        final rowRepo = _FakeRowResultRepository();
        final uc = makeUseCase(rowResultRepository: rowRepo);
        await uc.execute(makePreview(eligibleCount: 1));
        final results = rowRepo.results.values.expand((r) => r).toList();
        for (final row in results) {
          if (row is ValidRow) {
            expect(row.description.toLowerCase(), isNot(contains('token')));
          }
        }
      });
    });

    group('revoked token', () {
      test('clears credentials when per-row API call returns 401', () async {
        final spy = _SpyTokenStorage();
        final uc = makeUseCase(
          tokenStorage: spy,
          apiClient: _apiClientReturning(401),
        );
        final result = await uc.execute(makePreview(eligibleCount: 1));
        expect(result, isA<ExecuteWishlistExportCompleted>());
        expect((result as ExecuteWishlistExportCompleted).failed, 1);
        expect(spy.deleteCallCount, 1);
      });

      test('does not clear credentials on non-401 per-row failure', () async {
        final spy = _SpyTokenStorage();
        final uc = makeUseCase(
          tokenStorage: spy,
          apiClient: _apiClientThrowing(),
        );
        final result = await uc.execute(makePreview(eligibleCount: 1));
        expect(result, isA<ExecuteWishlistExportCompleted>());
        expect(spy.deleteCallCount, 0);
      });
    });

    group('rate-limit retry', () {
      Future<void> noOpDelay(Duration _) async {}

      DiscogsApiClient apiClientWithStatuses(List<int> statuses) {
        var call = 0;
        return DiscogsApiClient(
          httpClient: MockClient((_) async {
            final code = call < statuses.length ? statuses[call] : 201;
            call++;
            return http.Response(jsonEncode({}), code);
          }),
        );
      }

      test(
        'returns ExportCompleted exported=1 when item succeeds on retry after 429',
        () async {
          final uc = makeUseCase(
            apiClient: apiClientWithStatuses([429, 201]),
            delay: noOpDelay,
            maxItemRetries: 1,
          );
          final result =
              await uc.execute(makePreview(eligibleCount: 1))
                  as ExecuteWishlistExportCompleted;
          expect(result.exported, 1);
          expect(result.failed, 0);
        },
      );

      test('calls delay with 60-second duration on 429', () async {
        final delays = <Duration>[];
        final uc = makeUseCase(
          apiClient: apiClientWithStatuses([429, 201]),
          delay: (d) async => delays.add(d),
          maxItemRetries: 1,
        );
        await uc.execute(makePreview(eligibleCount: 1));
        expect(delays, [const Duration(seconds: 60)]);
      });

      test('items exported before 429 are not re-exported', () async {
        var totalCalls = 0;
        final uc = makeUseCase(
          // call 1: item-0 => 201, call 2: item-1 => 429, call 3: item-1 retry => 201
          apiClient: DiscogsApiClient(
            httpClient: MockClient((_) async {
              totalCalls++;
              return http.Response(jsonEncode({}), totalCalls == 2 ? 429 : 201);
            }),
          ),
          delay: noOpDelay,
          maxItemRetries: 1,
        );
        final result =
            await uc.execute(makePreview(eligibleCount: 2))
                as ExecuteWishlistExportCompleted;
        expect(result.exported, 2);
        expect(totalCalls, 3);
      });

      test('item counts as failed when retries exhausted', () async {
        final uc = makeUseCase(
          apiClient: apiClientWithStatuses([429]),
          delay: noOpDelay,
          maxItemRetries: 0,
        );
        final result =
            await uc.execute(makePreview(eligibleCount: 1))
                as ExecuteWishlistExportCompleted;
        expect(result.failed, 1);
        expect(result.exported, 0);
      });

      test('export continues with remaining items after exhaustion', () async {
        // item-0 gets 429 (exhausted immediately at maxItemRetries=0), item-1 succeeds
        var totalCalls = 0;
        final uc = makeUseCase(
          apiClient: DiscogsApiClient(
            httpClient: MockClient((_) async {
              totalCalls++;
              return http.Response(jsonEncode({}), totalCalls == 1 ? 429 : 201);
            }),
          ),
          delay: noOpDelay,
          maxItemRetries: 0,
        );
        final result =
            await uc.execute(makePreview(eligibleCount: 2))
                as ExecuteWishlistExportCompleted;
        expect(result.failed, 1);
        expect(result.exported, 1);
      });

      test('calls delay maxItemRetries times before exhaustion', () async {
        final delays = <Duration>[];
        // 3 consecutive 429s: 2 retries allowed, so delay called twice then rethrows
        final uc = makeUseCase(
          apiClient: apiClientWithStatuses([429, 429, 429]),
          delay: (d) async => delays.add(d),
          maxItemRetries: 2,
        );
        await uc.execute(makePreview(eligibleCount: 1));
        expect(delays, hasLength(2));
        expect(delays.every((d) => d == const Duration(seconds: 60)), isTrue);
      });

      test('saves ValidRow for item that succeeds after retry', () async {
        final rowRepo = _FakeRowResultRepository();
        final uc = makeUseCase(
          apiClient: apiClientWithStatuses([429, 201]),
          delay: noOpDelay,
          maxItemRetries: 1,
          rowResultRepository: rowRepo,
        );
        await uc.execute(makePreview(eligibleCount: 1));
        final results = rowRepo.results.values.first;
        expect(results.whereType<ValidRow>(), hasLength(1));
      });
    });
  });
}

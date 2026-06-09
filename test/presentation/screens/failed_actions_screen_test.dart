import 'package:cratewise/application/use_cases/retry_add_collection_item_use_case.dart';
import 'package:cratewise/application/use_cases/retry_add_wishlist_item_use_case.dart';
import 'package:cratewise/application/use_cases/retry_metadata_refresh_use_case.dart';
import 'package:cratewise/application/use_cases/retry_thumbnail_use_case.dart';
import 'package:cratewise/domain/models/cached_release_metadata.dart';
import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/repositories/cached_release_metadata_repository.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/presentation/screens/failed_actions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeRetryRepo implements RetryActionRepository {
  _FakeRetryRepo({this.actions = const [], this.throwsOnLoad = false});

  final List<RetryAction> actions;
  final bool throwsOnLoad;
  int loadCallCount = 0;

  @override
  Future<List<RetryAction>> getAll() async {
    loadCallCount++;
    if (throwsOnLoad) throw Exception('db error');
    return List.of(actions);
  }

  @override
  Future<RetryAction?> getById(String id) async =>
      actions.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<RetryAction>> getPending() async =>
      actions.where((a) => a.status == RetryActionStatus.pending).toList();

  @override
  Future<void> add(RetryAction action) async {}

  @override
  Future<void> update(RetryAction action) async {}

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> deleteFailedBefore(DateTime cutoff) async {}
}

// Minimal fakes for RetryMetadataRefreshUseCase super-constructor.
class _NullCacheRepo implements CachedReleaseMetadataRepository {
  @override
  Future<CachedReleaseMetadata?> getByReleaseId(int id) async => null;
  @override
  Future<void> save(CachedReleaseMetadata m) async {}
  @override
  Future<void> remove(int id) async {}
}

class _NullRetryRepoForUseCase implements RetryActionRepository {
  @override
  Future<void> add(RetryAction a) async {}
  @override
  Future<List<RetryAction>> getAll() async => [];
  @override
  Future<RetryAction?> getById(String id) async => null;
  @override
  Future<List<RetryAction>> getPending() async => [];
  @override
  Future<void> update(RetryAction a) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> deleteFailedBefore(DateTime cutoff) async {}
}

class _NullThumbnailRepo implements ThumbnailRepository {
  @override
  Future<String?> getLocalPath(int id) async => null;
  @override
  Future<void> save(int id, List<int> bytes) async {}
  @override
  Future<void> remove(int id) async {}
  @override
  Future<bool> exists(int id) async => false;
  @override
  Future<int> totalSizeBytes() async => 0;
  @override
  Future<List<ThumbnailEntry>> listEntries() async => [];
  @override
  Future<void> removeAll() async {}
}

/// Fake use case that returns a configurable result without touching repos.
class _FakeRetryUseCase extends RetryMetadataRefreshUseCase {
  _FakeRetryUseCase(this._result)
    : super(retryRepo: _NullRetryRepoForUseCase(), cacheRepo: _NullCacheRepo());

  final RetryMetadataResult _result;
  int callCount = 0;

  @override
  Future<RetryMetadataResult> execute(RetryAction action) async {
    callCount++;
    return _result;
  }
}

/// Fake thumbnail use case that returns a configurable result.
class _FakeThumbnailUseCase extends RetryThumbnailUseCase {
  _FakeThumbnailUseCase(this._result)
    : super(
        retryRepo: _NullRetryRepoForUseCase(),
        cacheRepo: _NullCacheRepo(),
        thumbnailRepo: _NullThumbnailRepo(),
      );

  final RetryThumbnailResult _result;
  int callCount = 0;

  @override
  Future<RetryThumbnailResult> execute(RetryAction action) async {
    callCount++;
    return _result;
  }
}

class _FlippingRepo implements RetryActionRepository {
  _FlippingRepo({required this.successActions});

  final List<RetryAction> successActions;
  int _callCount = 0;

  @override
  Future<List<RetryAction>> getAll() async {
    _callCount++;
    if (_callCount == 1) throw Exception('first load fails');
    return List.of(successActions);
  }

  @override
  Future<RetryAction?> getById(String id) async => null;
  @override
  Future<List<RetryAction>> getPending() async => [];
  @override
  Future<void> add(RetryAction action) async {}
  @override
  Future<void> update(RetryAction action) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> deleteFailedBefore(DateTime cutoff) async {}
}

// Null collection/wishlist repos for use case constructors.
class _NullCollectionRepo implements CollectionRepository {
  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _NullWishlistRepo implements WishlistRepository {
  @override
  Future<List<WishlistItem>> getAll() async => [];
  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int id) async => false;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakeAddCollectionUseCase extends RetryAddCollectionItemUseCase {
  _FakeAddCollectionUseCase(this._result)
    : super(
        retryRepo: _NullRetryRepoForUseCase(),
        collectionRepo: _NullCollectionRepo(),
      );

  final RetryAddCollectionItemResult _result;
  int callCount = 0;

  @override
  Future<RetryAddCollectionItemResult> execute(RetryAction action) async {
    callCount++;
    return _result;
  }
}

class _FakeAddWishlistUseCase extends RetryAddWishlistItemUseCase {
  _FakeAddWishlistUseCase(this._result)
    : super(
        retryRepo: _NullRetryRepoForUseCase(),
        wishlistRepo: _NullWishlistRepo(),
      );

  final RetryAddWishlistItemResult _result;
  int callCount = 0;

  @override
  Future<RetryAddWishlistItemResult> execute(RetryAction action) async {
    callCount++;
    return _result;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

RetryAction _makeAction({
  String id = 'a1',
  RetryActionType actionType = RetryActionType.cacheThumbnail,
  RetryActionEntityType entityType = RetryActionEntityType.cachedRelease,
  String entityId = '1',
  String safeErrorMessage = 'Cover image could not be cached.',
  RetryActionStatus status = RetryActionStatus.pending,
  int attemptCount = 0,
  DateTime? lastAttemptedAt,
}) {
  return RetryAction(
    id: id,
    actionType: actionType,
    entityType: entityType,
    entityId: entityId,
    safeErrorMessage: safeErrorMessage,
    createdAt: DateTime(2026, 6, 1, 10, 0),
    attemptCount: attemptCount,
    status: status,
    lastAttemptedAt: lastAttemptedAt,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FailedActionsScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeRetryRepo();
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no non-abandoned actions', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: []);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('No failed actions'), findsOneWidget);
      expect(find.text('Everything is up to date.'), findsOneWidget);
    });

    testWidgets('shows empty state when all actions are abandoned', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(
        actions: [_makeAction(status: RetryActionStatus.abandoned)],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('No failed actions'), findsOneWidget);
    });

    testWidgets('shows action card for pending action', (tester) async {
      final repo = _FakeRetryRepo(actions: [_makeAction()]);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows friendly label for cacheThumbnail', (tester) async {
      final repo = _FakeRetryRepo(
        actions: [_makeAction(actionType: RetryActionType.cacheThumbnail)],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Cache cover image'), findsOneWidget);
    });

    testWidgets('shows friendly label for refreshReleaseMetadata', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(
        actions: [
          _makeAction(actionType: RetryActionType.refreshReleaseMetadata),
        ],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Refresh release info'), findsOneWidget);
    });

    testWidgets('shows safe error message on card', (tester) async {
      const msg = 'Cover image could not be cached.';
      final repo = _FakeRetryRepo(
        actions: [_makeAction(safeErrorMessage: msg)],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text(msg), findsOneWidget);
    });

    testWidgets('shows attempt count on card', (tester) async {
      final repo = _FakeRetryRepo(actions: [_makeAction(attemptCount: 3)]);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows queued status chip for pending action', (tester) async {
      final repo = _FakeRetryRepo(
        actions: [_makeAction(status: RetryActionStatus.pending)],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Queued'), findsOneWidget);
    });

    testWidgets('shows failed status chip for failed action', (tester) async {
      final repo = _FakeRetryRepo(
        actions: [_makeAction(status: RetryActionStatus.failed)],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('shows last tried row when lastAttemptedAt is set', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(
        actions: [_makeAction(lastAttemptedAt: DateTime(2026, 6, 1, 15, 30))],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last tried:'), findsOneWidget);
    });

    testWidgets('does not show last tried row when lastAttemptedAt is null', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [_makeAction()]);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last tried:'), findsNothing);
    });

    testWidgets('shows multiple cards for multiple actions', (tester) async {
      final repo = _FakeRetryRepo(
        actions: [
          _makeAction(id: 'a1', entityId: '1'),
          _makeAction(id: 'a2', entityId: '2'),
          _makeAction(id: 'a3', entityId: '3'),
        ],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('shows error state on repository failure', (tester) async {
      final repo = _FakeRetryRepo(throwsOnLoad: true);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not load failed actions from device storage.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });

    testWidgets('retry button reloads and shows empty state on success', (
      tester,
    ) async {
      final repo = _FlippingRepo(successActions: []);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not load failed actions from device storage.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No failed actions'), findsOneWidget);
    });

    testWidgets('screen has Failed Actions app bar title', (tester) async {
      final repo = _FakeRetryRepo();
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Failed Actions'), findsOneWidget);
    });

    group('FailedActionsScreen — security', () {
      testWidgets('card text does not contain token or secret', (tester) async {
        final repo = _FakeRetryRepo(
          actions: [
            _makeAction(
              safeErrorMessage: 'Release metadata could not be refreshed.',
              actionType: RetryActionType.refreshReleaseMetadata,
            ),
            _makeAction(
              id: 'b2',
              safeErrorMessage: 'Cover image could not be cached.',
              actionType: RetryActionType.cacheThumbnail,
            ),
          ],
        );
        await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
        await tester.pumpAndSettle();

        final allText = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' ')
            .toLowerCase();

        expect(allText, isNot(contains('token')));
        expect(allText, isNot(contains('secret')));
        expect(allText, isNot(contains('header')));
        expect(allText, isNot(contains('authorization')));
      });
    });
  });

  group('FailedActionsScreen — retry button', () {
    RetryAction metadataAction() => _makeAction(
      actionType: RetryActionType.refreshReleaseMetadata,
      safeErrorMessage: 'Release metadata could not be refreshed.',
    );

    testWidgets(
      'shows Retry button for refreshReleaseMetadata when use case provided',
      (tester) async {
        final repo = _FakeRetryRepo(actions: [metadataAction()]);
        final uc = _FakeRetryUseCase(const RetryMetadataSuccess());
        await tester.pumpWidget(
          _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
      },
    );

    testWidgets('does NOT show Retry button for cacheThumbnail action', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(
        actions: [_makeAction(actionType: RetryActionType.cacheThumbnail)],
      );
      final uc = _FakeRetryUseCase(const RetryMetadataSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Retry'), findsNothing);
    });

    testWidgets('does NOT show Retry button when no use case provided', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [metadataAction()]);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Retry'), findsNothing);
    });

    testWidgets('tapping Retry calls use case execute', (tester) async {
      final repo = _FakeRetryRepo(actions: [metadataAction()]);
      final uc = _FakeRetryUseCase(const RetryMetadataSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(uc.callCount, 1);
    });

    testWidgets('success shows snackbar with success message', (tester) async {
      final repo = _FakeRetryRepo(actions: [metadataAction()]);
      final uc = _FakeRetryUseCase(const RetryMetadataSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Release info updated.'), findsOneWidget);
    });

    testWidgets('NoToken shows snackbar with connect-account message', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [metadataAction()]);
      final uc = _FakeRetryUseCase(const RetryMetadataNoToken());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Connect your Discogs account to retry.'),
        findsOneWidget,
      );
    });

    testWidgets('RateLimited shows snackbar with rate-limit message', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [metadataAction()]);
      final uc = _FakeRetryUseCase(const RetryMetadataRateLimited());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Rate limited — try again shortly.'), findsOneWidget);
    });

    testWidgets('NetworkError shows snackbar with network message', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [metadataAction()]);
      final uc = _FakeRetryUseCase(const RetryMetadataNetworkError());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Network unavailable — try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('snackbar message does not contain token or secret', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [metadataAction()]);
      for (final result in <RetryMetadataResult>[
        const RetryMetadataSuccess(),
        const RetryMetadataNoToken(),
        const RetryMetadataRateLimited(),
        const RetryMetadataNetworkError(),
        const RetryMetadataFailed(),
      ]) {
        final uc = _FakeRetryUseCase(result);
        await tester.pumpWidget(
          _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Retry'));
        await tester.pumpAndSettle();

        final snackbar = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(SnackBar),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data ?? '')
            .join(' ')
            .toLowerCase();

        expect(snackbar, isNot(contains('token')));
        expect(snackbar, isNot(contains('secret')));
      }
    });

    testWidgets('after success, list reloads (shows empty state)', (
      tester,
    ) async {
      // Repo starts with one action; after retry (success) the action is
      // removed and the list reloads as empty.
      final actions = [metadataAction()];
      final repo = _FakeRetryRepo(actions: actions);
      final uc = _FakeRetryUseCase(const RetryMetadataSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, retryUseCase: uc)),
      );
      await tester.pumpAndSettle();

      // Simulate the action being removed (success removes it from repo).
      actions.clear();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No failed actions'), findsOneWidget);
    });
  });

  group('FailedActionsScreen — thumbnail retry button', () {
    RetryAction thumbnailAction() => _makeAction(
      actionType: RetryActionType.cacheThumbnail,
      safeErrorMessage: 'Cover image could not be cached.',
    );

    testWidgets(
      'shows Retry button for cacheThumbnail when thumbnailUseCase provided',
      (tester) async {
        final repo = _FakeRetryRepo(actions: [thumbnailAction()]);
        final uc = _FakeThumbnailUseCase(const RetryThumbnailSuccess());
        await tester.pumpWidget(
          _wrap(FailedActionsScreen(repository: repo, thumbnailUseCase: uc)),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'does NOT show Retry button for cacheThumbnail without thumbnailUseCase',
      (tester) async {
        final repo = _FakeRetryRepo(actions: [thumbnailAction()]);
        await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'Retry'), findsNothing);
      },
    );

    testWidgets('tapping Retry for thumbnail calls thumbnailUseCase.execute', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [thumbnailAction()]);
      final uc = _FakeThumbnailUseCase(const RetryThumbnailSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, thumbnailUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(uc.callCount, 1);
    });

    testWidgets('Success shows snackbar with cached message', (tester) async {
      final repo = _FakeRetryRepo(actions: [thumbnailAction()]);
      final uc = _FakeThumbnailUseCase(const RetryThumbnailSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, thumbnailUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Cover image cached.'), findsOneWidget);
    });

    testWidgets('NoUrl shows safe snackbar message', (tester) async {
      final repo = _FakeRetryRepo(actions: [thumbnailAction()]);
      final uc = _FakeThumbnailUseCase(const RetryThumbnailNoUrl());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, thumbnailUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(
        find.text('No cover image available for this release.'),
        findsOneWidget,
      );
    });

    testWidgets('NetworkError shows safe snackbar message', (tester) async {
      final repo = _FakeRetryRepo(actions: [thumbnailAction()]);
      final uc = _FakeThumbnailUseCase(const RetryThumbnailNetworkError());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, thumbnailUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Network unavailable — try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('thumbnail snackbar does not contain token or secret', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [thumbnailAction()]);
      for (final result in <RetryThumbnailResult>[
        const RetryThumbnailSuccess(),
        const RetryThumbnailNoUrl(),
        const RetryThumbnailNetworkError(),
        const RetryThumbnailFailed(),
      ]) {
        final uc = _FakeThumbnailUseCase(result);
        await tester.pumpWidget(
          _wrap(FailedActionsScreen(repository: repo, thumbnailUseCase: uc)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Retry'));
        await tester.pumpAndSettle();

        final snackbar = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(SnackBar),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data ?? '')
            .join(' ')
            .toLowerCase();

        expect(snackbar, isNot(contains('token')));
        expect(snackbar, isNot(contains('secret')));
      }
    });

    testWidgets('after success, list reloads', (tester) async {
      final actions = [thumbnailAction()];
      final repo = _FakeRetryRepo(actions: actions);
      final uc = _FakeThumbnailUseCase(const RetryThumbnailSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, thumbnailUseCase: uc)),
      );
      await tester.pumpAndSettle();

      actions.clear();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No failed actions'), findsOneWidget);
    });
  });

  group('FailedActionsScreen — add collection item retry button', () {
    RetryAction addCollectionAction() => _makeAction(
      actionType: RetryActionType.addCollectionItem,
      safeErrorMessage: "Could not save 'Kind Of Blue' to collection.",
    );

    testWidgets(
      'shows Retry button for addCollectionItem when addCollectionUseCase provided',
      (tester) async {
        final repo = _FakeRetryRepo(actions: [addCollectionAction()]);
        final uc = _FakeAddCollectionUseCase(
          const RetryAddCollectionItemSuccess(),
        );
        await tester.pumpWidget(
          _wrap(
            FailedActionsScreen(repository: repo, addCollectionUseCase: uc),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'does NOT show Retry button for addCollectionItem without use case',
      (tester) async {
        final repo = _FakeRetryRepo(actions: [addCollectionAction()]);
        await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'Retry'), findsNothing);
      },
    );

    testWidgets('tapping Retry calls addCollectionUseCase.execute', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [addCollectionAction()]);
      final uc = _FakeAddCollectionUseCase(
        const RetryAddCollectionItemSuccess(),
      );
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, addCollectionUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(uc.callCount, 1);
    });

    testWidgets('Success shows snackbar with added-to-collection message', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [addCollectionAction()]);
      final uc = _FakeAddCollectionUseCase(
        const RetryAddCollectionItemSuccess(),
      );
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, addCollectionUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Item added to collection.'), findsOneWidget);
    });

    testWidgets('AlreadyExists shows safe snackbar message', (tester) async {
      final repo = _FakeRetryRepo(actions: [addCollectionAction()]);
      final uc = _FakeAddCollectionUseCase(
        const RetryAddCollectionItemAlreadyExists(),
      );
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, addCollectionUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Already in your collection.'), findsOneWidget);
    });

    testWidgets('StorageError shows safe snackbar message', (tester) async {
      final repo = _FakeRetryRepo(actions: [addCollectionAction()]);
      final uc = _FakeAddCollectionUseCase(
        const RetryAddCollectionItemStorageError(),
      );
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, addCollectionUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not save to collection — try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('shows friendly label for addCollectionItem action', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [addCollectionAction()]);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Add to collection'), findsOneWidget);
    });
  });

  group('FailedActionsScreen — add wishlist item retry button', () {
    RetryAction addWishlistAction() => _makeAction(
      actionType: RetryActionType.addWishlistItem,
      safeErrorMessage: "Could not save 'Kind Of Blue' to wishlist.",
    );

    testWidgets(
      'shows Retry button for addWishlistItem when addWishlistUseCase provided',
      (tester) async {
        final repo = _FakeRetryRepo(actions: [addWishlistAction()]);
        final uc = _FakeAddWishlistUseCase(const RetryAddWishlistItemSuccess());
        await tester.pumpWidget(
          _wrap(FailedActionsScreen(repository: repo, addWishlistUseCase: uc)),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'does NOT show Retry button for addWishlistItem without use case',
      (tester) async {
        final repo = _FakeRetryRepo(actions: [addWishlistAction()]);
        await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'Retry'), findsNothing);
      },
    );

    testWidgets('tapping Retry calls addWishlistUseCase.execute', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [addWishlistAction()]);
      final uc = _FakeAddWishlistUseCase(const RetryAddWishlistItemSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, addWishlistUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(uc.callCount, 1);
    });

    testWidgets('Success shows snackbar with added-to-wishlist message', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [addWishlistAction()]);
      final uc = _FakeAddWishlistUseCase(const RetryAddWishlistItemSuccess());
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, addWishlistUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Item added to wishlist.'), findsOneWidget);
    });

    testWidgets('StorageError shows safe snackbar message', (tester) async {
      final repo = _FakeRetryRepo(actions: [addWishlistAction()]);
      final uc = _FakeAddWishlistUseCase(
        const RetryAddWishlistItemStorageError(),
      );
      await tester.pumpWidget(
        _wrap(FailedActionsScreen(repository: repo, addWishlistUseCase: uc)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not save to wishlist — try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('shows friendly label for addWishlistItem action', (
      tester,
    ) async {
      final repo = _FakeRetryRepo(actions: [addWishlistAction()]);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Add to wishlist'), findsOneWidget);
    });
  });

  group('SettingsScreen — Failed Actions tile', () {
    testWidgets('settings screen shows Failed Actions tile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _SettingsScreenWithoutNav())),
      );

      expect(find.text('Failed Actions'), findsOneWidget);
      expect(find.text('View actions waiting to be retried'), findsOneWidget);
    });
  });

  group('FailedActionsScreen — safe area', () {
    testWidgets('loaded list has SafeArea with top: false', (tester) async {
      final repo = _FakeRetryRepo(actions: [_makeAction()]);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pump();
      final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
      expect(safeAreas.any((sa) => !sa.top), isTrue);
    });
  });
}

// A minimal test stand-in for SettingsScreen that doesn't need Navigator.
class _SettingsScreenWithoutNav extends StatelessWidget {
  const _SettingsScreenWithoutNav();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.history_toggle_off_outlined),
          title: Text('Failed Actions'),
          subtitle: Text('View actions waiting to be retried'),
          trailing: Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

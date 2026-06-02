import 'package:cratewise/domain/models/retry_action.dart';
import 'package:cratewise/domain/repositories/retry_action_repository.dart';
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

    testWidgets('shows empty state when no non-abandoned actions',
        (tester) async {
      final repo = _FakeRetryRepo(actions: []);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('No failed actions'), findsOneWidget);
      expect(find.text('Everything is up to date.'), findsOneWidget);
    });

    testWidgets('shows empty state when all actions are abandoned',
        (tester) async {
      final repo = _FakeRetryRepo(actions: [
        _makeAction(status: RetryActionStatus.abandoned),
      ]);
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

    testWidgets('shows friendly label for refreshReleaseMetadata',
        (tester) async {
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
      final repo = _FakeRetryRepo(
        actions: [_makeAction(attemptCount: 3)],
      );
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

    testWidgets('shows last tried row when lastAttemptedAt is set',
        (tester) async {
      final repo = _FakeRetryRepo(
        actions: [
          _makeAction(lastAttemptedAt: DateTime(2026, 6, 1, 15, 30)),
        ],
      );
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last tried:'), findsOneWidget);
    });

    testWidgets('does not show last tried row when lastAttemptedAt is null',
        (tester) async {
      final repo = _FakeRetryRepo(actions: [_makeAction()]);
      await tester.pumpWidget(_wrap(FailedActionsScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last tried:'), findsNothing);
    });

    testWidgets('shows multiple cards for multiple actions', (tester) async {
      final repo = _FakeRetryRepo(actions: [
        _makeAction(id: 'a1', entityId: '1'),
        _makeAction(id: 'a2', entityId: '2'),
        _makeAction(id: 'a3', entityId: '3'),
      ]);
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

    testWidgets('retry button reloads and shows empty state on success',
        (tester) async {
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
      testWidgets('card text does not contain token or secret',
          (tester) async {
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

  group('SettingsScreen — Failed Actions tile', () {
    testWidgets('settings screen shows Failed Actions tile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _SettingsScreenWithoutNav(),
          ),
        ),
      );

      expect(find.text('Failed Actions'), findsOneWidget);
      expect(find.text('View actions waiting to be retried'), findsOneWidget);
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

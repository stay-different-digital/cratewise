import 'package:cratewise/application/use_cases/execute_pending_deletions_use_case.dart';
import 'package:cratewise/domain/models/pending_discogs_deletion.dart';
import 'package:cratewise/domain/repositories/pending_discogs_deletion_repository.dart';
import 'package:cratewise/domain/repositories/token_storage.dart';
import 'package:cratewise/infrastructure/discogs/discogs_api_client.dart';
import 'package:cratewise/presentation/screens/pending_deletions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeDeletionRepository implements PendingDiscogsDeletionRepository {
  _FakeDeletionRepository(this._byType);
  final Map<DeletionEntityType, List<PendingDiscogsDeletion>> _byType;
  final List<String> removedIds = [];

  @override
  Future<void> add(PendingDiscogsDeletion deletion) async {}
  @override
  Future<List<PendingDiscogsDeletion>> getByType(
    DeletionEntityType type,
  ) async => _byType[type] ?? [];
  @override
  Future<bool> containsRelease(int id, DeletionEntityType type) async => false;
  @override
  Future<void> remove(String id) async => removedIds.add(id);
  @override
  Future<void> removeByRelease(int id, DeletionEntityType type) async {}
}

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> loadToken() async => 'tok';
  @override
  Future<String?> loadUsername() async => 'vinyl_fan';
  @override
  Future<void> saveCredentials({
    required String token,
    required String username,
  }) async {}
  @override
  Future<void> deleteCredentials() async {}
}

PendingDiscogsDeletion _collectionDeletion({String id = 'c-1'}) =>
    PendingDiscogsDeletion(
      id: id,
      entityType: DeletionEntityType.collection,
      discogsReleaseId: 100,
      discogsInstanceId: 9001,
      artist: 'Test Artist',
      title: 'Test Album',
      createdAt: DateTime(2026, 6, 1),
    );

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('shows the empty state when there is nothing to remove', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PendingDeletionsScreen(deletionRepository: _FakeDeletionRepository({})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing to remove'), findsOneWidget);
  });

  testWidgets('lists pending removals with a confirm button', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PendingDeletionsScreen(
          deletionRepository: _FakeDeletionRepository({
            DeletionEntityType.collection: [_collectionDeletion()],
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Album'), findsOneWidget);
    expect(find.text('Remove 1 from Discogs'), findsOneWidget);
  });

  testWidgets('confirming removes the tombstones and shows the summary', (
    tester,
  ) async {
    final repo = _FakeDeletionRepository({
      DeletionEntityType.collection: [_collectionDeletion()],
    });
    final useCase = ExecutePendingDeletionsUseCase(
      tokenStorage: _FakeTokenStorage(),
      apiClient: DiscogsApiClient(
        httpClient: MockClient((_) async => http.Response('', 204)),
      ),
      deletionRepository: repo,
      delay: (_) async {},
    );

    await tester.pumpWidget(
      _wrap(
        PendingDeletionsScreen(
          deletionRepository: repo,
          executeUseCase: useCase,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm-removals-button')));
    await tester.pumpAndSettle();

    expect(find.text('Removals complete'), findsOneWidget);
    expect(find.text('Removed from Discogs: 1'), findsOneWidget);
    expect(repo.removedIds, ['c-1']);
  });
}

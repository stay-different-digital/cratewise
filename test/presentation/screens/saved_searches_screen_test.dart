import 'package:cratewise/domain/models/saved_search.dart';
import 'package:cratewise/domain/repositories/saved_search_repository.dart';
import 'package:cratewise/presentation/screens/saved_searches_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements SavedSearchRepository {
  _FakeRepo({List<SavedSearch>? items}) : _items = List.of(items ?? []);

  final List<SavedSearch> _items;
  String? lastRenamedId;
  String? lastRenamedName;
  String? lastDeletedId;
  String? lastUpdatedLastUsedId;

  @override
  Future<List<SavedSearch>> getAll() async => List.of(_items);

  @override
  Future<List<SavedSearch>> getByType(SavedSearchType type) async =>
      _items.where((i) => i.type == type).toList();

  @override
  Future<void> save(SavedSearch search) async => _items.add(search);

  @override
  Future<void> updateName(String id, String name) async {
    lastRenamedId = id;
    lastRenamedName = name;
  }

  @override
  Future<void> updateLastUsed(String id, DateTime lastUsedAt) async {
    lastUpdatedLastUsedId = id;
  }

  @override
  Future<void> remove(String id) async {
    lastDeletedId = id;
    _items.removeWhere((i) => i.id == id);
  }
}

SavedSearch _search({
  String id = '1',
  String name = 'Test search',
  SavedSearchType type = SavedSearchType.discogsSearch,
  String payload = '{"query":"test","filter":"all","schemaVersion":1}',
}) => SavedSearch(
  id: id,
  name: name,
  type: type,
  payloadJson: payload,
  schemaVersion: 1,
  createdAt: DateTime(2026, 1, 1),
  lastUsedAt: DateTime(2026, 6, 1),
);

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('SavedSearchesScreen', () {
    testWidgets('shows empty state when no saved searches', (tester) async {
      await tester.pumpWidget(
        _wrap(SavedSearchesScreen(repository: _FakeRepo())),
      );
      await tester.pumpAndSettle();
      expect(find.text('No saved searches yet'), findsOneWidget);
    });

    testWidgets('shows list of saved searches', (tester) async {
      final repo = _FakeRepo(
        items: [
          _search(id: '1', name: 'My search'),
          _search(id: '2', name: 'Another search'),
        ],
      );
      await tester.pumpWidget(_wrap(SavedSearchesScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('My search'), findsOneWidget);
      expect(find.text('Another search'), findsOneWidget);
    });

    testWidgets('filters by type when filterType set', (tester) async {
      final repo = _FakeRepo(
        items: [
          _search(
            id: '1',
            name: 'Discogs',
            type: SavedSearchType.discogsSearch,
          ),
          _search(
            id: '2',
            name: 'Collection filter',
            type: SavedSearchType.collectionFilter,
            payload:
                '{"schemaVersion":1,"decades":[],"formats":[],"labels":[],'
                '"genres":[],"styles":[],"mediaConditions":[],"sleeveConditions":[],'
                '"tags":[],"storageLocation":null,"syncStatuses":[],"hasCover":null}',
          ),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          SavedSearchesScreen(
            repository: repo,
            filterType: SavedSearchType.discogsSearch,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Discogs'), findsOneWidget);
      expect(find.text('Collection filter'), findsNothing);
    });

    testWidgets('delete removes item via swipe', (tester) async {
      final item = _search(id: '42', name: 'To delete');
      final repo = _FakeRepo(items: [item]);
      await tester.pumpWidget(_wrap(SavedSearchesScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.drag(find.text('To delete'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(repo.lastDeletedId, '42');
    });

    testWidgets('rename updates name via menu', (tester) async {
      final item = _search(id: '7', name: 'Old name');
      final repo = _FakeRepo(items: [item]);
      await tester.pumpWidget(_wrap(SavedSearchesScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastRenamedId, '7');
      expect(repo.lastRenamedName, 'New name');
    });

    testWidgets('tapping item pops with the SavedSearch', (tester) async {
      SavedSearch? returned;
      final item = _search(id: '5', name: 'My filter');
      final repo = _FakeRepo(items: [item]);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                returned = await Navigator.of(ctx).push<SavedSearch>(
                  MaterialPageRoute(
                    builder: (_) => SavedSearchesScreen(repository: repo),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My filter'));
      await tester.pumpAndSettle();

      expect(returned?.id, '5');
    });
  });
}

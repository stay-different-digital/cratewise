import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/presentation/screens/collection_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCollectionRepository implements CollectionRepository {
  _FakeCollectionRepository({
    this.item,
    this.throwsOnLoad = false,
    this.throwsOnUpdate = false,
  });

  final CollectionItem? item;
  final bool throwsOnLoad;
  final bool throwsOnUpdate;
  int loadCallCount = 0;
  int updateCallCount = 0;
  CollectionItem? lastUpdatedItem;

  @override
  Future<CollectionItem?> getById(String id) async {
    loadCallCount++;
    if (throwsOnLoad) throw Exception('db error');
    return item;
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {
    updateCallCount++;
    lastUpdatedItem = item;
    if (throwsOnUpdate) throw Exception('update error');
  }

  @override
  Future<void> remove(String id) async {}
}

class _FlippingCollectionRepository implements CollectionRepository {
  _FlippingCollectionRepository({required this.successItem});

  final CollectionItem successItem;
  int _callCount = 0;

  @override
  Future<CollectionItem?> getById(String id) async {
    _callCount++;
    if (_callCount == 1) throw Exception('first load fails');
    return successItem;
  }

  @override
  Future<List<CollectionItem>> getAll() async => [];
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _makeItem({
  String id = 'test-1',
  String artist = 'Test Artist',
  String title = 'Test Album',
  String? label,
  String? catno,
  String? format,
  String? country,
  int? year,
  String? notes,
  List<String> tags = const [],
  String? storageLocation,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => CollectionItem(
      id: id,
      discogsReleaseId: 1,
      artist: artist,
      title: title,
      label: label,
      catno: catno,
      format: format,
      country: country,
      year: year,
      coverUrl: null,
      notes: notes,
      mediaCondition: RecordCondition.veryGood,
      sleeveCondition: RecordCondition.nearMint,
      tags: tags,
      storageLocation: storageLocation,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 3, 15),
    );

Widget _wrap(Widget child) => MaterialApp(home: child);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionDetailScreen — loading state', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides loading indicator after load completes', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('CollectionDetailScreen — loaded state', () {
    testWidgets('shows item title in app bar', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(title: 'Kind of Blue'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kind of Blue'), findsWidgets);
    });

    testWidgets('shows artist', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(artist: 'Miles Davis'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('shows media condition', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(RecordCondition.veryGood.label),
        findsOneWidget,
      );
    });

    testWidgets('shows sleeve condition', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(RecordCondition.nearMint.label),
        findsOneWidget,
      );
    });

    testWidgets('shows label when provided', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(label: 'Blue Note'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Blue Note'), findsOneWidget);
    });

    testWidgets('shows catno when provided without label', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(catno: 'BN 1577'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('BN 1577'), findsOneWidget);
    });

    testWidgets('combines label and catno with separator', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(label: 'Blue Note', catno: 'BN 1577'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Blue Note — BN 1577'), findsOneWidget);
    });

    testWidgets('shows format when provided', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(format: 'LP'));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('LP'), findsOneWidget);
    });

    testWidgets('shows country when provided', (tester) async {
      final repo =
          _FakeCollectionRepository(item: _makeItem(country: 'US'));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('US'), findsOneWidget);
    });

    testWidgets('shows year when provided', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(year: 1959));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1959'), findsOneWidget);
    });

    testWidgets('shows notes section when notes is present', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(notes: 'Original pressing. Excellent.'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original pressing. Excellent.'), findsOneWidget);
    });

    testWidgets('does not show notes section when notes is null',
        (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(notes: null));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('shows tags when provided', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(tags: ['jazz', 'essential']),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('jazz'), findsOneWidget);
      expect(find.text('essential'), findsOneWidget);
    });

    testWidgets('does not show tags section when tags list is empty',
        (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem(tags: []));
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tags'), findsNothing);
    });

    testWidgets('shows storage location when provided', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(storageLocation: 'Shelf B3'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Shelf B3'), findsOneWidget);
    });

    testWidgets('shows created date', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(createdAt: DateTime(2026, 1, 5)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-01-05'), findsOneWidget);
    });

    testWidgets('shows updated date', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2026, 6, 20)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-06-20'), findsOneWidget);
    });

    testWidgets('renders without error when all optional fields are null',
        (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(
          label: null,
          catno: null,
          format: null,
          country: null,
          year: null,
          notes: null,
          tags: [],
          storageLocation: null,
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item not found.'), findsNothing);
      expect(find.textContaining('Could not load'), findsNothing);
    });
  });

  group('CollectionDetailScreen — not found state', () {
    testWidgets('shows not found message when item does not exist',
        (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(itemId: 'nonexistent-id', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item not found.'), findsOneWidget);
    });

    testWidgets('shows descriptive not found body text', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(itemId: 'nonexistent-id', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('may have been removed'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — error state', () {
    testWidgets('shows error message when load fails', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not load'), findsOneWidget);
    });

    testWidgets('shows Retry button in error state', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry calls getById again', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repo.loadCallCount, 2);
    });

    testWidgets('retry can recover to loaded state', (tester) async {
      final repo = _FlippingCollectionRepository(
        successItem: _makeItem(artist: 'Recovered Artist'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered Artist'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('CollectionDetailScreen — wide layout', () {
    testWidgets('renders without error at wide breakpoint', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeCollectionRepository(
        item: _makeItem(
          artist: 'Miles Davis',
          title: 'Kind of Blue',
          label: 'Columbia',
          notes: 'A classic.',
          tags: ['jazz'],
        ),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Miles Davis'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — edit conditions', () {
    testWidgets('shows edit button when loaded', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('edit-conditions-button')),
        findsOneWidget,
      );
    });

    testWidgets('does not show edit button while loading', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byKey(const Key('edit-conditions-button')), findsNothing);
    });

    testWidgets('does not show edit button in not-found state', (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(itemId: 'nonexistent', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-conditions-button')), findsNothing);
    });

    testWidgets('does not show edit button in error state', (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-conditions-button')), findsNothing);
    });

    testWidgets('tapping edit button opens sheet with title', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Conditions'), findsOneWidget);
    });

    testWidgets('sheet shows Save button', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-conditions-button')), findsOneWidget);
    });

    testWidgets('tapping Save calls repository.update', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
    });

    testWidgets('shows success snackbar after save', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.text('Conditions saved.'), findsOneWidget);
    });

    testWidgets('save updates updatedAt shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2026, 2, 15)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2026-02-15'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('2026-02-15'), findsNothing);
    });

    testWidgets('save error shows error message in sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
    });

    testWidgets('save error does not close sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-conditions-button')), findsOneWidget);
    });

    testWidgets(
        'changing media condition and saving updates displayed value',
        (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-conditions-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('media-condition-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(RecordCondition.mint.label).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-conditions-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining(RecordCondition.mint.label), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — edit tags', () {
    testWidgets('shows edit tags button when loaded', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-tags-button')), findsOneWidget);
    });

    testWidgets('does not show edit tags button while loading', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byKey(const Key('edit-tags-button')), findsNothing);
    });

    testWidgets('does not show edit tags button in not-found state',
        (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(itemId: 'nonexistent', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-tags-button')), findsNothing);
    });

    testWidgets('does not show edit tags button in error state',
        (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-tags-button')), findsNothing);
    });

    testWidgets('tapping edit tags button opens sheet with title',
        (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Tags'), findsOneWidget);
    });

    testWidgets('sheet shows existing tags as chips', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(tags: ['jazz', 'essential']),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tag-chip-jazz')), findsOneWidget);
      expect(find.byKey(const Key('tag-chip-essential')), findsOneWidget);
    });

    testWidgets('can add a tag', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('tag-input-field')),
        'soul',
      );
      await tester.tap(find.byKey(const Key('add-tag-button')));
      await tester.pump();

      expect(find.byKey(const Key('tag-chip-soul')), findsOneWidget);
    });

    testWidgets('can remove a tag', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(tags: ['jazz']),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('tag-chip-jazz')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('tag-chip-jazz')), findsNothing);
    });

    testWidgets('does not add empty tag', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-tag-button')));
      await tester.pump();

      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('does not add duplicate tag (case-insensitive)', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(tags: ['jazz']),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('tag-input-field')),
        'Jazz',
      );
      await tester.tap(find.byKey(const Key('add-tag-button')));
      await tester.pump();

      expect(find.byType(InputChip), findsOneWidget);
    });

    testWidgets('tapping Save calls repository.update', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
    });

    testWidgets('shows success snackbar after save', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.text('Tags saved.'), findsOneWidget);
    });

    testWidgets('save updates tags shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(tags: ['jazz']),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('tag-input-field')),
        'soul',
      );
      await tester.tap(find.byKey(const Key('add-tag-button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.text('soul'), findsOneWidget);
    });

    testWidgets('save updates updatedAt shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2025, 11, 5)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2025-11-05'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('2025-11-05'), findsNothing);
    });

    testWidgets('save error shows error message in sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
    });

    testWidgets('save error does not close sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-tags-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-tags-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-tags-button')), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — edit notes', () {
    testWidgets('shows edit notes button when loaded', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-notes-button')), findsOneWidget);
    });

    testWidgets('does not show edit notes button while loading', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      expect(find.byKey(const Key('edit-notes-button')), findsNothing);
    });

    testWidgets('does not show edit notes button in not-found state',
        (tester) async {
      final repo = _FakeCollectionRepository();
      await tester.pumpWidget(
        _wrap(
          CollectionDetailScreen(itemId: 'nonexistent', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-notes-button')), findsNothing);
    });

    testWidgets('does not show edit notes button in error state',
        (tester) async {
      final repo = _FakeCollectionRepository(throwsOnLoad: true);
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-notes-button')), findsNothing);
    });

    testWidgets('tapping edit notes button opens sheet with title',
        (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Notes'), findsOneWidget);
    });

    testWidgets('sheet shows Save button', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-notes-button')), findsOneWidget);
    });

    testWidgets('sheet pre-fills existing notes', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(notes: 'Existing note text'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('notes-text-field')),
          matching: find.text('Existing note text'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Save calls repository.update', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
    });

    testWidgets('shows success snackbar after save', (tester) async {
      final repo = _FakeCollectionRepository(item: _makeItem());
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.text('Notes saved.'), findsOneWidget);
    });

    testWidgets('save updates notes shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(notes: 'Old note text'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old note text'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('notes-text-field')),
        'New note text',
      );
      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.text('New note text'), findsOneWidget);
      expect(find.text('Old note text'), findsNothing);
    });

    testWidgets('save updates updatedAt shown on screen', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(updatedAt: DateTime(2025, 12, 10)),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2025-12-10'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('2025-12-10'), findsNothing);
    });

    testWidgets('clearing notes hides the notes section', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(notes: 'Some note'),
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('notes-text-field')), '');
      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('save error shows error message in sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
    });

    testWidgets('save error does not close sheet', (tester) async {
      final repo = _FakeCollectionRepository(
        item: _makeItem(),
        throwsOnUpdate: true,
      );
      await tester.pumpWidget(
        _wrap(CollectionDetailScreen(itemId: 'test-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-notes-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-notes-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-notes-button')), findsOneWidget);
    });
  });
}

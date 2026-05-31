import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/presentation/screens/collection_screen.dart';
import 'package:cratewise/presentation/widgets/collection_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _makeItem({
  String id = 'test-1',
  int releaseId = 1,
  String artist = 'Test Artist',
  String title = 'Test Album',
  String? label,
  int? year,
  String? format,
  String? storageLocation,
}) =>
    CollectionItem(
      id: id,
      discogsReleaseId: releaseId,
      artist: artist,
      title: title,
      label: label,
      format: format,
      year: year,
      coverUrl: null,
      mediaCondition: RecordCondition.veryGood,
      sleeveCondition: RecordCondition.veryGood,
      tags: const [],
      storageLocation: storageLocation,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CollectionScreen — empty state', () {
    testWidgets('shows empty state title when items list is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen(items: [])));
      expect(find.text('Your collection is empty'), findsOneWidget);
    });

    testWidgets('shows descriptive empty state body text', (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen(items: [])));
      expect(
        find.textContaining('Search for a release'),
        findsOneWidget,
      );
    });

    testWidgets('does not show any CollectionItemCard when empty',
        (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen(items: [])));
      expect(find.byType(CollectionItemCard), findsNothing);
    });
  });

  group('CollectionScreen — list', () {
    testWidgets('shows one card per item', (tester) async {
      final items = [
        _makeItem(id: 'a'),
        _makeItem(id: 'b'),
        _makeItem(id: 'c'),
      ];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.byType(CollectionItemCard), findsNWidgets(3));
    });

    testWidgets('shows artist name', (tester) async {
      final items = [_makeItem(artist: 'Miles Davis')];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.text('Miles Davis'), findsOneWidget);
    });

    testWidgets('shows title', (tester) async {
      final items = [_makeItem(title: 'Kind of Blue')];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.text('Kind of Blue'), findsOneWidget);
    });

    testWidgets('does not show empty state text when items present',
        (tester) async {
      final items = [_makeItem()];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.text('Your collection is empty'), findsNothing);
    });
  });

  group('CollectionScreen — default fake data', () {
    testWidgets('shows items when no items param provided', (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen()));
      expect(find.byType(CollectionItemCard), findsWidgets);
    });

    testWidgets('does not show empty state by default', (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen()));
      expect(find.text('Your collection is empty'), findsNothing);
    });
  });

  group('CollectionScreen — search field', () {
    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen(items: [])));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('clear button hidden when search is empty', (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen(items: [])));
      expect(find.byTooltip('Clear search'), findsNothing);
    });

    testWidgets('clear button appears after typing', (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen(items: [])));
      await tester.enterText(find.byType(TextField), 'jazz');
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsOneWidget);
    });

    testWidgets('clear button hides after tapping clear', (tester) async {
      await tester.pumpWidget(_wrap(const CollectionScreen(items: [])));
      await tester.enterText(find.byType(TextField), 'jazz');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });

  group('CollectionItemCard — optional fields', () {
    testWidgets('shows label when provided', (tester) async {
      final items = [_makeItem(label: 'Blue Note')];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.textContaining('Blue Note'), findsOneWidget);
    });

    testWidgets('shows year when provided', (tester) async {
      final items = [_makeItem(year: 1959)];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.textContaining('1959'), findsOneWidget);
    });

    testWidgets('shows format when provided', (tester) async {
      final items = [_makeItem(format: 'LP')];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.textContaining('LP'), findsOneWidget);
    });

    testWidgets('shows storage location when provided', (tester) async {
      final items = [_makeItem(storageLocation: 'Shelf B3')];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.textContaining('Shelf B3'), findsOneWidget);
    });

    testWidgets('does not show meta row when all optional fields are null',
        (tester) async {
      final items = [
        _makeItem(label: null, year: null, format: null, storageLocation: null),
      ];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      // Card should render without error; just no meta text
      expect(find.byType(CollectionItemCard), findsOneWidget);
    });

    testWidgets('joins label, year, and format with separator', (tester) async {
      final items = [_makeItem(label: 'Columbia', year: 1959, format: 'LP')];
      await tester.pumpWidget(_wrap(CollectionScreen(items: items)));
      expect(find.text('Columbia · 1959 · LP'), findsOneWidget);
    });
  });
}

import 'package:cratewise/presentation/screens/collection_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('CollectionDetailScreen', () {
    testWidgets('shows the item id', (tester) async {
      await tester.pumpWidget(
        _wrap(const CollectionDetailScreen(itemId: 'abc-123')),
      );
      expect(find.text('abc-123'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(
        _wrap(const CollectionDetailScreen(itemId: 'any-id')),
      );
      expect(find.text('Collection Item'), findsOneWidget);
    });

    testWidgets('different item ids are shown correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(const CollectionDetailScreen(itemId: 'xyz-999')),
      );
      expect(find.text('xyz-999'), findsOneWidget);
      expect(find.text('abc-123'), findsNothing);
    });
  });
}

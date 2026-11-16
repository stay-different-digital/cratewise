import 'package:cratewise/domain/models/wishlist_filter_set.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/presentation/widgets/wishlist_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WishlistItem _item(String id, String format) => WishlistItem(
  id: id,
  discogsReleaseId: id.hashCode,
  artist: 'A',
  title: 'T $id',
  priority: WishlistPriority.medium,
  format: format,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  testWidgets('Format shows one chip per type and "Vinyl" hides a File-only '
      'item (US-147)', (tester) async {
    final items = [
      _item('v', 'Vinyl, 12", 33 ⅓ RPM'),
      _item('f', 'File, MP3, 320 kbps'),
    ];
    late Future<WishlistFilterSet?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => result = showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => WishlistFilterSheet(
                    current: const WishlistFilterSet(),
                    items: items,
                    metadata: const [],
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Vinyl'),
      100,
      scrollable: scrollable,
    );
    expect(find.text('File'), findsOneWidget);
    expect(find.textContaining('33 ⅓ RPM'), findsNothing);
    await tester.tap(find.text('Vinyl'));
    await tester.pump();

    final apply = find.byKey(const Key('apply-filter-button'));
    await tester.scrollUntilVisible(apply, 100, scrollable: scrollable);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    final filter = (await result)!;
    expect(filter.formats, {'Vinyl'});
    expect(filter.apply(items).map((i) => i.id), ['v']);
  });
}

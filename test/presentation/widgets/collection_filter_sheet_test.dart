import 'package:cratewise/domain/models/collection_filter_set.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/presentation/widgets/collection_filter_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CollectionItem _item({String id = '1', String? format}) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: 'A',
  title: 'T',
  format: format,
  mediaCondition: RecordCondition.veryGood,
  sleeveCondition: RecordCondition.veryGood,
  tags: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late Future<CollectionFilterSet?> result;

  Future<void> openSheet(
    WidgetTester tester,
    List<CollectionItem> items, {
    CollectionFilterSet current = const CollectionFilterSet(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  result = showModalBottomSheet<CollectionFilterSet>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CollectionFilterSheet(
                      current: current,
                      items: items,
                      metadata: const [],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> scrollSheetTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<CollectionFilterSet> apply(WidgetTester tester) async {
    await scrollSheetTo(tester, find.byKey(const Key('apply-filter-button')));
    await tester.tap(find.byKey(const Key('apply-filter-button')));
    await tester.pumpAndSettle();
    return (await result)!;
  }

  testWidgets('Format shows one chip per type; Vinyl lands in the filter '
      '(US-143)', (tester) async {
    await openSheet(tester, [
      _item(id: '1', format: 'Vinyl, 12", 33 ⅓ RPM'),
      _item(id: '2', format: 'Vinyl, LP, Album'),
      _item(id: '3', format: 'File, MP3, 320 kbps'),
      _item(id: '4', format: 'Vinyl, LP\nCD, Album'),
    ]);
    await scrollSheetTo(tester, find.text('Vinyl'));

    expect(find.text('Vinyl'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('CD'), findsOneWidget);
    expect(find.textContaining('33 ⅓ RPM'), findsNothing);

    await tester.tap(find.text('Vinyl'));
    await tester.pump();
    final filter = await apply(tester);
    expect(filter.formats, {'Vinyl'});
  });

  // US-165: the DJ fields are gone from the app, so are their filters.
  testWidgets('no BPM, Key, Energy or Gig crate sections', (tester) async {
    await openSheet(tester, [_item(format: 'Vinyl, LP')]);

    for (final title in ['BPM', 'Key', 'Energy', 'Gig crate']) {
      expect(find.text(title), findsNothing);
    }
    expect(find.byKey(const Key('bpm-min-field')), findsNothing);
  });
}

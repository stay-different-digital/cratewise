import 'package:cratewise/domain/models/collection_filter_set.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/presentation/widgets/collection_filter_sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _item({
  String id = '1',
  String? format,
  int? bpm,
  MusicalKey? musicalKey,
  int? energyLevel,
  List<String> gigCrates = const [],
}) => CollectionItem(
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
  bpm: bpm,
  musicalKey: musicalKey,
  energyLevel: energyLevel,
  gigCrates: gigCrates,
);

void main() {
  group('CollectionFilterSheet — DJ sections (US-121)', () {
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

    testWidgets('DJ sections hidden when no item has DJ data', (tester) async {
      await openSheet(tester, [_item()]);
      expect(find.text('BPM'), findsNothing);
      expect(find.text('Key'), findsNothing);
      expect(find.text('Energy'), findsNothing);
      expect(find.text('Gig crate'), findsNothing);
    });

    testWidgets('gig crate chip selection lands in the applied filter', (
      tester,
    ) async {
      await openSheet(tester, [
        _item(id: '1', gigCrates: ['Warmup']),
        _item(id: '2', gigCrates: ['Techno Night']),
      ]);
      await scrollSheetTo(tester, find.text('Warmup'));
      await tester.tap(find.text('Warmup'));
      await tester.pump();

      final filter = await apply(tester);
      expect(filter.gigCrates, {'Warmup'});
    });

    testWidgets('key and energy chips land in the applied filter', (
      tester,
    ) async {
      await openSheet(tester, [
        _item(id: '1', musicalKey: MusicalKey.aMinor, energyLevel: 4),
        _item(id: '2', musicalKey: MusicalKey.cMajor, energyLevel: 2),
      ]);
      await scrollSheetTo(tester, find.text('A minor'));
      await tester.tap(find.text('A minor'));
      await scrollSheetTo(tester, find.text('4'));
      await tester.tap(find.text('4'));
      await tester.pump();

      final filter = await apply(tester);
      expect(filter.musicalKeys, {MusicalKey.aMinor});
      expect(filter.energyLevels, {4});
    });

    testWidgets('BPM min/max fields land in the applied filter', (
      tester,
    ) async {
      await openSheet(tester, [_item(id: '1', bpm: 128)]);
      await scrollSheetTo(tester, find.byKey(const Key('bpm-min-field')));
      await tester.enterText(find.byKey(const Key('bpm-min-field')), '120');
      await tester.enterText(find.byKey(const Key('bpm-max-field')), '130');

      final filter = await apply(tester);
      expect(filter.bpmMin, 120);
      expect(filter.bpmMax, 130);
    });

    testWidgets('current DJ filter values are pre-selected', (tester) async {
      await openSheet(
        tester,
        [
          _item(id: '1', bpm: 128, gigCrates: ['Warmup']),
        ],
        current: const CollectionFilterSet(bpmMin: 100, gigCrates: {'Warmup'}),
      );
      await scrollSheetTo(tester, find.byKey(const Key('bpm-min-field')));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('bpm-min-field')))
            .controller!
            .text,
        '100',
      );

      final filter = await apply(tester);
      expect(filter.bpmMin, 100);
      expect(filter.gigCrates, {'Warmup'});
    });

    testWidgets('Clear all resets the DJ sections', (tester) async {
      await openSheet(
        tester,
        [_item(id: '1', bpm: 128, musicalKey: MusicalKey.aMinor)],
        current: const CollectionFilterSet(
          bpmMin: 100,
          bpmMax: 130,
          musicalKeys: {MusicalKey.aMinor},
        ),
      );
      await tester.tap(find.byKey(const Key('clear-all-button')));
      await tester.pump();

      final filter = await apply(tester);
      expect(filter.isEmpty, isTrue);
    });
  });
}

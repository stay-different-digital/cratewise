import 'package:cratewise/domain/models/release_search_result.dart';
import 'package:cratewise/presentation/widgets/release_search_result_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _kindOfBlue = ReleaseSearchResult(
  id: 249504,
  title: 'Kind Of Blue',
  artist: 'Miles Davis',
  format: 'Vinyl',
  label: 'Columbia',
  country: 'US',
  year: 1959,
);

const _noYearNoCountry = ReleaseSearchResult(
  id: 1,
  title: 'Unknown Press',
  artist: 'Various',
  format: 'Vinyl',
  label: 'Promo',
  country: '',
  year: null,
);

Widget _wrap({bool inCollection = false, bool onWishlist = false}) {
  return MaterialApp(
    home: Scaffold(
      body: ReleaseSearchResultCard(
        result: _kindOfBlue,
        inCollection: inCollection,
        onWishlist: onWishlist,
      ),
    ),
  );
}

void main() {
  group('ReleaseSearchResultCard meta field order (US-100)', () {
    testWidgets('shows label · year · format on a single meta row', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Columbia · 1959 · Vinyl'), findsOneWidget);
    });

    testWidgets('omits year from meta row when year is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReleaseSearchResultCard(result: _noYearNoCountry),
          ),
        ),
      );
      expect(find.text('Promo · Vinyl'), findsOneWidget);
    });

    testWidgets('shows country on a separate row when non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('US'), findsOneWidget);
    });

    testWidgets('omits country row when country is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReleaseSearchResultCard(result: _noYearNoCountry),
          ),
        ),
      );
      expect(find.text(''), findsNothing);
    });
  });

  group('ReleaseSearchResultCard membership icons (US-80)', () {
    testWidgets('shows the collection icon when in collection only', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(inCollection: true));
      expect(find.byKey(const Key('in-collection-icon')), findsOneWidget);
      expect(find.byKey(const Key('on-wishlist-icon')), findsNothing);
    });

    testWidgets('shows the wishlist icon when on wishlist only', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(onWishlist: true));
      expect(find.byKey(const Key('on-wishlist-icon')), findsOneWidget);
      expect(find.byKey(const Key('in-collection-icon')), findsNothing);
    });

    testWidgets('shows both icons when in collection and on wishlist', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(inCollection: true, onWishlist: true));
      expect(find.byKey(const Key('in-collection-icon')), findsOneWidget);
      expect(find.byKey(const Key('on-wishlist-icon')), findsOneWidget);
    });

    testWidgets('shows no membership icons when in neither', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byKey(const Key('in-collection-icon')), findsNothing);
      expect(find.byKey(const Key('on-wishlist-icon')), findsNothing);
    });

    testWidgets('exposes membership state to screen readers via semantics', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(inCollection: true, onWishlist: true));
      final collectionIcon = tester.widget<Icon>(
        find.byKey(const Key('in-collection-icon')),
      );
      final wishlistIcon = tester.widget<Icon>(
        find.byKey(const Key('on-wishlist-icon')),
      );
      expect(collectionIcon.semanticLabel, 'In your collection');
      expect(wishlistIcon.semanticLabel, 'On your wishlist');
    });

    testWidgets('renders a tooltip for each membership icon', (tester) async {
      await tester.pumpWidget(_wrap(inCollection: true, onWishlist: true));
      expect(find.byTooltip('In your collection'), findsOneWidget);
      expect(find.byTooltip('On your wishlist'), findsOneWidget);
    });
  });
}

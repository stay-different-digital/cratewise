import 'package:cratewise/presentation/widgets/release_image_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ReleaseImageGallery (US-103)', () {
    testWidgets('shows placeholder when imageUrls is empty and no local path', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ReleaseImageGallery()));
      expect(find.byKey(const Key('release-cover-image')), findsNothing);
      expect(find.byIcon(Icons.album), findsOneWidget);
    });

    testWidgets('shows single image without dots for one URL', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ReleaseImageGallery(
            imageUrls: ['https://example.com/cover.jpg'],
          ),
        ),
      );
      expect(find.byKey(const Key('release-cover-image')), findsOneWidget);
      // No PageView — single image path
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('shows PageView with dots for two or more URLs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ReleaseImageGallery(
            imageUrls: [
              'https://example.com/cover.jpg',
              'https://example.com/label.jpg',
            ],
          ),
        ),
      );
      expect(find.byType(PageView), findsOneWidget);
      // Two dot containers rendered
      expect(find.byKey(const Key('release-cover-image')), findsOneWidget);
    });

    testWidgets('dot count matches imageUrls length', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ReleaseImageGallery(
            imageUrls: [
              'https://example.com/a.jpg',
              'https://example.com/b.jpg',
              'https://example.com/c.jpg',
            ],
          ),
        ),
      );
      // 3 AnimatedContainers inside _DotsIndicator
      final pageView = find.byType(PageView);
      expect(pageView, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('semantics label contains image index and total', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ReleaseImageGallery(
            imageUrls: [
              'https://example.com/a.jpg',
              'https://example.com/b.jpg',
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Image 1 of 2'), findsOneWidget);
    });
  });
}

import 'package:cratewise/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Cratewise app renders the starter shell', (tester) async {
    await tester.pumpWidget(const CratewiseApp());

    expect(find.text('Cratewise'), findsOneWidget);
    expect(find.text('Search Discogs'), findsOneWidget);
    expect(find.byIcon(Icons.album_outlined), findsOneWidget);
  });
}

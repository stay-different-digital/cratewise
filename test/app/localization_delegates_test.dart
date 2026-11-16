import 'package:cratewise/app/localization_delegates.dart';
import 'package:cratewise/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // With material_ui, Material widgets read material_ui's MaterialLocalizations;
  // the old flutter_localizations delegates would leave them untranslated.
  testWidgets('Dutch locale translates app and Material strings', (
    tester,
  ) async {
    late MaterialLocalizations material;
    late AppLocalizations app;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nl'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: Builder(
          builder: (context) {
            material = MaterialLocalizations.of(context);
            app = AppLocalizations.of(context)!;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(material.backButtonTooltip, 'Terug');
    expect(app.navStatistics, 'Statistieken');
  });
}

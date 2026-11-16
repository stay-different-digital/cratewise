import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// Localization delegates for the app: Cratewise's own strings plus the
/// Material, Cupertino and Widgets translations from `material_ui`.
///
/// Use this instead of the generated `AppLocalizations.localizationsDelegates`:
/// `flutter gen-l10n` (Flutter 3.50) still fills that list with the deprecated
/// `flutter_localizations` delegates, which provide the *old* framework's
/// MaterialLocalizations type. `material_ui` widgets look up their own type,
/// so with the old delegates non-English locales would lose translated
/// tooltips and dialog labels.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

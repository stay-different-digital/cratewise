import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('nl'),
  ];

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get navCollection;

  /// No description provided for @navWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get navWishlist;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Artist, album, or label…'**
  String get searchHint;

  /// No description provided for @searchClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearTooltip;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Discogs'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Type an artist, album, or label name to search.'**
  String get searchEmptyBody;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term.'**
  String get searchNoResultsBody;

  /// No description provided for @searchSelectResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a result'**
  String get searchSelectResultTitle;

  /// No description provided for @searchSelectResultBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a search result to view its details.'**
  String get searchSelectResultBody;

  /// No description provided for @searchFilterRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get searchFilterRelease;

  /// No description provided for @searchFilterArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get searchFilterArtist;

  /// No description provided for @searchFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get searchFilterLabel;

  /// No description provided for @cachedResultsBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing saved results'**
  String get cachedResultsBanner;

  /// No description provided for @collectionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your collection…'**
  String get collectionSearchHint;

  /// No description provided for @collectionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your collection is empty'**
  String get collectionEmptyTitle;

  /// No description provided for @collectionOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Your collection is saved on this device and works without internet.'**
  String get collectionOfflineNote;

  /// No description provided for @collectionNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String collectionNoResultsTitle(String query);

  /// No description provided for @collectionNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different artist or title.'**
  String get collectionNoResultsBody;

  /// No description provided for @wishlistSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your wishlist…'**
  String get wishlistSearchHint;

  /// No description provided for @wishlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmptyTitle;

  /// No description provided for @wishlistOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is saved on this device and works without internet.'**
  String get wishlistOfflineNote;

  /// No description provided for @wishlistNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String wishlistNoResultsTitle(String query);

  /// No description provided for @wishlistNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different artist or title.'**
  String get wishlistNoResultsBody;

  /// No description provided for @addViaSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Use the Search tab to find releases and add them.'**
  String get addViaSearchHint;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get calculating;

  /// No description provided for @settingsImportExport.
  ///
  /// In en, this message translates to:
  /// **'Import & Export'**
  String get settingsImportExport;

  /// No description provided for @settingsImportExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move records to and from Discogs or CSV files'**
  String get settingsImportExportSubtitle;

  /// No description provided for @settingsFailedActions.
  ///
  /// In en, this message translates to:
  /// **'Failed Actions'**
  String get settingsFailedActions;

  /// No description provided for @settingsFailedActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View actions waiting to be retried'**
  String get settingsFailedActionsSubtitle;

  /// No description provided for @settingsThumbnailCache.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail Cache'**
  String get settingsThumbnailCache;

  /// No description provided for @settingsLocalData.
  ///
  /// In en, this message translates to:
  /// **'Local data'**
  String get settingsLocalData;

  /// No description provided for @settingsClearCollection.
  ///
  /// In en, this message translates to:
  /// **'Clear collection'**
  String get settingsClearCollection;

  /// No description provided for @settingsClearWishlist.
  ///
  /// In en, this message translates to:
  /// **'Clear wishlist'**
  String get settingsClearWishlist;

  /// No description provided for @settingsTourRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart tour'**
  String get settingsTourRestart;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @barcodeEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode manually…'**
  String get barcodeEnterManually;

  /// No description provided for @barcodeScanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get barcodeScanButton;

  /// No description provided for @barcodeSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get barcodeSearchButton;

  /// No description provided for @barcodeScanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Scan barcode\' to open your camera'**
  String get barcodeScanPrompt;

  /// No description provided for @barcodePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get barcodePermissionDenied;

  /// No description provided for @barcodePermissionDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in Settings to scan barcodes.'**
  String get barcodePermissionDeniedHint;

  /// No description provided for @barcodeScanOrEnter.
  ///
  /// In en, this message translates to:
  /// **'Scan or enter a barcode'**
  String get barcodeScanOrEnter;

  /// No description provided for @barcodeScanOrEnterHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a barcode or type one above.'**
  String get barcodeScanOrEnterHint;

  /// No description provided for @barcodeNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No releases found'**
  String get barcodeNoReleases;

  /// No description provided for @barcodeNoReleasesHint.
  ///
  /// In en, this message translates to:
  /// **'No Discogs releases match this barcode. Try a different barcode or check the number.'**
  String get barcodeNoReleasesHint;

  /// No description provided for @barcodeNoToken.
  ///
  /// In en, this message translates to:
  /// **'Discogs account not connected'**
  String get barcodeNoToken;

  /// No description provided for @barcodeNoTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings to connect your Discogs account.'**
  String get barcodeNoTokenHint;

  /// No description provided for @barcodeRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get barcodeRateLimited;

  /// No description provided for @barcodeRateLimitedHint.
  ///
  /// In en, this message translates to:
  /// **'Discogs is limiting requests right now. Wait a moment and try again.'**
  String get barcodeRateLimitedHint;

  /// No description provided for @barcodeSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get barcodeSomethingWrong;

  /// No description provided for @barcodeSomethingWrongHint.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Discogs. An internet connection is needed for barcode lookups.'**
  String get barcodeSomethingWrongHint;

  /// No description provided for @barcodeValidationNotBarcode.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like a barcode'**
  String get barcodeValidationNotBarcode;

  /// No description provided for @barcodeValidationWrongLength.
  ///
  /// In en, this message translates to:
  /// **'Barcode must be 8, 12, or 13 digits'**
  String get barcodeValidationWrongLength;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

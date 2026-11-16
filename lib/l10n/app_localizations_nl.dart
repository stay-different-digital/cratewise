// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get navSearch => 'Zoeken';

  @override
  String get navCollection => 'Collectie';

  @override
  String get navWishlist => 'Verlanglijst';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get searchHint => 'Artiest, album of label…';

  @override
  String get searchClearTooltip => 'Zoekopdracht wissen';

  @override
  String get searchEmptyTitle => 'Zoek op Discogs';

  @override
  String get searchEmptyBody =>
      'Typ een artiest-, album- of labelnaam om te zoeken.';

  @override
  String get searchNoResultsTitle => 'Geen resultaten';

  @override
  String get searchNoResultsBody => 'Probeer een andere zoekterm.';

  @override
  String get searchSelectResultTitle => 'Selecteer een resultaat';

  @override
  String get searchSelectResultBody =>
      'Tik op een zoekresultaat om de details te bekijken.';

  @override
  String get searchFilterRelease => 'Release';

  @override
  String get searchFilterArtist => 'Artiest';

  @override
  String get searchFilterLabel => 'Label';

  @override
  String get cachedResultsBanner => 'Opgeslagen resultaten worden weergegeven';

  @override
  String get collectionSearchHint => 'Doorzoek je collectie…';

  @override
  String get collectionEmptyTitle => 'Je collectie is leeg';

  @override
  String get collectionOfflineNote =>
      'Je collectie wordt op dit apparaat opgeslagen en werkt zonder internet.';

  @override
  String collectionNoResultsTitle(String query) {
    return 'Geen resultaten voor «$query»';
  }

  @override
  String get collectionNoResultsBody => 'Probeer een andere artiest of titel.';

  @override
  String get wishlistSearchHint => 'Doorzoek je verlanglijst…';

  @override
  String get wishlistEmptyTitle => 'Je verlanglijst is leeg';

  @override
  String get wishlistOfflineNote =>
      'Je verlanglijst wordt op dit apparaat opgeslagen en werkt zonder internet.';

  @override
  String wishlistNoResultsTitle(String query) {
    return 'Geen resultaten voor «$query»';
  }

  @override
  String get wishlistNoResultsBody => 'Probeer een andere artiest of titel.';

  @override
  String get addViaSearchHint =>
      'Gebruik het zoektabblad om releases te vinden en toe te voegen.';

  @override
  String get calculating => 'Berekenen…';

  @override
  String get settingsImportExport => 'Importeren en exporteren';

  @override
  String get settingsImportExportSubtitle =>
      'Records verplaatsen naar en van Discogs of CSV-bestanden';

  @override
  String get settingsFailedActions => 'Mislukte acties';

  @override
  String get settingsFailedActionsSubtitle =>
      'Bekijk acties die wachten op een nieuwe poging';

  @override
  String get settingsThumbnailCache => 'Thumbnail-cache';

  @override
  String get settingsLocalData => 'Lokale gegevens';

  @override
  String get settingsClearCollection => 'Collectie wissen';

  @override
  String get settingsClearWishlist => 'Verlanglijst wissen';

  @override
  String get settingsTourRestart => 'Rondleiding opnieuw starten';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsLanguageSystem => 'Systeeminstelling';

  @override
  String get actionCancel => 'Annuleren';

  @override
  String get actionClear => 'Wissen';

  @override
  String get barcodeEnterManually => 'Streepjescode handmatig invoeren…';

  @override
  String get barcodeScanButton => 'Streepjescode scannen';

  @override
  String get barcodeSearchButton => 'Zoeken';

  @override
  String get barcodeScanPrompt =>
      'Tik op \'Streepjescode scannen\' om de camera te openen';

  @override
  String get barcodePermissionDenied => 'Cameratoegang geweigerd';

  @override
  String get barcodePermissionDeniedHint =>
      'Geef cameratoegang in Instellingen om streepjescodes te scannen.';

  @override
  String get barcodeScanOrEnter => 'Scan of voer een streepjescode in';

  @override
  String get barcodeScanOrEnterHint =>
      'Richt de camera op een streepjescode of typ er een hierboven in.';

  @override
  String get barcodeNoReleases => 'Geen releases gevonden';

  @override
  String get barcodeNoReleasesHint =>
      'Geen Discogs-releases komen overeen met deze streepjescode. Probeer een andere streepjescode of controleer het nummer.';

  @override
  String get barcodeNoToken => 'Discogs-account niet verbonden';

  @override
  String get barcodeNoTokenHint =>
      'Ga naar Instellingen om je Discogs-account te verbinden.';

  @override
  String get barcodeRateLimited => 'Te veel verzoeken';

  @override
  String get barcodeRateLimitedHint =>
      'Discogs beperkt nu verzoeken. Wacht even en probeer het opnieuw.';

  @override
  String get barcodeSomethingWrong => 'Er ging iets mis';

  @override
  String get barcodeSomethingWrongHint =>
      'Kan Discogs niet bereiken. Er is een internetverbinding nodig voor streepjescodezoekingen.';

  @override
  String get barcodeValidationNotBarcode =>
      'Dit ziet er niet uit als een streepjescode';

  @override
  String get barcodeValidationWrongLength =>
      'Streepjescode moet 8, 12 of 13 cijfers hebben';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageDutch => 'Nederlands';
}

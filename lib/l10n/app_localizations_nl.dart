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
  String get navStatistics => 'Statistieken';

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
  String get searchSortTooltip => 'Sorteren';

  @override
  String get searchSortRelevance => 'Relevantie';

  @override
  String get searchSortNewestFirst => 'Nieuwste eerst';

  @override
  String get searchSortOldestFirst => 'Oudste eerst';

  @override
  String get searchVinylOnly => 'Alleen vinyl';

  @override
  String get searchNoResultsVinylOnlyBody =>
      'Geen vinylreleases gevonden voor deze zoekopdracht.';

  @override
  String get searchShowAllFormats => 'Alle formaten tonen';

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
  String get settingsAutoSync => 'Automatisch synchroniseren met Discogs';

  @override
  String get settingsAutoSyncSubtitle =>
      'Platen die je aan je collectie of verlanglijst toevoegt, gaan direct naar je Discogs-account.';

  @override
  String get settingsAutoSyncNeedsAccount =>
      'Koppel hierboven je Discogs-account om dit te gebruiken.';

  @override
  String get settingsAutoSyncTurnedOff =>
      'Uitgezet omdat Discogs je token weigerde. Koppel opnieuw en zet het daarna weer aan.';

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

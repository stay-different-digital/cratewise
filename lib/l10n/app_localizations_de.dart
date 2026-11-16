// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navSearch => 'Suchen';

  @override
  String get navCollection => 'Sammlung';

  @override
  String get navWishlist => 'Wunschliste';

  @override
  String get navStatistics => 'Statistiken';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get searchHint => 'Künstler, Album oder Label…';

  @override
  String get searchClearTooltip => 'Suche löschen';

  @override
  String get searchEmptyTitle => 'Discogs durchsuchen';

  @override
  String get searchEmptyBody =>
      'Gib einen Künstler-, Album- oder Labelnamen ein.';

  @override
  String get searchNoResultsTitle => 'Keine Ergebnisse';

  @override
  String get searchNoResultsBody => 'Probiere einen anderen Suchbegriff.';

  @override
  String get searchSelectResultTitle => 'Ergebnis auswählen';

  @override
  String get searchSelectResultBody =>
      'Tippe auf ein Suchergebnis, um die Details anzuzeigen.';

  @override
  String get searchFilterRelease => 'Release';

  @override
  String get searchFilterArtist => 'Künstler';

  @override
  String get searchFilterLabel => 'Label';

  @override
  String get searchSortTooltip => 'Sortieren';

  @override
  String get searchSortRelevance => 'Relevanz';

  @override
  String get searchSortNewestFirst => 'Neueste zuerst';

  @override
  String get searchSortOldestFirst => 'Älteste zuerst';

  @override
  String get searchVinylOnly => 'Nur Vinyl';

  @override
  String get searchNoResultsVinylOnlyBody =>
      'Keine Vinyl-Veröffentlichungen für diese Suche gefunden.';

  @override
  String get searchShowAllFormats => 'Alle Formate anzeigen';

  @override
  String get cachedResultsBanner => 'Gespeicherte Ergebnisse werden angezeigt';

  @override
  String get collectionSearchHint => 'Sammlung durchsuchen…';

  @override
  String get collectionEmptyTitle => 'Deine Sammlung ist leer';

  @override
  String get collectionOfflineNote =>
      'Deine Sammlung wird auf diesem Gerät gespeichert und funktioniert ohne Internet.';

  @override
  String collectionNoResultsTitle(String query) {
    return 'Keine Ergebnisse für «$query»';
  }

  @override
  String get collectionNoResultsBody =>
      'Probiere einen anderen Künstler oder Titel.';

  @override
  String get wishlistSearchHint => 'Wunschliste durchsuchen…';

  @override
  String get wishlistEmptyTitle => 'Deine Wunschliste ist leer';

  @override
  String get wishlistOfflineNote =>
      'Deine Wunschliste wird auf diesem Gerät gespeichert und funktioniert ohne Internet.';

  @override
  String wishlistNoResultsTitle(String query) {
    return 'Keine Ergebnisse für «$query»';
  }

  @override
  String get wishlistNoResultsBody =>
      'Probiere einen anderen Künstler oder Titel.';

  @override
  String get addViaSearchHint =>
      'Nutze den Suchen-Tab, um Releases zu finden und hinzuzufügen.';

  @override
  String get calculating => 'Wird berechnet…';

  @override
  String get settingsAutoSync => 'Automatisch mit Discogs synchronisieren';

  @override
  String get settingsAutoSyncSubtitle =>
      'Platten, die du deiner Sammlung oder Wunschliste hinzufügst, werden sofort an dein Discogs-Konto gesendet.';

  @override
  String get settingsAutoSyncNeedsAccount =>
      'Verbinde oben dein Discogs-Konto, um dies zu nutzen.';

  @override
  String get settingsAutoSyncTurnedOff =>
      'Ausgeschaltet, weil Discogs dein Token abgelehnt hat. Verbinde dich neu und schalte es dann wieder ein.';

  @override
  String get settingsImportExport => 'Import & Export';

  @override
  String get settingsImportExportSubtitle =>
      'Datensätze zu und von Discogs oder CSV-Dateien verschieben';

  @override
  String get settingsFailedActions => 'Fehlgeschlagene Aktionen';

  @override
  String get settingsFailedActionsSubtitle =>
      'Aktionen anzeigen, die wiederholt werden';

  @override
  String get settingsThumbnailCache => 'Thumbnail-Cache';

  @override
  String get settingsLocalData => 'Lokale Daten';

  @override
  String get settingsClearCollection => 'Sammlung löschen';

  @override
  String get settingsClearWishlist => 'Wunschliste löschen';

  @override
  String get settingsTourRestart => 'Tour neu starten';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionClear => 'Löschen';

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

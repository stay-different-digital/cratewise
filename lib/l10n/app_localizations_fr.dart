// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navSearch => 'Rechercher';

  @override
  String get navCollection => 'Collection';

  @override
  String get navWishlist => 'Liste de souhaits';

  @override
  String get navStatistics => 'Statistiques';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get searchHint => 'Artiste, album ou label…';

  @override
  String get searchClearTooltip => 'Effacer la recherche';

  @override
  String get searchEmptyTitle => 'Rechercher sur Discogs';

  @override
  String get searchEmptyBody =>
      'Saisissez un artiste, un album ou un nom de label pour rechercher.';

  @override
  String get searchNoResultsTitle => 'Aucun résultat';

  @override
  String get searchNoResultsBody => 'Essayez un autre terme de recherche.';

  @override
  String get searchSelectResultTitle => 'Sélectionner un résultat';

  @override
  String get searchSelectResultBody =>
      'Appuyez sur un résultat pour afficher ses détails.';

  @override
  String get searchFilterRelease => 'Release';

  @override
  String get searchFilterArtist => 'Artiste';

  @override
  String get searchFilterLabel => 'Label';

  @override
  String get filterButtonTooltip => 'Filtrer';

  @override
  String get searchFilterSheetTitle => 'Filtres de recherche';

  @override
  String get searchScopeTitle => 'Rechercher dans';

  @override
  String get sortTitle => 'Trier';

  @override
  String get filtersClearAll => 'Tout effacer';

  @override
  String get filtersApply => 'Appliquer';

  @override
  String get searchSortRelevance => 'Pertinence';

  @override
  String get sortNewestFirst => 'Plus récents d’abord';

  @override
  String get sortOldestFirst => 'Plus anciens d’abord';

  @override
  String get searchVinylOnly => 'Vinyle uniquement';

  @override
  String get searchNoResultsVinylOnlyBody =>
      'Aucun vinyle ne correspond à cette recherche.';

  @override
  String get searchShowAllFormats => 'Afficher tous les formats';

  @override
  String get cachedResultsBanner => 'Affichage des résultats enregistrés';

  @override
  String get collectionSearchHint => 'Rechercher dans la collection…';

  @override
  String get collectionEmptyTitle => 'Votre collection est vide';

  @override
  String get collectionOfflineNote =>
      'Votre collection est enregistrée sur cet appareil et fonctionne sans Internet.';

  @override
  String collectionNoResultsTitle(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get collectionNoResultsBody =>
      'Essayez un artiste ou un titre différent.';

  @override
  String get wishlistSearchHint => 'Rechercher dans la liste de souhaits…';

  @override
  String get wishlistEmptyTitle => 'Votre liste de souhaits est vide';

  @override
  String get wishlistOfflineNote =>
      'Votre liste de souhaits est enregistrée sur cet appareil et fonctionne sans Internet.';

  @override
  String wishlistNoResultsTitle(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get wishlistNoResultsBody =>
      'Essayez un artiste ou un titre différent.';

  @override
  String get addViaSearchHint =>
      'Utilisez l\'onglet Rechercher pour trouver des releases et les ajouter.';

  @override
  String get calculating => 'Calcul en cours…';

  @override
  String get settingsAutoSync => 'Synchroniser automatiquement avec Discogs';

  @override
  String get settingsAutoSyncSubtitle =>
      'Les disques ajoutés à ta collection ou à ta liste de souhaits sont envoyés immédiatement à ton compte Discogs.';

  @override
  String get settingsAutoSyncNeedsAccount =>
      'Connecte ton compte Discogs ci-dessus pour utiliser cette option.';

  @override
  String get settingsAutoSyncTurnedOff =>
      'Désactivé car Discogs a refusé ton jeton. Reconnecte-toi, puis réactive l’option.';

  @override
  String settingsAutoSyncConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Envoyer $count disques vers Discogs ?',
      one: 'Envoyer 1 disque vers Discogs ?',
    );
    return '$_temp0';
  }

  @override
  String get settingsAutoSyncConfirmBody =>
      'Les disques de ta collection ou de ta liste de souhaits qui ne sont pas encore sur Discogs seront ajoutés à ton compte Discogs. Ceux qui y sont déjà ne sont pas ajoutés deux fois.';

  @override
  String get settingsAutoSyncConfirmAction => 'Activer';

  @override
  String get settingsAutoSyncRunning => 'Synchronisation avec Discogs…';

  @override
  String settingsAutoSyncLastRun(String time, int sent, int added) {
    return 'Dernière synchronisation $time : $sent envoyés, $added ajoutés.';
  }

  @override
  String settingsAutoSyncLastRunProblem(String time, String problem) {
    return 'Dernière synchronisation $time : $problem Nouvel essai plus tard.';
  }

  @override
  String get settingsAutoSyncProblemNoConnection => 'Pas de connexion.';

  @override
  String get settingsAutoSyncProblemDiscogsBusy => 'Discogs était surchargé.';

  @override
  String get settingsAutoSyncProblemFailed => 'Un problème est survenu.';

  @override
  String get settingsImportExport => 'Import & Export';

  @override
  String get settingsImportExportSubtitle =>
      'Déplacer des enregistrements vers et depuis Discogs ou des fichiers CSV';

  @override
  String get settingsFailedActions => 'Actions échouées';

  @override
  String get settingsFailedActionsSubtitle =>
      'Voir les actions en attente de réessai';

  @override
  String get settingsThumbnailCache => 'Cache des miniatures';

  @override
  String get settingsLocalData => 'Données locales';

  @override
  String get settingsClearCollection => 'Effacer la collection';

  @override
  String get settingsClearWishlist => 'Effacer la liste de souhaits';

  @override
  String get settingsTourRestart => 'Redémarrer la visite';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Paramètre système';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionClear => 'Effacer';

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

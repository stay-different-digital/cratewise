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
  String get searchSortTooltip => 'Trier';

  @override
  String get searchSortRelevance => 'Pertinence';

  @override
  String get searchSortNewestFirst => 'Plus récents d’abord';

  @override
  String get searchSortOldestFirst => 'Plus anciens d’abord';

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
  String get barcodeEnterManually => 'Saisir le code-barres manuellement…';

  @override
  String get barcodeScanButton => 'Scanner un code-barres';

  @override
  String get barcodeSearchButton => 'Rechercher';

  @override
  String get barcodeScanPrompt =>
      'Appuyez sur « Scanner un code-barres » pour ouvrir l\'appareil photo';

  @override
  String get barcodePermissionDenied => 'Accès à la caméra refusé';

  @override
  String get barcodePermissionDeniedHint =>
      'Autorisez l\'accès à la caméra dans les Paramètres pour scanner des codes-barres.';

  @override
  String get barcodeScanOrEnter => 'Scanner ou saisir un code-barres';

  @override
  String get barcodeScanOrEnterHint =>
      'Pointez votre caméra sur un code-barres ou saisissez-en un ci-dessus.';

  @override
  String get barcodeNoReleases => 'Aucune release trouvée';

  @override
  String get barcodeNoReleasesHint =>
      'Aucune release Discogs ne correspond à ce code-barres. Essayez un autre code-barres ou vérifiez le numéro.';

  @override
  String get barcodeNoToken => 'Compte Discogs non connecté';

  @override
  String get barcodeNoTokenHint =>
      'Accédez aux Paramètres pour connecter votre compte Discogs.';

  @override
  String get barcodeRateLimited => 'Trop de requêtes';

  @override
  String get barcodeRateLimitedHint =>
      'Discogs limite les requêtes en ce moment. Attendez un instant et réessayez.';

  @override
  String get barcodeSomethingWrong => 'Quelque chose s\'est mal passé';

  @override
  String get barcodeSomethingWrongHint =>
      'Impossible de contacter Discogs. Une connexion Internet est nécessaire pour les recherches par code-barres.';

  @override
  String get barcodeValidationNotBarcode =>
      'Cela ne ressemble pas à un code-barres';

  @override
  String get barcodeValidationWrongLength =>
      'Le code-barres doit comporter 8, 12 ou 13 chiffres';

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

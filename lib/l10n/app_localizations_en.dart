// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navSearch => 'Search';

  @override
  String get navCollection => 'Collection';

  @override
  String get navWishlist => 'Wishlist';

  @override
  String get navSettings => 'Settings';

  @override
  String get searchHint => 'Artist, album, or label…';

  @override
  String get searchClearTooltip => 'Clear search';

  @override
  String get searchEmptyTitle => 'Search Discogs';

  @override
  String get searchEmptyBody =>
      'Type an artist, album, or label name to search.';

  @override
  String get searchNoResultsTitle => 'No results';

  @override
  String get searchNoResultsBody => 'Try a different search term.';

  @override
  String get searchSelectResultTitle => 'Select a result';

  @override
  String get searchSelectResultBody =>
      'Tap a search result to view its details.';

  @override
  String get searchFilterRelease => 'Release';

  @override
  String get searchFilterArtist => 'Artist';

  @override
  String get searchFilterLabel => 'Label';

  @override
  String get cachedResultsBanner => 'Showing saved results';

  @override
  String get collectionSearchHint => 'Search your collection…';

  @override
  String get collectionEmptyTitle => 'Your collection is empty';

  @override
  String get collectionOfflineNote =>
      'Your collection is saved on this device and works without internet.';

  @override
  String collectionNoResultsTitle(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get collectionNoResultsBody => 'Try a different artist or title.';

  @override
  String get wishlistSearchHint => 'Search your wishlist…';

  @override
  String get wishlistEmptyTitle => 'Your wishlist is empty';

  @override
  String get wishlistOfflineNote =>
      'Your wishlist is saved on this device and works without internet.';

  @override
  String wishlistNoResultsTitle(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get wishlistNoResultsBody => 'Try a different artist or title.';

  @override
  String get addViaSearchHint =>
      'Use the Search tab to find releases and add them.';

  @override
  String get calculating => 'Calculating…';

  @override
  String get settingsImportExport => 'Import & Export';

  @override
  String get settingsImportExportSubtitle =>
      'Move records to and from Discogs or CSV files';

  @override
  String get settingsFailedActions => 'Failed Actions';

  @override
  String get settingsFailedActionsSubtitle =>
      'View actions waiting to be retried';

  @override
  String get settingsThumbnailCache => 'Thumbnail Cache';

  @override
  String get settingsLocalData => 'Local data';

  @override
  String get settingsClearCollection => 'Clear collection';

  @override
  String get settingsClearWishlist => 'Clear wishlist';

  @override
  String get settingsTourRestart => 'Restart tour';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClear => 'Clear';

  @override
  String get barcodeEnterManually => 'Enter barcode manually…';

  @override
  String get barcodeScanButton => 'Scan barcode';

  @override
  String get barcodeSearchButton => 'Search';

  @override
  String get barcodeScanPrompt => 'Tap \'Scan barcode\' to open your camera';

  @override
  String get barcodePermissionDenied => 'Camera permission denied';

  @override
  String get barcodePermissionDeniedHint =>
      'Allow camera access in Settings to scan barcodes.';

  @override
  String get barcodeScanOrEnter => 'Scan or enter a barcode';

  @override
  String get barcodeScanOrEnterHint =>
      'Point your camera at a barcode or type one above.';

  @override
  String get barcodeNoReleases => 'No releases found';

  @override
  String get barcodeNoReleasesHint =>
      'No Discogs releases match this barcode. Try a different barcode or check the number.';

  @override
  String get barcodeNoToken => 'Discogs account not connected';

  @override
  String get barcodeNoTokenHint =>
      'Go to Settings to connect your Discogs account.';

  @override
  String get barcodeRateLimited => 'Too many requests';

  @override
  String get barcodeRateLimitedHint =>
      'Discogs is limiting requests right now. Wait a moment and try again.';

  @override
  String get barcodeSomethingWrong => 'Something went wrong';

  @override
  String get barcodeSomethingWrongHint =>
      'Could not reach Discogs. An internet connection is needed for barcode lookups.';

  @override
  String get barcodeValidationNotBarcode => 'This doesn\'t look like a barcode';

  @override
  String get barcodeValidationWrongLength =>
      'Barcode must be 8, 12, or 13 digits';

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

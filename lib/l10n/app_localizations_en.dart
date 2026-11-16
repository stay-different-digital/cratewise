// ignore_for_file: deprecated_member_use

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
  String get navStatistics => 'Statistics';

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
  String get searchSortTooltip => 'Sort';

  @override
  String get searchSortRelevance => 'Relevance';

  @override
  String get searchSortNewestFirst => 'Newest first';

  @override
  String get searchSortOldestFirst => 'Oldest first';

  @override
  String get searchVinylOnly => 'Vinyl only';

  @override
  String get searchNoResultsVinylOnlyBody =>
      'No vinyl releases match this search.';

  @override
  String get searchShowAllFormats => 'Show all formats';

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
  String get settingsAutoSync => 'Sync automatically with Discogs';

  @override
  String get settingsAutoSyncSubtitle =>
      'Records you add to your collection or wishlist are sent to your Discogs account right away.';

  @override
  String get settingsAutoSyncNeedsAccount =>
      'Connect your Discogs account above to use this.';

  @override
  String get settingsAutoSyncTurnedOff =>
      'Turned off because Discogs rejected your token. Reconnect, then turn it on again.';

  @override
  String settingsAutoSyncConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count records to Discogs?',
      one: 'Send 1 record to Discogs?',
    );
    return '$_temp0';
  }

  @override
  String get settingsAutoSyncConfirmBody =>
      'Records in your collection or wishlist that are not on Discogs yet will be added to your Discogs account. Records already there are not added twice.';

  @override
  String get settingsAutoSyncConfirmAction => 'Turn on';

  @override
  String get settingsAutoSyncRunning => 'Syncing with Discogs…';

  @override
  String settingsAutoSyncLastRun(String time, int sent, int added) {
    return 'Last sync $time: $sent sent, $added added.';
  }

  @override
  String settingsAutoSyncLastRunProblem(String time, String problem) {
    return 'Last sync $time: $problem It will try again.';
  }

  @override
  String get settingsAutoSyncProblemNoConnection => 'No connection.';

  @override
  String get settingsAutoSyncProblemDiscogsBusy => 'Discogs was busy.';

  @override
  String get settingsAutoSyncProblemFailed => 'Something went wrong.';

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

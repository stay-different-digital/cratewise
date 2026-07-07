import 'package:flutter/widgets.dart';

import '../domain/repositories/transaction_runner.dart';
import '../infrastructure/local_database/app_database.dart';
import '../infrastructure/local_database/database_transaction_runner.dart';
import '../infrastructure/local_database/local_cached_release_metadata_repository.dart';
import '../infrastructure/local_database/local_collection_repository.dart';
import '../infrastructure/local_database/local_import_export_job_repository.dart';
import '../infrastructure/local_database/local_import_export_row_result_repository.dart';
import '../infrastructure/local_database/local_pending_discogs_deletion_repository.dart';
import '../infrastructure/local_database/local_retry_action_repository.dart';
import '../infrastructure/local_database/local_saved_search_repository.dart';
import '../infrastructure/local_database/local_wishlist_repository.dart';

/// All database-backed repositories created from a single [AppDatabase].
///
/// Provided to the widget tree via [AppRepositoriesScope].
class AppRepositories {
  AppRepositories(AppDatabase db)
    : collection = LocalCollectionRepository(db),
      wishlist = LocalWishlistRepository(db),
      cachedRelease = LocalCachedReleaseMetadataRepository(db),
      pendingDeletion = LocalPendingDiscogsDeletionRepository(db),
      importExportJob = LocalImportExportJobRepository(db),
      importExportRowResult = LocalImportExportRowResultRepository(db),
      retryAction = LocalRetryActionRepository(db),
      savedSearch = LocalSavedSearchRepository(db),
      transactionRunner = DatabaseTransactionRunner(db);

  final LocalCollectionRepository collection;
  final LocalWishlistRepository wishlist;
  final LocalCachedReleaseMetadataRepository cachedRelease;
  final LocalPendingDiscogsDeletionRepository pendingDeletion;
  final LocalImportExportJobRepository importExportJob;
  final LocalImportExportRowResultRepository importExportRowResult;
  final LocalRetryActionRepository retryAction;
  final LocalSavedSearchRepository savedSearch;
  final TransactionRunner transactionRunner;
}

/// Provides [AppRepositories] to all descendant widgets.
///
/// Screens read repositories in [State.initState] via
/// [AppRepositoriesScope.of] when no repository is injected via constructor
/// (the production path). Tests inject repositories directly and never call
/// [of], so they don't need this scope to be present.
class AppRepositoriesScope extends InheritedWidget {
  const AppRepositoriesScope({
    super.key,
    required this.repositories,
    required super.child,
  });

  final AppRepositories repositories;

  static AppRepositories of(BuildContext context) => context
      .getInheritedWidgetOfExactType<AppRepositoriesScope>()!
      .repositories;

  static AppRepositories? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<AppRepositoriesScope>()
      ?.repositories;

  @override
  bool updateShouldNotify(AppRepositoriesScope oldWidget) => false;
}

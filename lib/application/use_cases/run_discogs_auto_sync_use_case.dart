import 'package:uuid/uuid.dart';

import '../../domain/models/collection_import_preview.dart';
import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_row_result.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_import_preview.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../domain/repositories/import_export_row_result_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../shared/errors/app_error.dart';
import '../services/discogs_auto_sync_service.dart';
import 'execute_collection_import_use_case.dart';
import 'execute_wishlist_import_use_case.dart';
import 'fetch_collection_import_preview_use_case.dart';
import 'fetch_wishlist_import_preview_use_case.dart';

/// Why (part of) a run did not complete; shown in Settings.
enum AutoSyncProblem { noConnection, discogsBusy, failed }

/// Outcome of one automatic sync run.
class AutoSyncRunResult {
  const AutoSyncRunResult({
    required this.sent,
    required this.failed,
    this.added = 0,
    this.problem,
  });

  /// Local items sent to Discogs.
  final int sent;

  /// Local items that could not be sent this time.
  final int failed;

  /// Releases added on Discogs that were brought into the app (US-149).
  final int added;
  final AutoSyncProblem? problem;
}

/// The background half of automatic sync: first sends every collection and
/// wishlist item that is not on Discogs yet — added offline, failed earlier,
/// or already local before auto-sync was turned on (US-148) — then brings in
/// releases added on Discogs (US-149). Sending first means an item just added
/// in the app never comes back as "new on Discogs".
///
/// Runs when the app opens and returns to the foreground, at most once per
/// [minInterval], never twice at once, and never while a manual import or
/// export is running. One instance per app keeps the throttle state.
class RunDiscogsAutoSyncUseCase {
  RunDiscogsAutoSyncUseCase({
    required this._autoSync,
    required this._collection,
    required this._wishlist,
    required this._jobs,
    required this._rowResults,
    required this._fetchCollection,
    required this._importCollection,
    required this._fetchWishlist,
    required this._importWishlist,
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? (() => const Uuid().v4());

  static const minInterval = Duration(minutes: 15);

  /// A manual job marked running but untouched for this long is treated as
  /// abandoned (e.g. the app was killed mid-import) and no longer blocks.
  static const _staleJobAfter = Duration(minutes: 30);

  static const _unsent = {
    SyncStatus.localOnly,
    SyncStatus.failed,
    SyncStatus.offline,
  };

  final DiscogsAutoSyncService _autoSync;
  final CollectionRepository _collection;
  final WishlistRepository _wishlist;
  final ImportExportJobRepository _jobs;
  final ImportExportRowResultRepository _rowResults;
  // The manual import's own steps (US-149): same duplicate, link and
  // pending-deletion rules, one place.
  final FetchCollectionImportPreviewUseCase _fetchCollection;
  final ExecuteCollectionImportUseCase _importCollection;
  final FetchWishlistImportPreviewUseCase _fetchWishlist;
  final ExecuteWishlistImportUseCase _importWishlist;
  final DateTime Function() _clock;
  final String Function() _idGenerator;

  DateTime? _lastRun;
  bool _running = false;

  /// How many items a run would send now — shown before auto-sync is turned
  /// on, so the user confirms sending items that were only local so far.
  static Future<int> countUnsent(
    CollectionRepository collection,
    WishlistRepository wishlist,
  ) async {
    final items = await collection.getAll();
    final wishes = await wishlist.getAll();
    return items.where((i) => _unsent.contains(i.syncStatus)).length +
        wishes.where((i) => _unsent.contains(i.syncStatus)).length;
  }

  /// Runs unless it ran less than [minInterval] ago ([force] skips that check,
  /// e.g. right after the user turns auto-sync on). Returns null when skipped;
  /// [onStart] is called only when a run actually starts.
  Future<AutoSyncRunResult?> run({
    bool force = false,
    void Function()? onStart,
  }) async {
    if (_running) return null;
    final now = _clock();
    final last = _lastRun;
    if (!force && last != null && now.difference(last) < minInterval) {
      return null;
    }
    _running = true;
    try {
      if (!await _autoSync.isEnabled()) return null;
      if (await _manualJobRunning(now)) return null;
      _lastRun = now;
      onStart?.call();
      try {
        final sent = await _sendUnsent();
        // Auto-sync switched itself off (token rejected): don't import either.
        if (sent.stopped) return sent.result;
        final (:added, :problem) = await _importNew();
        return AutoSyncRunResult(
          sent: sent.result.sent,
          failed: sent.result.failed,
          added: added,
          problem: problem,
        );
      } catch (e, st) {
        logSwallowed(e, st, 'RunDiscogsAutoSyncUseCase');
        return const AutoSyncRunResult(
          sent: 0,
          failed: 0,
          problem: AutoSyncProblem.failed,
        );
      }
    } catch (e, st) {
      logSwallowed(e, st, 'RunDiscogsAutoSyncUseCase');
      return null;
    } finally {
      _running = false;
    }
  }

  Future<bool> _manualJobRunning(DateTime now) async {
    final recent = await _jobs.getRecent(limit: 5);
    return recent.any(
      (j) =>
          j.status == ImportExportStatus.running &&
          j.jobType != ImportExportJobType.autoSyncWithDiscogs &&
          now.difference(j.updatedAt) < _staleJobAfter,
    );
  }

  Future<({AutoSyncRunResult result, bool stopped})> _sendUnsent() async {
    final items = (await _collection.getAll())
        .where((i) => _unsent.contains(i.syncStatus))
        .toList();
    final wishes = (await _wishlist.getAll())
        .where((i) => _unsent.contains(i.syncStatus))
        .toList();
    // Nothing to do: keep the history free of empty runs.
    if (items.isEmpty && wishes.isEmpty) {
      return (
        result: const AutoSyncRunResult(sent: 0, failed: 0),
        stopped: false,
      );
    }

    final now = _clock();
    final job = ImportExportJob(
      id: _idGenerator(),
      jobType: ImportExportJobType.autoSyncWithDiscogs,
      source: 'Cratewise',
      target: 'Discogs',
      status: ImportExportStatus.running,
      totalItems: items.length + wishes.length,
      createdAt: now,
      updatedAt: now,
    );
    await _jobs.add(job);

    var sent = 0;
    var failed = 0;
    var row = 0;
    Future<bool> record(String description, SyncStatus? status) async {
      // null: auto-sync switched itself off mid-run (token rejected) or the
      // account was unlinked — stop instead of failing every remaining item.
      if (status == null) return false;
      if (status == SyncStatus.synced) {
        sent++;
        await _rowResults.addResult(
          job.id,
          ValidRow(rowIndex: row++, description: description),
        );
      } else {
        failed++;
        await _rowResults.addResult(
          job.id,
          FailedRow(
            rowIndex: row++,
            safeErrorMessage: status == SyncStatus.offline
                ? '$description — no connection, will retry'
                : '$description — could not be sent, will retry',
          ),
        );
      }
      return true;
    }

    var stopped = false;
    for (final item in items) {
      final status = await _autoSync.pushCollectionItem(item, _collection);
      if (!await record('${item.artist} – ${item.title}', status)) {
        stopped = true;
        break;
      }
    }
    if (!stopped) {
      for (final wish in wishes) {
        final status = await _autoSync.pushWishlistItem(wish, _wishlist);
        if (!await record(
          '${wish.artist} – ${wish.title} (wishlist)',
          status,
        )) {
          stopped = true;
          break;
        }
      }
    }

    await _jobs.update(
      job.copyWith(
        status: stopped
            ? ImportExportStatus.failed
            : failed > 0
            ? ImportExportStatus.completedWithErrors
            : ImportExportStatus.completed,
        validItems: sent,
        failedItems: failed,
        safeErrorMessage: stopped
            ? 'Stopped: automatic sync was turned off or Discogs is not '
                  'connected.'
            : null,
        updatedAt: _clock(),
      ),
    );
    return (
      result: AutoSyncRunResult(sent: sent, failed: failed),
      stopped: stopped,
    );
  }

  /// Brings in releases that are on Discogs but not in the app (US-149).
  /// Only adds and links: rows for releases the app already has are dropped
  /// before importing, so local fields are never overwritten, nothing is
  /// deleted, and the history gets no line per already-present record. A
  /// release with a pending local deletion is a conflict row and stays out.
  Future<({int added, AutoSyncProblem? problem})> _importNew() async {
    var added = 0;
    AutoSyncProblem? problem;

    switch (await _fetchCollection.execute()) {
      case FetchPreviewReady(:final preview):
        final rows = preview.rows
            .where(
              (r) =>
                  r is NewCollectionRow ||
                  (r is DuplicateCollectionRow && r.linkTargetId != null),
            )
            .toList();
        if (rows.isNotEmpty) {
          final result = await _importCollection.execute(
            CollectionImportPreview(rows: rows),
          );
          if (result is ExecuteImportCompleted) {
            added += result.imported;
          } else {
            problem = AutoSyncProblem.failed;
          }
        }
      case FetchPreviewNoToken():
        return (added: 0, problem: null);
      case FetchPreviewNetworkError():
        problem = AutoSyncProblem.noConnection;
      case FetchPreviewRateLimitExhausted():
        problem = AutoSyncProblem.discogsBusy;
      case FetchPreviewError():
        problem = AutoSyncProblem.failed;
    }

    switch (await _fetchWishlist.execute()) {
      case FetchWishlistPreviewReady(:final preview):
        // Wishlist duplicates need no link: unsynced local wishes were just
        // sent above, which already marked them synced.
        final rows = preview.rows.whereType<NewWishlistRow>().toList();
        if (rows.isNotEmpty) {
          final result = await _importWishlist.execute(
            WishlistImportPreview(rows: rows),
          );
          if (result is ExecuteWishlistImportCompleted) {
            added += result.imported;
          } else {
            problem ??= AutoSyncProblem.failed;
          }
        }
      case FetchWishlistPreviewNoToken():
        break;
      case FetchWishlistPreviewNetworkError():
        problem ??= AutoSyncProblem.noConnection;
      case FetchWishlistPreviewRateLimitExhausted():
        problem ??= AutoSyncProblem.discogsBusy;
      case FetchWishlistPreviewError():
        problem ??= AutoSyncProblem.failed;
    }
    return (added: added, problem: problem);
  }
}

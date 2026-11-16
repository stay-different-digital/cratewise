import 'dart:async';

import 'package:cratewise/application/services/discogs_auto_sync_service.dart';
import 'package:cratewise/application/use_cases/build_collection_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/build_wishlist_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/execute_collection_import_use_case.dart';
import 'package:cratewise/application/use_cases/execute_wishlist_import_use_case.dart';
import 'package:cratewise/application/use_cases/fetch_collection_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/fetch_wishlist_import_preview_use_case.dart';
import 'package:cratewise/application/use_cases/run_discogs_auto_sync_use_case.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/widgets/discogs_auto_sync_runner.dart';
import 'package:cratewise/shared/auto_sync_request_notifier.dart';
import 'package:cratewise/shared/import_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Never called: the recording run overrides everything that would use them.
class _NoCollection implements CollectionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoWishlist implements WishlistRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoJobs implements ImportExportJobRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoRows implements ImportExportRowResultRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _RecordingRun extends RunDiscogsAutoSyncUseCase {
  _RecordingRun()
    : super(
        autoSync: DiscogsAutoSyncService(),
        collection: _NoCollection(),
        wishlist: _NoWishlist(),
        jobs: _NoJobs(),
        rowResults: _NoRows(),
        fetchCollection: FetchCollectionImportPreviewUseCase(
          previewBuilder: BuildCollectionImportPreviewUseCase(_NoCollection()),
        ),
        importCollection: ExecuteCollectionImportUseCase(
          collectionRepository: _NoCollection(),
          jobRepository: _NoJobs(),
          rowResultRepository: _NoRows(),
        ),
        fetchWishlist: FetchWishlistImportPreviewUseCase(
          previewBuilder: BuildWishlistImportPreviewUseCase(_NoWishlist()),
        ),
        importWishlist: ExecuteWishlistImportUseCase(
          wishlistRepository: _NoWishlist(),
          jobRepository: _NoJobs(),
          rowResultRepository: _NoRows(),
        ),
      );

  final calls = <bool>[]; // force flag per call
  AutoSyncRunResult? result;
  Completer<void>? gate;

  @override
  Future<AutoSyncRunResult?> run({
    bool force = false,
    void Function()? onStart,
  }) async {
    calls.add(force);
    if (result == null) return null;
    onStart?.call();
    await gate?.future;
    return result;
  }
}

void main() {
  testWidgets('runs on start, on resume, and forced on request (US-148)', (
    tester,
  ) async {
    final run = _RecordingRun();
    await tester.pumpWidget(
      DiscogsAutoSyncRunner(useCase: run, child: const SizedBox()),
    );
    expect(run.calls, [false], reason: 'app opened');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(run.calls, [false, false], reason: 'back in the foreground');

    autoSyncRequestNotifier.value++;
    expect(run.calls, [false, false, true], reason: 'auto-sync turned on');
  });

  testWidgets('publishes progress and result; lists reload after imports '
      '(US-149)', (tester) async {
    final run = _RecordingRun()
      ..result = const AutoSyncRunResult(sent: 1, failed: 0, added: 2)
      ..gate = Completer<void>();
    final collectionBefore = collectionImportNotifier.value;
    await tester.pumpWidget(
      DiscogsAutoSyncRunner(useCase: run, child: const SizedBox()),
    );

    expect(autoSyncStatusNotifier.value.running, isTrue);

    run.gate!.complete();
    await tester.pump();

    final status = autoSyncStatusNotifier.value;
    expect(status.running, isFalse);
    expect(status.lastResult!.added, 2);
    expect(status.lastRunAt, isNotNull);
    expect(collectionImportNotifier.value, collectionBefore + 1);
  });
}

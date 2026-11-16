import 'package:cratewise/application/services/discogs_auto_sync_service.dart';
import 'package:cratewise/application/use_cases/run_discogs_auto_sync_use_case.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/domain/repositories/import_export_row_result_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/presentation/widgets/discogs_auto_sync_runner.dart';
import 'package:cratewise/shared/auto_sync_request_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRun extends RunDiscogsAutoSyncUseCase {
  _RecordingRun()
    : super(
        autoSync: DiscogsAutoSyncService(),
        collection: _NoCollection(),
        wishlist: _NoWishlist(),
        jobs: _NoJobs(),
        rowResults: _NoRows(),
      );
  final calls = <bool>[]; // force flag per call

  @override
  Future<AutoSyncRunResult?> run({bool force = false}) async {
    calls.add(force);
    return null;
  }
}

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
}

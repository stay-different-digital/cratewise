import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../app/app_repositories.dart';
import '../../application/services/discogs_auto_sync_service.dart';
import '../../application/use_cases/run_discogs_auto_sync_use_case.dart';
import '../../shared/auto_sync_request_notifier.dart';
import '../../shared/import_notifier.dart';

/// Starts automatic Discogs sync runs (US-148): when the app opens, when it
/// returns to the foreground, and on request (auto-sync just turned on). The
/// use case throttles to once per 15 minutes and does nothing when off.
class DiscogsAutoSyncRunner extends StatefulWidget {
  const DiscogsAutoSyncRunner({super.key, required this.child, this.useCase});

  final Widget child;

  /// Injected only in tests.
  final RunDiscogsAutoSyncUseCase? useCase;

  @override
  State<DiscogsAutoSyncRunner> createState() => _DiscogsAutoSyncRunnerState();
}

class _DiscogsAutoSyncRunnerState extends State<DiscogsAutoSyncRunner>
    with WidgetsBindingObserver {
  late final RunDiscogsAutoSyncUseCase _useCase;

  @override
  void initState() {
    super.initState();
    final repos = widget.useCase == null
        ? AppRepositoriesScope.of(context)
        : null;
    _useCase =
        widget.useCase ??
        RunDiscogsAutoSyncUseCase(
          autoSync: DiscogsAutoSyncService.shared,
          collection: repos!.collection,
          wishlist: repos.wishlist,
          jobs: repos.importExportJob,
          rowResults: repos.importExportRowResult,
        );
    WidgetsBinding.instance.addObserver(this);
    autoSyncRequestNotifier.addListener(_onRequest);
    unawaited(_run());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    autoSyncRequestNotifier.removeListener(_onRequest);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_run());
  }

  void _onRequest() => unawaited(_run(force: true));

  Future<void> _run({bool force = false}) async {
    final result = await _useCase.run(force: force);
    if (result == null || result.sent + result.failed == 0) return;
    // Sync status icons changed: let the collection and wishlist reload.
    collectionImportNotifier.value++;
    wishlistImportNotifier.value++;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

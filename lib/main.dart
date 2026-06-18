import 'package:flutter/material.dart';

import 'app/app.dart';
import 'application/services/onboarding_service.dart';
import 'application/use_cases/clean_up_stale_csv_exports_use_case.dart';
import 'application/use_cases/purge_stale_failed_actions_use_case.dart';
import 'infrastructure/local_database/app_database.dart';
import 'infrastructure/local_database/local_retry_action_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final showOnboarding = !(await const OnboardingService().isComplete());
  await _purgeStaleFailedActions();
  await CleanUpStaleCsvExportsUseCase().execute();
  runApp(CratewiseApp(showOnboarding: showOnboarding));
}

Future<void> _purgeStaleFailedActions() async {
  final db = AppDatabase(openAppDatabase());
  try {
    await PurgeStaleFailedActionsUseCase(
      retryRepo: LocalRetryActionRepository(db),
    ).execute();
  } finally {
    await db.close();
  }
}

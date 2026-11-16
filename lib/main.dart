import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'application/services/onboarding_service.dart';
import 'application/use_cases/clean_up_stale_csv_exports_use_case.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final showOnboarding = !(await const OnboardingService().isComplete());
  await CleanUpStaleCsvExportsUseCase().execute();
  runApp(CratewiseApp(showOnboarding: showOnboarding));
}

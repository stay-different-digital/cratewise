// Upgrade check for stored settings (US-155): data written by one build must
// still be readable after a newer build is installed over it.
//
//   1. From the OLD code: flutter test integration_test/secure_storage_upgrade_test.dart \
//        -d <device> --dart-define=PHASE=write
//   2. From the NEW code, same device, without uninstalling:
//        ... --dart-define=PHASE=verify
//
// Without PHASE the test is skipped (CI, normal test runs). Uses fixed dummy
// values, never a real token.

import 'package:cratewise/app/locale_preference.dart';
import 'package:cratewise/app/search_preferences.dart';
import 'package:cratewise/application/services/discogs_auto_sync_service.dart';
import 'package:cratewise/application/services/onboarding_service.dart';
import 'package:cratewise/infrastructure/secure_storage/discogs_token_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _phase = String.fromEnvironment('PHASE');
const _token = 'upgrade-check-token-0123456789abcdefghij';
const _username = 'upgrade-check-user';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'secure storage survives an app upgrade ($_phase)',
    (tester) async {
      final tokens = DiscogsTokenStorage();
      final autoSync = DiscogsAutoSyncService();
      if (_phase == 'write') {
        await tokens.saveCredentials(token: _token, username: _username);
        await saveLocalePreference(const Locale('nl'));
        await const OnboardingService().markComplete();
        await saveVinylOnlyPreference(true);
        await autoSync.setEnabled(true);
        // flutter_secure_storage 9 persists with SharedPreferences.apply(),
        // which is asynchronous; the test process is killed right after the
        // test, so give the write time to reach disk (the real app keeps
        // running after a save).
        await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      }
      expect(await tokens.loadToken(), _token);
      expect(await tokens.loadUsername(), _username);
      expect((await loadLocalePreference())?.languageCode, 'nl');
      expect(await const OnboardingService().isComplete(), isTrue);
      expect(await loadVinylOnlyPreference(), isTrue);
      expect(await autoSync.isEnabled(), isTrue);
    },
    skip: _phase != 'write' && _phase != 'verify',
  );
}

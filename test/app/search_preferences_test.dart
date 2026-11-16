import 'package:cratewise/app/search_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('vinyl-only search preference (US-142)', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('defaults to off', () async {
      expect(await loadVinylOnlyPreference(), isFalse);
    });

    test('round-trips on and off', () async {
      await saveVinylOnlyPreference(true);
      expect(await loadVinylOnlyPreference(), isTrue);
      await saveVinylOnlyPreference(false);
      expect(await loadVinylOnlyPreference(), isFalse);
    });
  });
}

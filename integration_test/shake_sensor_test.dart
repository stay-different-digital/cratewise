// Device check for sensors_plus under built-in Kotlin (US-153/US-159): the
// real accelerometer stream must deliver a shake-strength event. Run on an
// Android emulator with --dart-define=SHAKE=true while simulating a shake:
//   adb emu sensor set acceleration 30:0:0
// Skipped otherwise. Screen reactions to a shake are covered by widget tests.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

const _shake = bool.fromEnvironment('SHAKE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('accelerometer delivers a shake-strength event', (tester) async {
    final magnitude = await tester.runAsync(
      () => accelerometerEventStream()
          .map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z))
          .firstWhere((m) => m >= 20) // same threshold as the screens
          .timeout(const Duration(seconds: 90)),
    );
    expect(magnitude, greaterThanOrEqualTo(20));
  }, skip: !_shake);
}

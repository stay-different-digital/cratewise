// Manual-assist smoke test for native plugins (US-151 share_plus,
// US-154 file_picker): opens the real share sheet and the real file picker.
// Run with --dart-define=SMOKE=true on a device, screenshot while each system
// screen is open, then dismiss it (Android: back button). Skipped otherwise.

import 'dart:io';

import 'package:cratewise/infrastructure/csv/csv_file_picker_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _smoke = bool.fromEnvironment('SMOKE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('share sheet and file picker open natively', (tester) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cratewise-smoke.csv')
      ..writeAsStringSync('artist,title\nMiles Davis,Kind Of Blue\n');

    // ignore: avoid_print
    print('SMOKE: share sheet opening');
    final shared = await tester.runAsync(
      () => SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
      ),
    );
    // ignore: avoid_print
    print('SMOKE: share closed with ${shared?.status}');

    // ignore: avoid_print
    print('SMOKE: file picker opening');
    final picked = await tester.runAsync(
      () => const CsvFilePickerService().pick(),
    );
    // ignore: avoid_print
    print('SMOKE: picker closed, picked=${picked?.filename}');
  }, skip: !_smoke);
}

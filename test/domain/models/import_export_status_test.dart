import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportExportStatus', () {
    test('has all expected values', () {
      expect(
        ImportExportStatus.values,
        unorderedEquals([
          ImportExportStatus.idle,
          ImportExportStatus.validating,
          ImportExportStatus.previewing,
          ImportExportStatus.running,
          ImportExportStatus.completed,
          ImportExportStatus.completedWithErrors,
          ImportExportStatus.failed,
          ImportExportStatus.cancelled,
        ]),
      );
    });

    test('switch is exhaustive over all values', () {
      for (final status in ImportExportStatus.values) {
        final name = switch (status) {
          ImportExportStatus.idle => 'idle',
          ImportExportStatus.validating => 'validating',
          ImportExportStatus.previewing => 'previewing',
          ImportExportStatus.running => 'running',
          ImportExportStatus.completed => 'completed',
          ImportExportStatus.completedWithErrors => 'completedWithErrors',
          ImportExportStatus.failed => 'failed',
          ImportExportStatus.cancelled => 'cancelled',
        };
        expect(name, isNotEmpty);
      }
    });
  });
}

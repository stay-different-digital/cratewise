import 'package:cratewise/domain/models/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncStatus', () {
    test('has all expected values', () {
      expect(
        SyncStatus.values,
        unorderedEquals([
          SyncStatus.localOnly,
          SyncStatus.synced,
          SyncStatus.pending,
          SyncStatus.failed,
          SyncStatus.conflict,
          SyncStatus.offline,
        ]),
      );
    });

    test('switch is exhaustive over all values', () {
      for (final status in SyncStatus.values) {
        final label = switch (status) {
          SyncStatus.localOnly => 'localOnly',
          SyncStatus.synced => 'synced',
          SyncStatus.pending => 'pending',
          SyncStatus.failed => 'failed',
          SyncStatus.conflict => 'conflict',
          SyncStatus.offline => 'offline',
        };
        expect(label, isNotEmpty);
      }
    });
  });
}

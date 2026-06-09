import 'dart:io';

import 'package:cratewise/application/use_cases/clean_up_stale_csv_exports_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory testDir;

  setUp(() {
    testDir = Directory.systemTemp.createTempSync('cratewise_cleanup_test_');
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  Future<Directory> fakeDir() async => testDir;

  CleanUpStaleCsvExportsUseCase buildSubject({
    Duration ttl = const Duration(days: 7),
  }) => CleanUpStaleCsvExportsUseCase(getTempDir: fakeDir, ttl: ttl);

  int daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

  File writeFile(String name) =>
      File('${testDir.path}/$name')..writeAsStringSync('test');

  // ---------------------------------------------------------------------------
  // collection_export files
  // ---------------------------------------------------------------------------

  group('CleanUpStaleCsvExportsUseCase', () {
    test('deletes collection_export csv older than TTL', () async {
      final file = writeFile('collection_export_${daysAgo(8)}.csv');
      await buildSubject().execute();
      expect(file.existsSync(), isFalse);
    });

    test('keeps collection_export csv newer than TTL', () async {
      final file = writeFile('collection_export_${daysAgo(6)}.csv');
      await buildSubject().execute();
      expect(file.existsSync(), isTrue);
    });

    // ---------------------------------------------------------------------------
    // wishlist_export files
    // ---------------------------------------------------------------------------

    test('deletes wishlist_export csv older than TTL', () async {
      final file = writeFile('wishlist_export_${daysAgo(8)}.csv');
      await buildSubject().execute();
      expect(file.existsSync(), isFalse);
    });

    test('keeps wishlist_export csv newer than TTL', () async {
      final file = writeFile('wishlist_export_${daysAgo(6)}.csv');
      await buildSubject().execute();
      expect(file.existsSync(), isTrue);
    });

    // ---------------------------------------------------------------------------
    // Non-matching files
    // ---------------------------------------------------------------------------

    test('ignores files with unrecognised prefix', () async {
      final file = writeFile('other_file_${daysAgo(8)}.csv');
      await buildSubject().execute();
      expect(file.existsSync(), isTrue);
    });

    test('ignores non-csv export files', () async {
      final file = writeFile('collection_export_${daysAgo(8)}.txt');
      await buildSubject().execute();
      expect(file.existsSync(), isTrue);
    });

    test('ignores files with no timestamp in name', () async {
      final file = writeFile('collection_export_notanumber.csv');
      await buildSubject().execute();
      expect(file.existsSync(), isTrue);
    });

    // ---------------------------------------------------------------------------
    // Mixed old and new
    // ---------------------------------------------------------------------------

    test('deletes old files and keeps new files in same directory', () async {
      final oldCollection = writeFile('collection_export_${daysAgo(10)}.csv');
      final newCollection = writeFile('collection_export_${daysAgo(3)}.csv');
      final oldWishlist = writeFile('wishlist_export_${daysAgo(15)}.csv');
      final newWishlist = writeFile('wishlist_export_${daysAgo(1)}.csv');

      await buildSubject().execute();

      expect(oldCollection.existsSync(), isFalse);
      expect(newCollection.existsSync(), isTrue);
      expect(oldWishlist.existsSync(), isFalse);
      expect(newWishlist.existsSync(), isTrue);
    });

    // ---------------------------------------------------------------------------
    // Custom TTL
    // ---------------------------------------------------------------------------

    test('respects custom TTL', () async {
      final file = writeFile('collection_export_${daysAgo(2)}.csv');
      await buildSubject(ttl: const Duration(days: 1)).execute();
      expect(file.existsSync(), isFalse);
    });

    // ---------------------------------------------------------------------------
    // Error handling
    // ---------------------------------------------------------------------------

    test('does not throw when getTempDir fails', () async {
      final subject = CleanUpStaleCsvExportsUseCase(
        getTempDir: () async => throw Exception('no temp dir'),
      );
      await expectLater(subject.execute(), completes);
    });
  });
}

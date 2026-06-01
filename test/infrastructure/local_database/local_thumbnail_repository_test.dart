import 'dart:io';
import 'dart:typed_data';

import 'package:cratewise/infrastructure/local_database/local_thumbnail_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalThumbnailRepository', () {
    late Directory tempDir;
    late LocalThumbnailRepository repo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('thumbnail_test_');
      repo = LocalThumbnailRepository(directory: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('getLocalPath returns null when file does not exist', () async {
      expect(await repo.getLocalPath(249504), isNull);
    });

    test('exists returns false before save', () async {
      expect(await repo.exists(249504), isFalse);
    });

    test('save creates file and getLocalPath returns a non-null path', () async {
      await repo.save(249504, [0xff, 0xd8, 0xff]);
      final path = await repo.getLocalPath(249504);
      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);
    });

    test('saved bytes are readable from the returned path', () async {
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0x01]);
      await repo.save(249504, bytes);
      final path = await repo.getLocalPath(249504);
      expect(path, isNotNull);
      final read = await File(path!).readAsBytes();
      expect(read, bytes);
    });

    test('exists returns true after save', () async {
      await repo.save(249504, [1, 2, 3]);
      expect(await repo.exists(249504), isTrue);
    });

    test('remove deletes the file and getLocalPath returns null', () async {
      await repo.save(249504, [1, 2, 3]);
      await repo.remove(249504);
      expect(await repo.getLocalPath(249504), isNull);
    });

    test('remove on non-existent ID does not throw', () async {
      await expectLater(repo.remove(9999), completes);
    });

    test('second save overwrites the existing file', () async {
      await repo.save(249504, [1, 2, 3]);
      await repo.save(249504, [4, 5, 6, 7]);
      final path = await repo.getLocalPath(249504);
      expect(path, isNotNull);
      final bytes = await File(path!).readAsBytes();
      expect(bytes, [4, 5, 6, 7]);
    });

    test('different release IDs are stored independently', () async {
      await repo.save(1, [1, 1, 1]);
      await repo.save(2, [2, 2, 2]);
      expect(await repo.getLocalPath(1), isNotNull);
      expect(await repo.getLocalPath(2), isNotNull);
      expect(await repo.getLocalPath(3), isNull);
    });

    test('remove only deletes the specified release', () async {
      await repo.save(1, [1, 1, 1]);
      await repo.save(2, [2, 2, 2]);
      await repo.remove(1);
      expect(await repo.getLocalPath(1), isNull);
      expect(await repo.getLocalPath(2), isNotNull);
    });
  });
}

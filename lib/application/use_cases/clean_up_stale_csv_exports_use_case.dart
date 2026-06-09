import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CleanUpStaleCsvExportsUseCase {
  CleanUpStaleCsvExportsUseCase({
    Future<Directory> Function()? getTempDir,
    Duration ttl = const Duration(days: 7),
  }) : _getTempDir = getTempDir ?? getTemporaryDirectory,
       _ttl = ttl;

  final Future<Directory> Function() _getTempDir;
  final Duration _ttl;

  static final _filePattern = RegExp(
    r'^(?:collection|wishlist)_export_(\d+)\.csv$',
  );

  Future<void> execute() async {
    final Directory dir;
    try {
      dir = await _getTempDir();
    } catch (_) {
      return;
    }

    final cutoff = DateTime.now().subtract(_ttl);

    List<FileSystemEntity> entities;
    try {
      entities = dir.listSync();
    } catch (_) {
      return;
    }

    for (final entity in entities) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final match = _filePattern.firstMatch(name);
      if (match == null) continue;
      final ms = int.tryParse(match.group(1)!);
      if (ms == null) continue;
      final exportedAt = DateTime.fromMillisecondsSinceEpoch(ms);
      if (exportedAt.isBefore(cutoff)) {
        try {
          entity.deleteSync();
        } catch (_) {}
      }
    }
  }
}

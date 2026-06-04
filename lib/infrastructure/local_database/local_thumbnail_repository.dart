import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/thumbnail_entry.dart';
import '../../domain/repositories/thumbnail_repository.dart';

class LocalThumbnailRepository implements ThumbnailRepository {
  LocalThumbnailRepository({Directory? directory}) : _injectedDir = directory;

  final Directory? _injectedDir;
  Directory? _resolvedDir;

  Future<Directory> _dir() async {
    if (_resolvedDir != null) return _resolvedDir!;
    if (_injectedDir != null) {
      _resolvedDir = _injectedDir;
      return _resolvedDir!;
    }
    final base = await getApplicationDocumentsDirectory();
    _resolvedDir = Directory(p.join(base.path, 'thumbnails'));
    await _resolvedDir!.create(recursive: true);
    return _resolvedDir!;
  }

  File _file(Directory dir, int releaseId) =>
      File(p.join(dir.path, 'thumb_$releaseId.jpg'));

  @override
  Future<String?> getLocalPath(int releaseId) async {
    final dir = await _dir();
    final file = _file(dir, releaseId);
    return await file.exists() ? file.path : null;
  }

  @override
  Future<void> save(int releaseId, List<int> bytes) async {
    final dir = await _dir();
    await _file(dir, releaseId).writeAsBytes(bytes);
  }

  @override
  Future<void> remove(int releaseId) async {
    final dir = await _dir();
    final file = _file(dir, releaseId);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> exists(int releaseId) async {
    final dir = await _dir();
    return _file(dir, releaseId).exists();
  }

  @override
  Future<int> totalSizeBytes() async {
    final dir = await _dir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        total += stat.size;
      }
    }
    return total;
  }

  @override
  Future<List<ThumbnailEntry>> listEntries() async {
    final dir = await _dir();
    if (!await dir.exists()) return [];
    final entries = <ThumbnailEntry>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        final name = p.basenameWithoutExtension(entity.path);
        if (name.startsWith('thumb_')) {
          final releaseId = int.tryParse(name.substring('thumb_'.length));
          if (releaseId != null) {
            final stat = await entity.stat();
            entries.add(
              ThumbnailEntry(
                releaseId: releaseId,
                lastModified: stat.modified,
                sizeBytes: stat.size,
              ),
            );
          }
        }
      }
    }
    return entries;
  }

  @override
  Future<void> removeAll() async {
    final dir = await _dir();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File) await entity.delete();
    }
  }
}

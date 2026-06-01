import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
}

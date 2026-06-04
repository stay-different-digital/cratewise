import 'package:cratewise/application/services/thumbnail_eviction_service.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

class _FakeRepo implements ThumbnailRepository {
  final Map<int, List<int>> _data = {};
  final Map<int, DateTime> _modified = {};

  void add(int id, {required int sizeBytes, required DateTime modified}) {
    _data[id] = List.generate(sizeBytes, (i) => i);
    _modified[id] = modified;
  }

  List<int> get removedIds => _removedIds;
  final List<int> _removedIds = [];

  @override
  Future<String?> getLocalPath(int id) async =>
      _data.containsKey(id) ? '/fake/$id.jpg' : null;
  @override
  Future<void> save(int id, List<int> bytes) async => _data[id] = bytes;
  @override
  Future<void> remove(int id) async {
    _data.remove(id);
    _modified.remove(id);
    _removedIds.add(id);
  }

  @override
  Future<bool> exists(int id) async => _data.containsKey(id);

  @override
  Future<int> totalSizeBytes() async =>
      _data.values.fold<int>(0, (sum, b) => sum + b.length);

  @override
  Future<List<ThumbnailEntry>> listEntries() async => _data.keys
      .map(
        (id) => ThumbnailEntry(
          releaseId: id,
          lastModified: _modified[id]!,
          sizeBytes: _data[id]!.length,
        ),
      )
      .toList();

  @override
  Future<void> removeAll() async {
    _removedIds.addAll(_data.keys);
    _data.clear();
    _modified.clear();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ThumbnailEvictionService.currentSizeBytes', () {
    test('returns 0 for empty cache', () async {
      final repo = _FakeRepo();
      final service = ThumbnailEvictionService(repository: repo);
      expect(await service.currentSizeBytes(), 0);
    });

    test('returns total bytes of all entries', () async {
      final repo = _FakeRepo()
        ..add(1, sizeBytes: 100, modified: DateTime(2026, 1, 1))
        ..add(2, sizeBytes: 200, modified: DateTime(2026, 1, 2));
      final service = ThumbnailEvictionService(repository: repo);
      expect(await service.currentSizeBytes(), 300);
    });
  });

  group('ThumbnailEvictionService.clearAll', () {
    test('removes all entries', () async {
      final repo = _FakeRepo()
        ..add(1, sizeBytes: 100, modified: DateTime(2026, 1, 1))
        ..add(2, sizeBytes: 200, modified: DateTime(2026, 1, 2));
      final service = ThumbnailEvictionService(repository: repo);
      await service.clearAll();
      expect(await service.currentSizeBytes(), 0);
    });

    test('all entry ids are removed', () async {
      final repo = _FakeRepo()
        ..add(10, sizeBytes: 50, modified: DateTime(2026, 1, 1))
        ..add(20, sizeBytes: 50, modified: DateTime(2026, 1, 2));
      final service = ThumbnailEvictionService(repository: repo);
      await service.clearAll();
      expect(repo.removedIds, containsAll([10, 20]));
    });
  });

  group('ThumbnailEvictionService.evictIfNeeded', () {
    test('does nothing when total is under the limit', () async {
      final repo = _FakeRepo()
        ..add(1, sizeBytes: 100, modified: DateTime(2026, 1, 1));
      final service = ThumbnailEvictionService(repository: repo);
      await service.evictIfNeeded(maxBytes: 500);
      expect(repo.removedIds, isEmpty);
    });

    test('does nothing when total equals the limit', () async {
      final repo = _FakeRepo()
        ..add(1, sizeBytes: 500, modified: DateTime(2026, 1, 1));
      final service = ThumbnailEvictionService(repository: repo);
      await service.evictIfNeeded(maxBytes: 500);
      expect(repo.removedIds, isEmpty);
    });

    test('evicts oldest entry first when over limit', () async {
      final repo = _FakeRepo()
        ..add(1, sizeBytes: 300, modified: DateTime(2026, 1, 1)) // oldest
        ..add(2, sizeBytes: 300, modified: DateTime(2026, 1, 2));
      final service = ThumbnailEvictionService(repository: repo);
      await service.evictIfNeeded(maxBytes: 400);
      expect(repo.removedIds, contains(1));
      expect(repo.removedIds, isNot(contains(2)));
    });

    test('evicts multiple oldest entries until under limit', () async {
      final repo = _FakeRepo()
        ..add(1, sizeBytes: 100, modified: DateTime(2026, 1, 1)) // oldest
        ..add(2, sizeBytes: 100, modified: DateTime(2026, 1, 2))
        ..add(3, sizeBytes: 100, modified: DateTime(2026, 1, 3)) // newest
        ;
      final service = ThumbnailEvictionService(repository: repo);
      await service.evictIfNeeded(maxBytes: 150);
      expect(repo.removedIds, containsAll([1, 2]));
      expect(repo.removedIds, isNot(contains(3)));
    });

    test('stops evicting once under limit', () async {
      final repo = _FakeRepo()
        ..add(1, sizeBytes: 100, modified: DateTime(2026, 1, 1))
        ..add(2, sizeBytes: 100, modified: DateTime(2026, 1, 2))
        ..add(3, sizeBytes: 100, modified: DateTime(2026, 1, 3));
      final service = ThumbnailEvictionService(repository: repo);
      await service.evictIfNeeded(maxBytes: 250);
      expect(repo.removedIds, hasLength(1));
    });

    test(
      'uses kDefaultThumbnailCacheLimitBytes when no maxBytes supplied',
      () async {
        final repo = _FakeRepo()
          ..add(1, sizeBytes: 100, modified: DateTime(2026, 1, 1));
        final service = ThumbnailEvictionService(repository: repo);
        await service.evictIfNeeded();
        expect(repo.removedIds, isEmpty); // 100 B << 200 MB
      },
    );

    test('evicts nothing from empty cache', () async {
      final repo = _FakeRepo();
      final service = ThumbnailEvictionService(repository: repo);
      await expectLater(service.evictIfNeeded(maxBytes: 0), completes);
    });
  });
}

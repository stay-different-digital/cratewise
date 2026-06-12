import 'package:cratewise/application/services/thumbnail_eviction_service.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeThumbnailRepository implements ThumbnailRepository {
  int _totalBytes;
  bool removeAllCalled = false;

  _FakeThumbnailRepository({int totalBytes = 0}) : _totalBytes = totalBytes;

  @override
  Future<int> totalSizeBytes() async => _totalBytes;

  @override
  Future<void> removeAll() async {
    _totalBytes = 0;
    removeAllCalled = true;
  }

  @override
  Future<List<ThumbnailEntry>> listEntries() async => [];

  @override
  Future<String?> getLocalPath(int id) async => null;
  @override
  Future<void> save(int id, List<int> bytes) async {}
  @override
  Future<void> remove(int id) async {}
  @override
  Future<bool> exists(int id) async => false;
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SettingsScreen — thumbnail cache section', () {
    testWidgets('shows Thumbnail Cache tile when eviction service provided', (
      tester,
    ) async {
      final repo = _FakeThumbnailRepository(totalBytes: 0);
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(SettingsScreen(evictionService: eviction)));
      await tester.pump();

      expect(find.text('Thumbnail Cache'), findsOneWidget);
    });

    testWidgets('does not show Thumbnail Cache tile without eviction service', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pump();

      expect(find.text('Thumbnail Cache'), findsNothing);
    });

    testWidgets('shows formatted size when cache has bytes', (tester) async {
      final repo = _FakeThumbnailRepository(
        totalBytes: 52 * 1024 * 1024, // 52 MB
      );
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(SettingsScreen(evictionService: eviction)));
      await tester.pump();

      expect(find.textContaining('MB'), findsWidgets);
    });

    testWidgets('shows "< 1 MB" for cache under 1 MB', (tester) async {
      final repo = _FakeThumbnailRepository(totalBytes: 512 * 1024); // 0.5 MB
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(SettingsScreen(evictionService: eviction)));
      await tester.pump();

      expect(find.text('< 1 MB'), findsOneWidget);
    });

    testWidgets('Clear button is visible when cache is non-empty', (
      tester,
    ) async {
      final repo = _FakeThumbnailRepository(totalBytes: 10 * 1024 * 1024);
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(SettingsScreen(evictionService: eviction)));
      await tester.pump();

      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('tapping Clear calls removeAll and updates subtitle', (
      tester,
    ) async {
      final repo = _FakeThumbnailRepository(totalBytes: 10 * 1024 * 1024);
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(SettingsScreen(evictionService: eviction)));
      await tester.pump();

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(repo.removeAllCalled, isTrue);
      expect(find.text('< 1 MB'), findsOneWidget);
    });

    testWidgets('Clear button is disabled when cache size is 0', (
      tester,
    ) async {
      final repo = _FakeThumbnailRepository(totalBytes: 0);
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(SettingsScreen(evictionService: eviction)));
      await tester.pump();

      final btn = tester.widget<TextButton>(find.byType(TextButton));
      expect(btn.onPressed, isNull);
    });
  });

  group('SettingsScreen — send feedback tile (US-64)', () {
    testWidgets('shows the Send feedback tile', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pump();

      expect(find.text('Send feedback'), findsOneWidget);
    });
  });

  group('SettingsScreen — about tile (US-68)', () {
    testWidgets('shows the About tile', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pump();

      expect(find.text('About Cratewise'), findsOneWidget);
    });
  });
}

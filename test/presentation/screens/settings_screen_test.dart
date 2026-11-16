import 'package:cratewise/application/services/thumbnail_eviction_service.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/pending_discogs_deletion.dart';
import 'package:cratewise/domain/models/thumbnail_entry.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/collection_repository.dart';
import 'package:cratewise/domain/repositories/pending_discogs_deletion_repository.dart';
import 'package:cratewise/domain/repositories/thumbnail_repository.dart';
import 'package:cratewise/domain/repositories/wishlist_repository.dart';
import 'package:cratewise/l10n/app_localizations.dart';
import 'package:cratewise/presentation/screens/settings_screen.dart';
import 'package:cratewise/application/services/discogs_auto_sync_service.dart';
import 'package:cratewise/application/services/discogs_connection_service.dart';
import 'package:cratewise/domain/models/connection_status.dart';
import 'package:cratewise/infrastructure/secure_storage/secure_key_value_store.dart';
import 'package:cratewise/shared/discogs_credentials_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeThumbnailRepository implements ThumbnailRepository {
  int _totalBytes;
  bool removeAllCalled = false;

  _FakeThumbnailRepository({this._totalBytes = 0});

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

CollectionItem _collectionItem(String id) => CollectionItem(
  id: id,
  discogsReleaseId: id.hashCode,
  artist: 'Artist',
  title: 'Title',
  mediaCondition: RecordCondition.veryGoodPlus,
  sleeveCondition: RecordCondition.veryGood,
  tags: const [],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

WishlistItem _wishlistItem(String id) => WishlistItem(
  id: id,
  discogsReleaseId: id.hashCode,
  artist: 'Artist',
  title: 'Title',
  priority: WishlistPriority.medium,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

class _FakeCollectionRepo implements CollectionRepository {
  _FakeCollectionRepo({int count = 0, this.throwOnDelete = false})
    : items = List.generate(count, (i) => _collectionItem('c$i'));

  List<CollectionItem> items;
  bool throwOnDelete;
  int deleteAllCount = 0;

  @override
  Future<List<CollectionItem>> getAll() async => items;

  @override
  Future<void> deleteAll() async {
    deleteAllCount++;
    if (throwOnDelete) throw Exception('storage failure');
    items = [];
  }

  @override
  Future<CollectionItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(CollectionItem item) async {}
  @override
  Future<void> update(CollectionItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakeWishlistRepo implements WishlistRepository {
  _FakeWishlistRepo({int count = 0})
    : items = List.generate(count, (i) => _wishlistItem('w$i'));

  List<WishlistItem> items;
  int deleteAllCount = 0;

  @override
  Future<List<WishlistItem>> getAll() async => items;

  @override
  Future<void> deleteAll() async {
    deleteAllCount++;
    items = [];
  }

  @override
  Future<WishlistItem?> getById(String id) async => null;
  @override
  Future<bool> containsRelease(int discogsReleaseId) async => false;
  @override
  Future<void> add(WishlistItem item) async {}
  @override
  Future<void> update(WishlistItem item) async {}
  @override
  Future<void> remove(String id) async {}
}

class _FakeDeletionRepo implements PendingDiscogsDeletionRepository {
  final List<DeletionEntityType> deletedTypes = [];
  int addCount = 0;

  @override
  Future<void> add(PendingDiscogsDeletion deletion) async {
    addCount++;
  }

  @override
  Future<void> deleteAllByType(DeletionEntityType entityType) async {
    deletedTypes.add(entityType);
  }

  @override
  Future<List<PendingDiscogsDeletion>> getByType(
    DeletionEntityType entityType,
  ) async => [];
  @override
  Future<bool> containsRelease(
    int discogsReleaseId,
    DeletionEntityType entityType,
  ) async => false;
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> removeByRelease(
    int discogsReleaseId,
    DeletionEntityType entityType,
  ) async {}
}

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Widget _wrapNl(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('nl'),
  home: Scaffold(body: child),
);

// Builds a SettingsScreen with hermetic local-data fakes so the "Local data"
// section never opens a real on-device database during tests.
class _Prefs implements SecureKeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read({required String key}) async => values[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      values[key] = value;
  @override
  Future<void> delete({required String key}) async => values.remove(key);
}

class _Connection extends DiscogsConnectionService {
  _Connection({this.connected = false});
  bool connected;
  @override
  Future<ConnectionStatus> loadStatus() async => connected
      ? ConnectionStatus.connected('digger')
      : const ConnectionStatus.disconnected();
}

SettingsScreen _settings({
  ThumbnailEvictionService? evictionService,
  DiscogsAutoSyncService? autoSync,
  DiscogsConnectionService? connection,
  CollectionRepository? collection,
  WishlistRepository? wishlist,
  PendingDiscogsDeletionRepository? deletions,
  Future<String> Function()? appVersionLoader,
}) => SettingsScreen(
  evictionService: evictionService,
  collectionRepository: collection ?? _FakeCollectionRepo(),
  wishlistRepository: wishlist ?? _FakeWishlistRepo(),
  deletionRepository: deletions ?? _FakeDeletionRepo(),
  appVersionLoader: appVersionLoader,
  autoSyncService: autoSync ?? DiscogsAutoSyncService(preferences: _Prefs()),
  connectionService: connection ?? _Connection(),
);

Finder _clearIn(String tileTitle) => find.descendant(
  of: find.widgetWithText(ListTile, tileTitle),
  matching: find.widgetWithText(TextButton, 'Clear'),
);

// Scrolls the main list until the Clear button is visible, then taps it.
// Required because the "Saved searches" tile (added in US-117) pushes the
// LocalDataSection below the default 800×600 test viewport. The pumpAndSettle
// after ensureVisible lets _loadCounts() complete (the section was off-screen
// and not yet built until the scroll brings it into view).
Future<void> _tapClearIn(WidgetTester tester, String tileTitle) async {
  final btn = _clearIn(tileTitle);
  await tester.ensureVisible(btn);
  await tester.pumpAndSettle();
  await tester.tap(btn);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // The tests find tiles without scrolling; a tall viewport keeps the whole
  // lazily built Settings list on screen as tiles are added above (US-144).
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(800, 2400);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  group('SettingsScreen — thumbnail cache section', () {
    testWidgets('shows Thumbnail Cache tile when eviction service provided', (
      tester,
    ) async {
      final repo = _FakeThumbnailRepository(totalBytes: 0);
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(_settings(evictionService: eviction)));
      await tester.pump();

      expect(find.text('Thumbnail Cache'), findsOneWidget);
    });

    testWidgets('does not show Thumbnail Cache tile without eviction service', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_settings()));
      await tester.pump();

      expect(find.text('Thumbnail Cache'), findsNothing);
    });

    testWidgets('shows formatted size when cache has bytes', (tester) async {
      final repo = _FakeThumbnailRepository(
        totalBytes: 52 * 1024 * 1024, // 52 MB
      );
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(_settings(evictionService: eviction)));
      await tester.pump();

      expect(find.textContaining('MB'), findsWidgets);
    });

    testWidgets('shows "< 1 MB" for cache under 1 MB', (tester) async {
      final repo = _FakeThumbnailRepository(totalBytes: 512 * 1024); // 0.5 MB
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(_settings(evictionService: eviction)));
      await tester.pump();

      expect(find.text('< 1 MB'), findsOneWidget);
    });

    testWidgets('Clear button is visible when cache is non-empty', (
      tester,
    ) async {
      final repo = _FakeThumbnailRepository(totalBytes: 10 * 1024 * 1024);
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(_settings(evictionService: eviction)));
      await tester.pump();

      expect(_clearIn('Thumbnail Cache'), findsOneWidget);
    });

    testWidgets('tapping Clear calls removeAll and updates subtitle', (
      tester,
    ) async {
      final repo = _FakeThumbnailRepository(totalBytes: 10 * 1024 * 1024);
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(_settings(evictionService: eviction)));
      await tester.pump();

      await tester.tap(_clearIn('Thumbnail Cache'));
      await tester.pumpAndSettle();

      expect(repo.removeAllCalled, isTrue);
      expect(find.text('< 1 MB'), findsOneWidget);
    });

    testWidgets('Clear button is disabled when cache size is 0', (
      tester,
    ) async {
      final repo = _FakeThumbnailRepository(totalBytes: 0);
      final eviction = ThumbnailEvictionService(repository: repo);

      await tester.pumpWidget(_wrap(_settings(evictionService: eviction)));
      await tester.pump();

      final btn = tester.widget<TextButton>(_clearIn('Thumbnail Cache'));
      expect(btn.onPressed, isNull);
    });
  });

  group('SettingsScreen — local data section (US-82)', () {
    testWidgets('shows the collection and wishlist item counts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _settings(
            collection: _FakeCollectionRepo(count: 2),
            wishlist: _FakeWishlistRepo(count: 1),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Clear collection'), findsOneWidget);
      expect(find.text('Clear wishlist'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('Clear buttons are disabled when both lists are empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_settings()));
      await tester.pump();

      expect(
        tester.widget<TextButton>(_clearIn('Clear collection')).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(_clearIn('Clear wishlist')).onPressed,
        isNull,
      );
    });

    testWidgets('confirm dialog states it is local-only and irreversible', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_settings(collection: _FakeCollectionRepo(count: 3))),
      );
      await tester.pump();

      await _tapClearIn(tester, 'Clear collection');
      await tester.pumpAndSettle();

      expect(find.text('Clear collection?'), findsOneWidget);
      expect(
        find.textContaining('permanently removes all 3 items'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Your Discogs account is not affected'),
        findsOneWidget,
      );
    });

    testWidgets(
      'confirming clears the collection, fires a snackbar, drops tombstones '
      'and creates none',
      (tester) async {
        final collection = _FakeCollectionRepo(count: 2);
        final deletions = _FakeDeletionRepo();
        await tester.pumpWidget(
          _wrap(
            _settings(
              collection: collection,
              // Distinct non-zero count so the post-clear "0 items" is
              // unambiguously the collection tile.
              wishlist: _FakeWishlistRepo(count: 5),
              deletions: deletions,
            ),
          ),
        );
        await tester.pump();

        await _tapClearIn(tester, 'Clear collection');
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(TextButton, 'Clear'),
          ),
        );
        await tester.pumpAndSettle();

        expect(collection.deleteAllCount, 1);
        // Tombstones for the cleared entity are discarded…
        expect(deletions.deletedTypes, [DeletionEntityType.collection]);
        // …and clearing never records new tombstones (account-switch safety).
        expect(deletions.addCount, 0);
        expect(
          find.text('Cleared 2 items from your collection.'),
          findsOneWidget,
        );
        expect(find.text('0 items'), findsOneWidget);
      },
    );

    testWidgets('cancelling the dialog leaves the data intact', (tester) async {
      final collection = _FakeCollectionRepo(count: 2);
      await tester.pumpWidget(_wrap(_settings(collection: collection)));
      await tester.pump();

      await _tapClearIn(tester, 'Clear collection');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(collection.deleteAllCount, 0);
      expect(find.text('2 items'), findsOneWidget);
    });

    testWidgets('clearing the collection leaves the wishlist untouched', (
      tester,
    ) async {
      final collection = _FakeCollectionRepo(count: 2);
      final wishlist = _FakeWishlistRepo(count: 3);
      final deletions = _FakeDeletionRepo();
      await tester.pumpWidget(
        _wrap(
          _settings(
            collection: collection,
            wishlist: wishlist,
            deletions: deletions,
          ),
        ),
      );
      await tester.pump();

      await _tapClearIn(tester, 'Clear collection');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Clear'),
        ),
      );
      await tester.pumpAndSettle();

      expect(wishlist.deleteAllCount, 0);
      expect(deletions.deletedTypes, [DeletionEntityType.collection]);
      expect(find.text('3 items'), findsOneWidget);
    });

    testWidgets('a storage failure shows a non-destructive error', (
      tester,
    ) async {
      final collection = _FakeCollectionRepo(count: 2, throwOnDelete: true);
      await tester.pumpWidget(_wrap(_settings(collection: collection)));
      await tester.pump();

      await _tapClearIn(tester, 'Clear collection');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Clear'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not clear your collection.'), findsOneWidget);
      // The count is unchanged — nothing was destroyed.
      expect(find.text('2 items'), findsOneWidget);
    });
  });

  group('SettingsScreen — send feedback tile (US-64)', () {
    testWidgets('shows the Send feedback tile', (tester) async {
      await tester.pumpWidget(_wrap(_settings()));
      await tester.pump();

      // The added "Local data" section pushes lower tiles off the test
      // viewport, so scroll the settings list down to them first.
      await tester.scrollUntilVisible(
        find.text('Send feedback'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Send feedback'), findsOneWidget);
    });
  });

  group('SettingsScreen — about tile (US-68)', () {
    testWidgets('shows the About tile', (tester) async {
      await tester.pumpWidget(_wrap(_settings()));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('About Cratewise'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('About Cratewise'), findsOneWidget);
    });
  });

  group('SettingsScreen — version footer (US-72)', () {
    testWidgets('shows version string below the about tile', (tester) async {
      await tester.pumpWidget(
        _wrap(_settings(appVersionLoader: () async => '1.0.0.1')),
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('1.0.0.1'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1.0.0.1'), findsOneWidget);
    });
  });

  group('SettingsScreen — NL locale (US-113)', () {
    testWidgets('shows Dutch labels when locale is nl', (tester) async {
      await tester.pumpWidget(_wrapNl(_settings()));
      await tester.pump();

      expect(find.text('Importeren en exporteren'), findsOneWidget);
      expect(find.text('Lokale gegevens'), findsOneWidget);
    });
  });

  group('SettingsScreen — auto-sync switch (US-144)', () {
    SwitchListTile tile(WidgetTester tester) => tester.widget<SwitchListTile>(
      find.byKey(const Key('auto-sync-switch')),
    );

    testWidgets('without a linked account: off, disabled, points to linking', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_settings()));
      await tester.pumpAndSettle();

      expect(tile(tester).value, isFalse);
      expect(tile(tester).onChanged, isNull);
      expect(
        find.text('Connect your Discogs account above to use this.'),
        findsOneWidget,
      );
    });

    testWidgets('with an account: off by default, turning it on persists', (
      tester,
    ) async {
      final prefs = _Prefs();
      final service = DiscogsAutoSyncService(preferences: prefs);
      await tester.pumpWidget(
        _wrap(
          _settings(
            autoSync: service,
            connection: _Connection(connected: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tile(tester).value, isFalse);

      await tester.tap(find.byKey(const Key('auto-sync-switch')));
      await tester.pumpAndSettle();

      expect(tile(tester).value, isTrue);
      expect(await service.isEnabled(), isTrue);
    });

    testWidgets('becomes usable as soon as an account is linked', (
      tester,
    ) async {
      final connection = _Connection();
      await tester.pumpWidget(_wrap(_settings(connection: connection)));
      await tester.pumpAndSettle();
      expect(tile(tester).onChanged, isNull);

      connection.connected = true;
      discogsCredentialsNotifier.value++;
      await tester.pumpAndSettle();

      expect(tile(tester).onChanged, isNotNull);
    });

    testWidgets('explains when Discogs rejected the token', (tester) async {
      final prefs = _Prefs()..values['discogs_auto_sync_revoked'] = 'true';
      await tester.pumpWidget(
        _wrap(
          _settings(
            autoSync: DiscogsAutoSyncService(preferences: prefs),
            connection: _Connection(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Discogs rejected your token'),
        findsOneWidget,
      );
    });
  });
}

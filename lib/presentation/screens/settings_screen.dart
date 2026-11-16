import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_repositories.dart';
import '../../app/locale_preference.dart';
import '../../app/app.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../application/services/discogs_auto_sync_service.dart';
import '../../application/services/discogs_connection_service.dart';
import '../../application/services/thumbnail_eviction_service.dart';
import '../../shared/discogs_credentials_notifier.dart';
import '../../domain/models/pending_discogs_deletion.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/pending_discogs_deletion_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../widgets/about_section_tile.dart';
import '../widgets/discogs_token_section.dart';
import '../widgets/send_feedback_tile.dart';
import '../widgets/version_footer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.evictionService,
    this.autoSyncService,
    this.connectionService,
    this.collectionRepository,
    this.wishlistRepository,
    this.deletionRepository,
    this.appVersionLoader,
  });

  final ThumbnailEvictionService? evictionService;
  // Injected only in tests (US-144).
  final DiscogsAutoSyncService? autoSyncService;
  final DiscogsConnectionService? connectionService;

  // Injected only in tests; in production the Local data section constructs its
  // own repositories from the shared on-device database.
  final CollectionRepository? collectionRepository;
  final WishlistRepository? wishlistRepository;
  final PendingDiscogsDeletionRepository? deletionRepository;
  final Future<String> Function()? appVersionLoader;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DiscogsTokenSection(),
        const SizedBox(height: 8),
        _AutoSyncTile(
          service: autoSyncService ?? DiscogsAutoSyncService.shared,
          connection: connectionService ?? DiscogsConnectionService(),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.import_export),
          title: Text(l10n.settingsImportExport),
          subtitle: Text(l10n.settingsImportExportSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.importExport),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_toggle_off_outlined),
          title: Text(l10n.settingsFailedActions),
          subtitle: Text(l10n.settingsFailedActionsSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.failedActions),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bookmarks_outlined),
          title: const Text('Saved searches & filters'),
          subtitle: const Text('Manage your saved searches and filter sets'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.savedSearches),
        ),
        if (evictionService != null) ...[
          const SizedBox(height: 8),
          _ThumbnailCacheSection(evictionService: evictionService!),
        ],
        const SizedBox(height: 8),
        _LocalDataSection(
          collectionRepository: collectionRepository,
          wishlistRepository: wishlistRepository,
          deletionRepository: deletionRepository,
        ),
        const SizedBox(height: 8),
        const _LanguageSection(),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.tour_outlined),
          title: Text(l10n.settingsTourRestart),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.onboarding),
        ),
        const SizedBox(height: 8),
        const SendFeedbackTile(),
        const SizedBox(height: 8),
        const AboutSectionTile(),
        VersionFooter(appVersionLoader: appVersionLoader),
      ],
    );
  }
}

class _ThumbnailCacheSection extends StatefulWidget {
  const _ThumbnailCacheSection({required this.evictionService});
  final ThumbnailEvictionService evictionService;

  @override
  State<_ThumbnailCacheSection> createState() => _ThumbnailCacheSectionState();
}

class _ThumbnailCacheSectionState extends State<_ThumbnailCacheSection> {
  int? _sizeBytes;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  Future<void> _loadSize() async {
    final size = await widget.evictionService.currentSizeBytes();
    if (!mounted) return;
    setState(() => _sizeBytes = size);
  }

  Future<void> _clear() async {
    setState(() => _clearing = true);
    await widget.evictionService.clearAll();
    if (!mounted) return;
    setState(() {
      _sizeBytes = 0;
      _clearing = false;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '< 1 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = _sizeBytes == null
        ? l10n.calculating
        : _formatSize(_sizeBytes!);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.image_outlined),
      title: Text(l10n.settingsThumbnailCache),
      subtitle: Text(subtitle),
      trailing: _clearing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: _sizeBytes == 0 ? null : _clear,
              child: Text(l10n.actionClear),
            ),
    );
  }
}

/// "Local data" section (US-82): bulk-clear the locally stored collection and
/// wishlist. Clearing is local-only and never propagates to Discogs — when a
/// user switches accounts the stored token may already point at a different
/// account, so creating `PendingDiscogsDeletion` tombstones here could delete
/// records from the wrong account. Any existing tombstones for the cleared
/// entity are discarded so the Pending Deletions screen shows nothing orphaned.
class _LocalDataSection extends StatefulWidget {
  const _LocalDataSection({
    this.collectionRepository,
    this.wishlistRepository,
    this.deletionRepository,
  });

  final CollectionRepository? collectionRepository;
  final WishlistRepository? wishlistRepository;
  final PendingDiscogsDeletionRepository? deletionRepository;

  @override
  State<_LocalDataSection> createState() => _LocalDataSectionState();
}

class _LocalDataSectionState extends State<_LocalDataSection> {
  late final CollectionRepository _collection;
  late final WishlistRepository _wishlist;
  late final PendingDiscogsDeletionRepository _deletions;

  int? _collectionCount;
  int? _wishlistCount;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    if (widget.collectionRepository != null &&
        widget.wishlistRepository != null &&
        widget.deletionRepository != null) {
      _collection = widget.collectionRepository!;
      _wishlist = widget.wishlistRepository!;
      _deletions = widget.deletionRepository!;
    } else {
      final repos = AppRepositoriesScope.of(context);
      _collection = widget.collectionRepository ?? repos.collection;
      _wishlist = widget.wishlistRepository ?? repos.wishlist;
      _deletions = widget.deletionRepository ?? repos.pendingDeletion;
    }
    _loadCounts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCounts() async {
    try {
      final collection = (await _collection.getAll()).length;
      final wishlist = (await _wishlist.getAll()).length;
      if (!mounted) return;
      setState(() {
        _collectionCount = collection;
        _wishlistCount = wishlist;
      });
    } catch (_) {
      // Leave the counts as "Calculating…"; the tiles stay disabled, which is
      // the safe default — nothing destructive is offered on a load failure.
    }
  }

  Future<bool> _confirm({required String entity, required int count}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear $entity?'),
        content: Text(
          'This permanently removes all $count '
          '${count == 1 ? 'item' : 'items'} from this device. '
          'Your Discogs account is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(ctx)!.actionClear),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _clearCollection() async {
    final count = _collectionCount ?? 0;
    if (count == 0) return;
    if (!await _confirm(entity: 'collection', count: count)) return;
    await _clear(
      entityType: DeletionEntityType.collection,
      deleteItems: _collection.deleteAll,
      successLabel: 'collection',
      onCleared: () => _collectionCount = 0,
    );
  }

  Future<void> _clearWishlist() async {
    final count = _wishlistCount ?? 0;
    if (count == 0) return;
    if (!await _confirm(entity: 'wishlist', count: count)) return;
    await _clear(
      entityType: DeletionEntityType.wishlist,
      deleteItems: _wishlist.deleteAll,
      successLabel: 'wishlist',
      onCleared: () => _wishlistCount = 0,
    );
  }

  Future<void> _clear({
    required DeletionEntityType entityType,
    required Future<void> Function() deleteItems,
    required String successLabel,
    required VoidCallback onCleared,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final count = entityType == DeletionEntityType.collection
        ? (_collectionCount ?? 0)
        : (_wishlistCount ?? 0);
    setState(() => _clearing = true);
    try {
      // Discard tombstones first: they are the less-important data, so a
      // failure before the items are touched leaves everything intact.
      await _deletions.deleteAllByType(entityType);
      await deleteItems();
      if (!mounted) return;
      setState(() {
        onCleared();
        _clearing = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cleared $count ${count == 1 ? 'item' : 'items'} '
            'from your $successLabel.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _clearing = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not clear your $successLabel.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destructive = TextButton.styleFrom(
      foregroundColor: theme.colorScheme.error,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            AppLocalizations.of(context)!.settingsLocalData,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _ClearTile(
          icon: Icons.library_music_outlined,
          title: AppLocalizations.of(context)!.settingsClearCollection,
          count: _collectionCount,
          clearing: _clearing,
          buttonStyle: destructive,
          onClear: _clearCollection,
        ),
        _ClearTile(
          icon: Icons.bookmark_border,
          title: AppLocalizations.of(context)!.settingsClearWishlist,
          count: _wishlistCount,
          clearing: _clearing,
          buttonStyle: destructive,
          onClear: _clearWishlist,
        ),
      ],
    );
  }
}

class _ClearTile extends StatelessWidget {
  const _ClearTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.clearing,
    required this.buttonStyle,
    required this.onClear,
  });

  final IconData icon;
  final String title;
  final int? count;
  final bool clearing;
  final ButtonStyle buttonStyle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = count == null
        ? l10n.calculating
        : '$count ${count == 1 ? 'item' : 'items'}';
    final enabled = !clearing && (count ?? 0) > 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: clearing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              style: buttonStyle,
              onPressed: enabled ? onClear : null,
              child: Text(l10n.actionClear),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language section (US-114)
// ---------------------------------------------------------------------------

class _LanguageSection extends StatefulWidget {
  const _LanguageSection();

  @override
  State<_LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<_LanguageSection> {
  static const _locales = <Locale?>[
    null,
    Locale('en'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('nl'),
  ];

  Future<void> _onChanged(Locale? locale) async {
    await saveLocalePreference(locale);
    if (!mounted) return;
    LocaleScope.maybeOf(context)?.value = locale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = LocaleScope.maybeOf(context)?.value;

    String labelFor(Locale? locale) => switch (locale?.languageCode) {
      null => l10n.settingsLanguageSystem,
      'en' => l10n.languageEnglish,
      'de' => l10n.languageGerman,
      'fr' => l10n.languageFrench,
      'es' => l10n.languageSpanish,
      'nl' => l10n.languageDutch,
      _ => locale!.languageCode,
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.language),
      title: Text(l10n.settingsLanguage),
      trailing: DropdownButton<Locale?>(
        value: current,
        underline: const SizedBox.shrink(),
        items: [
          for (final locale in _locales)
            DropdownMenuItem(value: locale, child: Text(labelFor(locale))),
        ],
        onChanged: _onChanged,
      ),
    );
  }
}

/// The "Sync automatically with Discogs" switch (US-144). Usable only with a
/// linked account; reloads when the account is linked or unlinked above.
class _AutoSyncTile extends StatefulWidget {
  const _AutoSyncTile({required this.service, required this.connection});

  final DiscogsAutoSyncService service;
  final DiscogsConnectionService connection;

  @override
  State<_AutoSyncTile> createState() => _AutoSyncTileState();
}

class _AutoSyncTileState extends State<_AutoSyncTile> {
  bool _connected = false;
  bool _enabled = false;
  bool _turnedOffByDiscogs = false;

  @override
  void initState() {
    super.initState();
    discogsCredentialsNotifier.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    discogsCredentialsNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final status = await widget.connection.loadStatus();
    final enabled = await widget.service.isEnabled();
    final turnedOff = await widget.service.wasTurnedOffByDiscogs();
    if (!mounted) return;
    setState(() {
      _connected = status.isConnected;
      _enabled = enabled;
      _turnedOffByDiscogs = turnedOff;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _enabled = value;
      if (value) _turnedOffByDiscogs = false;
    });
    await widget.service.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = _turnedOffByDiscogs
        ? l10n.settingsAutoSyncTurnedOff
        : _connected
        ? l10n.settingsAutoSyncSubtitle
        : l10n.settingsAutoSyncNeedsAccount;
    return SwitchListTile(
      key: const Key('auto-sync-switch'),
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.sync),
      title: Text(l10n.settingsAutoSync),
      subtitle: Text(subtitle),
      value: _connected && _enabled,
      onChanged: _connected ? _toggle : null,
    );
  }
}

import 'package:flutter/material.dart';

import '../../application/services/thumbnail_eviction_service.dart';
import '../../application/use_cases/retry_metadata_refresh_use_case.dart';
import '../../application/use_cases/retry_thumbnail_use_case.dart';
import '../widgets/discogs_token_section.dart';
import 'failed_actions_screen.dart';
import 'import_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.retryUseCase,
    this.thumbnailUseCase,
    this.evictionService,
  });

  final RetryMetadataRefreshUseCase? retryUseCase;
  final RetryThumbnailUseCase? thumbnailUseCase;
  final ThumbnailEvictionService? evictionService;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DiscogsTokenSection(),
        const SizedBox(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.import_export),
          title: const Text('Import & Export'),
          subtitle: const Text('Move records to and from Discogs or CSV files'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ImportExportScreen()),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_toggle_off_outlined),
          title: const Text('Failed Actions'),
          subtitle: const Text('View actions waiting to be retried'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FailedActionsScreen(
                retryUseCase: retryUseCase,
                thumbnailUseCase: thumbnailUseCase,
              ),
            ),
          ),
        ),
        if (evictionService != null) ...[
          const SizedBox(height: 8),
          _ThumbnailCacheSection(evictionService: evictionService!),
        ],
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
    final subtitle = _sizeBytes == null
        ? 'Calculating…'
        : _formatSize(_sizeBytes!);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.image_outlined),
      title: const Text('Thumbnail Cache'),
      subtitle: Text(subtitle),
      trailing: _clearing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: _sizeBytes == 0 ? null : _clear,
              child: const Text('Clear'),
            ),
    );
  }
}

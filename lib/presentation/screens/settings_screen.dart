import 'package:flutter/material.dart';

import '../../application/use_cases/retry_metadata_refresh_use_case.dart';
import '../../application/use_cases/retry_thumbnail_use_case.dart';
import '../widgets/discogs_token_section.dart';
import 'failed_actions_screen.dart';
import 'import_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.retryUseCase, this.thumbnailUseCase});

  final RetryMetadataRefreshUseCase? retryUseCase;
  final RetryThumbnailUseCase? thumbnailUseCase;

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
            MaterialPageRoute<void>(
              builder: (_) => const ImportExportScreen(),
            ),
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
      ],
    );
  }
}

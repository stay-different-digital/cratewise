import 'package:flutter/material.dart';

class ReleaseDetailScreen extends StatelessWidget {
  const ReleaseDetailScreen({super.key, required this.releaseId});

  final int releaseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Release Detail')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.album,
                size: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'Release #$releaseId',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Full release details coming soon.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

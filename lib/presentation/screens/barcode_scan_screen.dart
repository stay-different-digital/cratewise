import 'package:flutter/material.dart';

class BarcodeScanScreen extends StatelessWidget {
  const BarcodeScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('Scan Barcode', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Scan a record barcode to find it on Discogs.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

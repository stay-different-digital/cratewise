import 'package:flutter/material.dart';

import '../../domain/models/release_search_result.dart';
import '../widgets/release_search_result_card.dart';

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

sealed class _ScanState {
  const _ScanState();
}

class _Idle extends _ScanState {
  const _Idle();
}

class _HasResults extends _ScanState {
  const _HasResults(this.results);
  final List<ReleaseSearchResult> results;
}

// ---------------------------------------------------------------------------
// Fake data (placeholder until barcode lookup use case is wired in Phase 4L)
// ---------------------------------------------------------------------------

const _kFakeResults = [
  ReleaseSearchResult(
    id: 249504,
    artist: 'Miles Davis',
    title: 'Kind Of Blue',
    format: 'Vinyl',
    label: 'Columbia',
    country: 'US',
    year: 1959,
  ),
  ReleaseSearchResult(
    id: 1362700,
    artist: 'Miles Davis',
    title: 'Kind Of Blue',
    format: 'CD',
    label: 'Legacy',
    country: 'US',
    year: 1997,
  ),
  ReleaseSearchResult(
    id: 3849102,
    artist: 'Miles Davis',
    title: 'Kind Of Blue',
    format: 'Vinyl',
    label: 'Mobile Fidelity',
    country: 'US',
    year: 2015,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _controller = TextEditingController();
  _ScanState _state = const _Idle();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch() {
    final barcode = _controller.text.trim();
    if (barcode.isEmpty) return;
    setState(() => _state = const _HasResults(_kFakeResults));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ScanAreaPlaceholder(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('barcode-input'),
                  controller: _controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSearch(),
                  decoration: const InputDecoration(
                    hintText: 'Enter barcode manually…',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('search-barcode-button'),
                onPressed: _onSearch,
                child: const Text('Search'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            key: const Key('scan-barcode-button'),
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan barcode'),
          ),
        ),
        Expanded(
          child: switch (_state) {
            _Idle() => const _EmptyState(),
            _HasResults(:final results) => _ResultsList(results: results),
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _ScanAreaPlaceholder extends StatelessWidget {
  const _ScanAreaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('scan-area-placeholder'),
      height: 160,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'Camera preview coming soon',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan or enter a barcode',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Point your camera at a barcode or type one above.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});

  final List<ReleaseSearchResult> results;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          ReleaseSearchResultCard(result: results[index]),
    );
  }
}

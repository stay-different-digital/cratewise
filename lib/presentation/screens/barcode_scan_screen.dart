import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../application/use_cases/barcode_lookup_use_case.dart';
import '../../domain/models/release_search_result.dart';
import '../../shared/errors/app_error.dart';
import '../widgets/release_search_result_card.dart';

// ---------------------------------------------------------------------------
// Lookup state machine
// ---------------------------------------------------------------------------

sealed class _ScanState {
  const _ScanState();
}

class _Idle extends _ScanState {
  const _Idle();
}

class _Loading extends _ScanState {
  const _Loading();
}

/// Stable results state. Tracks accumulated items and pagination sub-states.
class _HasResults extends _ScanState {
  const _HasResults({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalResults,
    this.isLoadingMore = false,
    this.paginationError,
  });

  final List<ReleaseSearchResult> items;
  final int currentPage;
  final int totalPages;
  final int totalResults;
  final bool isLoadingMore;
  final AppError? paginationError;

  bool get hasMore => currentPage < totalPages;

  _HasResults copyWith({
    List<ReleaseSearchResult>? items,
    int? currentPage,
    int? totalPages,
    int? totalResults,
    bool? isLoadingMore,
    AppError? paginationError,
    bool clearPaginationError = false,
  }) {
    return _HasResults(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalResults: totalResults ?? this.totalResults,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: clearPaginationError
          ? null
          : (paginationError ?? this.paginationError),
    );
  }
}

class _NoResults extends _ScanState {
  const _NoResults();
}

class _NoToken extends _ScanState {
  const _NoToken();
}

class _RateLimited extends _ScanState {
  const _RateLimited();
}

class _LookupError extends _ScanState {
  const _LookupError();
}

// ---------------------------------------------------------------------------
// Scan area state
// ---------------------------------------------------------------------------

enum _ScanAreaState { placeholder, scanning, permissionDenied }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, this.useCase});

  final BarcodeLookupUseCase? useCase;

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _controller = TextEditingController();
  late final BarcodeLookupUseCase _useCase;
  _ScanState _state = const _Idle();
  _ScanAreaState _scanAreaState = _ScanAreaState.placeholder;
  String _lastBarcode = '';

  static bool get _supportsScanner =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _useCase = widget.useCase ?? BarcodeLookupUseCase();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final barcode = _controller.text.trim();
    if (barcode.isEmpty) return;
    _lastBarcode = barcode;
    setState(() => _state = const _Loading());
    final result = await _useCase.execute(barcode);
    if (!mounted) return;
    setState(() {
      _state = switch (result) {
        BarcodeLookupSuccess(:final page) => _HasResults(
          items: page.items,
          currentPage: page.currentPage,
          totalPages: page.totalPages,
          totalResults: page.totalResults,
        ),
        BarcodeLookupNoResults() => const _NoResults(),
        BarcodeLookupEmptyInput() => const _Idle(),
        BarcodeLookupNoToken() => const _NoToken(),
        BarcodeLookupRateLimited() => const _RateLimited(),
        BarcodeLookupError() => const _LookupError(),
      };
    });
  }

  Future<void> _loadMore() async {
    if (_state is! _HasResults) return;
    final current = _state as _HasResults;
    if (!current.hasMore || current.isLoadingMore) return;

    setState(
      () => _state = current.copyWith(
        isLoadingMore: true,
        clearPaginationError: true,
      ),
    );

    final result = await _useCase.execute(
      _lastBarcode,
      page: current.currentPage + 1,
    );
    if (!mounted) return;
    setState(() {
      _state = switch (result) {
        BarcodeLookupSuccess(:final page) => _HasResults(
          items: [...current.items, ...page.items],
          currentPage: page.currentPage,
          totalPages: page.totalPages,
          totalResults: page.totalResults,
        ),
        BarcodeLookupRateLimited() => current.copyWith(
          isLoadingMore: false,
          paginationError: const RateLimitedError(),
        ),
        _ => current.copyWith(
          isLoadingMore: false,
          paginationError: const NetworkError(),
        ),
      };
    });
  }

  void _onScanButtonPressed() {
    if (!_supportsScanner) return;
    setState(() => _scanAreaState = _ScanAreaState.scanning);
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_scanAreaState != _ScanAreaState.scanning) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;
    setState(() => _scanAreaState = _ScanAreaState.placeholder);
    _controller.text = rawValue;
    _onSearch();
  }

  void _onScannerPermissionDenied() {
    if (!mounted || _scanAreaState != _ScanAreaState.scanning) return;
    setState(() => _scanAreaState = _ScanAreaState.permissionDenied);
  }

  static const _kWideBreakpoint = 700.0;

  Widget _buildScanArea({double height = 160}) => switch (_scanAreaState) {
    _ScanAreaState.placeholder => _ScanAreaPlaceholder(height: height),
    _ScanAreaState.permissionDenied => _PermissionDeniedScanArea(
      height: height,
    ),
    _ScanAreaState.scanning => _CameraScanArea(
      height: height,
      onDetect: _onBarcodeDetected,
      onPermissionDenied: _onScannerPermissionDenied,
    ),
  };

  Widget _buildResults() => switch (_state) {
    _Idle() => const _EmptyState(),
    _Loading() => const _LoadingIndicator(),
    _HasResults(
      :final items,
      :final totalResults,
      :final isLoadingMore,
      :final paginationError,
      :final hasMore,
    ) =>
      _ResultsList(
        items: items,
        totalResults: totalResults,
        isLoadingMore: isLoadingMore,
        paginationError: paginationError,
        onLoadMore: hasMore && !isLoadingMore ? _loadMore : null,
        onRetry: _loadMore,
      ),
    _NoResults() => const _NoResultsState(),
    _NoToken() => const _NoTokenState(),
    _RateLimited() => const _RateLimitedState(),
    _LookupError() => const _ErrorState(),
  };

  Widget _buildNarrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScanArea(),
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
            onPressed: _onScanButtonPressed,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan barcode'),
          ),
        ),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildScanArea(height: 280),
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
                  onPressed: _onScanButtonPressed,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan barcode'),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _buildResults()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= _kWideBreakpoint
          ? _buildWide(context)
          : _buildNarrow(context),
    );
  }
}

// ---------------------------------------------------------------------------
// Scan area widgets
// ---------------------------------------------------------------------------

class _ScanAreaPlaceholder extends StatelessWidget {
  const _ScanAreaPlaceholder({this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('scan-area-placeholder'),
      height: height,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
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
              "Tap 'Scan barcode' to open your camera",
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

class _PermissionDeniedScanArea extends StatelessWidget {
  const _PermissionDeniedScanArea({this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('scan-area-permission-denied'),
      height: height,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'Camera permission denied',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Allow camera access in Settings to scan barcodes.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _CameraScanArea extends StatelessWidget {
  const _CameraScanArea({
    required this.onDetect,
    required this.onPermissionDenied,
    this.height = 160,
  });

  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onPermissionDenied;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('scan-area-scanner'),
      height: height,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: onDetect,
            errorBuilder: (context, error) {
              if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => onPermissionDenied(),
                );
              }
              return const SizedBox.expand();
            },
          ),
          const _ViewfinderOverlay(),
        ],
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const Key('viewfinder-overlay'),
      painter: _ViewfinderPainter(),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  static const _bracketLength = 24.0;
  static const _strokeWidth = 3.0;
  // Fraction of total width/height between the container edge and viewfinder rect
  static const _inset = 0.15;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final l = size.width * _inset;
    final t = size.height * _inset;
    final r = size.width * (1 - _inset);
    final b = size.height * (1 - _inset);

    // Top-left corner
    canvas.drawLine(Offset(l, t + _bracketLength), Offset(l, t), paint);
    canvas.drawLine(Offset(l, t), Offset(l + _bracketLength, t), paint);
    // Top-right corner
    canvas.drawLine(Offset(r - _bracketLength, t), Offset(r, t), paint);
    canvas.drawLine(Offset(r, t), Offset(r, t + _bracketLength), paint);
    // Bottom-left corner
    canvas.drawLine(Offset(l, b - _bracketLength), Offset(l, b), paint);
    canvas.drawLine(Offset(l, b), Offset(l + _bracketLength, b), paint);
    // Bottom-right corner
    canvas.drawLine(Offset(r - _bracketLength, b), Offset(r, b), paint);
    canvas.drawLine(Offset(r, b - _bracketLength), Offset(r, b), paint);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Body widgets
// ---------------------------------------------------------------------------

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
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
            Text('Scan or enter a barcode', style: theme.textTheme.titleMedium),
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

class _ResultsList extends StatefulWidget {
  const _ResultsList({
    required this.items,
    required this.totalResults,
    required this.isLoadingMore,
    required this.paginationError,
    required this.onLoadMore,
    required this.onRetry,
  });

  final List<ReleaseSearchResult> items;
  final int totalResults;
  final bool isLoadingMore;
  final AppError? paginationError;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;

  @override
  State<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<_ResultsList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  @override
  void didUpdateWidget(_ResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onLoadMore == null && widget.onLoadMore != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onScroll();
      });
    }
  }

  void _onScroll() {
    if (widget.onLoadMore == null || widget.isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      widget.onLoadMore!();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFooter(BuildContext context) {
    if (widget.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(key: Key('pagination-loading')),
        ),
      );
    }
    if (widget.paginationError != null) {
      final isRateLimit = widget.paginationError is RateLimitedError;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextButton.icon(
          key: const Key('pagination-retry'),
          onPressed: widget.onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(
            isRateLimit
                ? 'Rate limited — tap to retry'
                : 'Failed to load more — tap to retry',
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countText = '1–${widget.items.length} of ${widget.totalResults}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            countText,
            key: const Key('result-count'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: widget.items.length + 1,
            separatorBuilder: (_, index) => index < widget.items.length - 1
                ? const SizedBox(height: 8)
                : const SizedBox.shrink(),
            itemBuilder: (context, index) {
              if (index == widget.items.length) return _buildFooter(context);
              return ReleaseSearchResultCard(result: widget.items[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

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
              Icons.search_off,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('No releases found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'No Discogs releases match this barcode. Try a different barcode or check the number.',
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

class _NoTokenState extends StatelessWidget {
  const _NoTokenState();

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
              Icons.link_off,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Discogs account not connected',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Settings to connect your Discogs account.',
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

class _RateLimitedState extends StatelessWidget {
  const _RateLimitedState();

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
              Icons.hourglass_empty,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('Too many requests', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Discogs is limiting requests right now. Wait a moment and try again.',
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

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Could not reach Discogs. An internet connection is needed for barcode lookups.',
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

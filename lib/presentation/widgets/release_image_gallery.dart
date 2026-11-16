import 'dart:io';

import 'package:material_ui/material_ui.dart';

/// Scrollable image gallery for release detail screens.
///
/// - 0 images and no [localThumbnailPath]: shows the album-icon placeholder.
/// - 0 images with [localThumbnailPath]: shows the cached local file (offline).
/// - 1 image: shows a single network image, no dots.
/// - 2+ images: shows a horizontal [PageView] with an overlaid dots indicator.
class ReleaseImageGallery extends StatefulWidget {
  const ReleaseImageGallery({
    super.key,
    this.imageUrls = const [],
    this.localThumbnailPath,
    this.borderRadius = BorderRadius.zero,
  });

  final List<String> imageUrls;
  final String? localThumbnailPath;
  final BorderRadius borderRadius;

  @override
  State<ReleaseImageGallery> createState() => _ReleaseImageGalleryState();
}

class _ReleaseImageGalleryState extends State<ReleaseImageGallery> {
  int _currentPage = 0;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _placeholder(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.album,
          size: 72,
          color: theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }

  Widget _networkImage(ThemeData theme, String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child;

    if (widget.imageUrls.isEmpty && widget.localThumbnailPath == null) {
      child = _placeholder(theme);
    } else if (widget.imageUrls.isEmpty) {
      child = Image.file(
        File(widget.localThumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(theme),
      );
    } else if (widget.imageUrls.length == 1) {
      child = _networkImage(theme, widget.imageUrls.first);
    } else {
      child = Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Semantics(
              label: 'Image ${i + 1} of ${widget.imageUrls.length}',
              child: _networkImage(theme, widget.imageUrls[i]),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: _DotsIndicator(
              count: widget.imageUrls.length,
              current: _currentPage,
            ),
          ),
        ],
      );
    }

    return AspectRatio(
      key: widget.imageUrls.isNotEmpty || widget.localThumbnailPath != null
          ? const Key('release-cover-image')
          : null,
      aspectRatio: 1,
      child: ClipRRect(borderRadius: widget.borderRadius, child: child),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 8 : 6,
          height: active ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
          ),
        );
      }),
    );
  }
}

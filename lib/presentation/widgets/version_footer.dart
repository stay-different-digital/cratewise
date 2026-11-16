import 'package:material_ui/material_ui.dart';

import '../../shared/utils/app_version.dart';

/// Subtle version string footer — reads at runtime, never hardcoded.
class VersionFooter extends StatefulWidget {
  const VersionFooter({super.key, this.appVersionLoader});

  /// Injected only for testing.
  final Future<String> Function()? appVersionLoader;

  @override
  State<VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<VersionFooter> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String v;
    try {
      v = await (widget.appVersionLoader ?? displayAppVersion)();
    } catch (_) {
      v = 'unknown';
    }
    if (!mounted) return;
    setState(() => _version = v);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        _version ?? '',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

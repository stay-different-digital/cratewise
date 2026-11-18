import 'package:material_ui/material_ui.dart';

import '../../shared/utils/app_version.dart';

/// Settings tile showing the app name and runtime version, opening the
/// standard Flutter about dialog with the open-source licence viewer.
class AboutSectionTile extends StatefulWidget {
  const AboutSectionTile({super.key, this.appVersionLoader});

  /// Injected only for testing. Production code passes null and reads the
  /// version via [displayAppVersion].
  final Future<String> Function()? appVersionLoader;

  @override
  State<AboutSectionTile> createState() => _AboutSectionTileState();
}

class _AboutSectionTileState extends State<AboutSectionTile> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    String version;
    try {
      version = await (widget.appVersionLoader ?? displayAppVersion)();
    } catch (_) {
      version = 'unknown';
    }
    if (!mounted) return;
    setState(() => _version = version);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.info_outline),
      title: const Text('About Cratewise'),
      subtitle: Text(_version == null ? 'Loading…' : 'Version $_version'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showAboutDialog(
        context: context,
        applicationName: 'Cratewise',
        applicationVersion: _version ?? '',
        applicationLegalese:
            'Free software under the GNU GPL v3.0. '
            'Uses the Discogs API. '
            'Not affiliated with Discogs.',
      ),
    );
  }
}

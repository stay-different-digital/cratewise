import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings tile showing the app name and runtime version, opening the
/// standard Flutter about dialog with the open-source licence viewer.
class AboutSectionTile extends StatefulWidget {
  const AboutSectionTile({super.key, this.appVersionLoader});

  /// Injected only for testing. Production code passes null and reads the
  /// version from [PackageInfo].
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
      if (widget.appVersionLoader != null) {
        version = await widget.appVersionLoader!();
      } else {
        final info = await PackageInfo.fromPlatform();
        version = '${info.version}+${info.buildNumber}';
      }
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
            'Uses the Discogs API. '
            'Not affiliated with Discogs.',
      ),
    );
  }
}

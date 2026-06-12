import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const feedbackEmailAddress = 'hellowerecratewise@gmail.com';

/// Settings tile that opens the system mail composer with a pre-addressed
/// beta feedback email. The version/platform context is prefilled; nothing
/// is sent without the user composing and sending it themselves.
class SendFeedbackTile extends StatelessWidget {
  const SendFeedbackTile({super.key, this.urlLauncher, this.appVersionLoader});

  /// Injected only for testing. Production code passes null and uses
  /// url_launcher's [launchUrl] directly.
  final Future<bool> Function(Uri uri)? urlLauncher;

  /// Injected only for testing. Production code passes null and reads the
  /// version from [PackageInfo].
  final Future<String> Function()? appVersionLoader;

  Future<String> _loadVersion() async {
    if (appVersionLoader != null) return appVersionLoader!();
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  String _platformDescription() {
    if (kIsWeb) return 'web';
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final version = await _loadVersion();
    final uri = Uri(
      scheme: 'mailto',
      path: feedbackEmailAddress,
      query: _encodeQuery({
        'subject': 'Cratewise beta feedback ($version)',
        'body':
            'Describe what happened:\n\n\n'
            '---\n'
            'App: Cratewise $version\n'
            'Platform: ${_platformDescription()}\n',
      }),
    );

    bool launched;
    try {
      if (urlLauncher != null) {
        launched = await urlLauncher!(uri);
      } else {
        launched = await launchUrl(uri);
      }
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open a mail app. '
            'Email $feedbackEmailAddress instead.',
          ),
        ),
      );
    }
  }

  /// Encodes mailto query parameters with %20 for spaces. The default
  /// [Uri] queryParameters encoding uses '+', which mail apps show
  /// literally in the subject and body.
  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.feedback_outlined),
      title: const Text('Send feedback'),
      subtitle: const Text('Report a problem or share an idea by email'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _sendFeedback(context),
    );
  }
}

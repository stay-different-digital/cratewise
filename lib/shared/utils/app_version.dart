import 'package:package_info_plus/package_info_plus.dart';

/// The user-facing version string, `version.buildNumber`.
/// Single home for the format so every widget shows the same shape.
Future<String> displayAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}.${info.buildNumber}';
}

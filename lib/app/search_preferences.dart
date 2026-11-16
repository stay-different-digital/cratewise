import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../shared/errors/app_error.dart';

// Same storage as the language preference (locale_preference.dart): small
// per-device settings, no separate preferences store.
const _kVinylOnlyKey = 'search_vinyl_only';
const _storage = FlutterSecureStorage();

/// Whether Discogs search is limited to vinyl (US-142). Defaults to `false`
/// so existing users see unchanged results after the update; a storage failure
/// also falls back to `false` rather than breaking search.
Future<bool> loadVinylOnlyPreference() async {
  try {
    return await _storage.read(key: _kVinylOnlyKey) == 'true';
  } catch (e, st) {
    logSwallowed(e, st, 'loadVinylOnlyPreference');
    return false;
  }
}

Future<void> saveVinylOnlyPreference(bool vinylOnly) async {
  try {
    await _storage.write(key: _kVinylOnlyKey, value: '$vinylOnly');
  } catch (e, st) {
    // Not persisting is acceptable: the toggle still applies this session.
    logSwallowed(e, st, 'saveVinylOnlyPreference');
  }
}

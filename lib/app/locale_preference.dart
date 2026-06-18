import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kLocaleKey = 'app_locale';
const _storage = FlutterSecureStorage();

Future<Locale?> loadLocalePreference() async {
  final code = await _storage.read(key: _kLocaleKey);
  return code == null ? null : Locale(code);
}

Future<void> saveLocalePreference(Locale? locale) async {
  if (locale == null) {
    await _storage.delete(key: _kLocaleKey);
  } else {
    await _storage.write(key: _kLocaleKey, value: locale.languageCode);
  }
}

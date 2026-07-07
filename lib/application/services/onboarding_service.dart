import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingService {
  const OnboardingService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'onboarding_complete';

  Future<bool> isComplete() async {
    try {
      return await _storage.read(key: _key) == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> markComplete() async {
    await _storage.write(key: _key, value: 'true');
  }
}

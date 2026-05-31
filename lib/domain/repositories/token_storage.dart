abstract interface class TokenStorage {
  Future<String?> loadToken();
  Future<String?> loadUsername();
  Future<void> saveCredentials({required String token, required String username});
  Future<void> deleteCredentials();
}

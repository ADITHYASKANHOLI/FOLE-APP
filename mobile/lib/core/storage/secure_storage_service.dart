import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String keyAccessToken = 'engivault_access_token';
  static const String keyRefreshToken = 'engivault_refresh_token';
  static const String keyUserId = 'engivault_user_id';
  static const String keyUsername = 'engivault_username';
  static const String keyAdminToken = 'engivault_admin_token';

  // --- Student Session ---

  Future<void> saveStudentSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String username,
  }) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
    await _storage.write(key: keyRefreshToken, value: refreshToken);
    await _storage.write(key: keyUserId, value: userId);
    await _storage.write(key: keyUsername, value: username);
  }

  Future<String?> getAccessToken() async =>
      await _storage.read(key: keyAccessToken);
  Future<String?> getRefreshToken() async =>
      await _storage.read(key: keyRefreshToken);
  Future<String?> getUserId() async => await _storage.read(key: keyUserId);
  Future<String?> getUsername() async => await _storage.read(key: keyUsername);

  Future<void> clearStudentSession() async {
    await _storage.delete(key: keyAccessToken);
    await _storage.delete(key: keyRefreshToken);
    await _storage.delete(key: keyUserId);
    await _storage.delete(key: keyUsername);
  }

  // --- Admin Session ---

  Future<void> saveAdminToken(String token) async {
    await _storage.write(key: keyAdminToken, value: token);
  }

  Future<String?> getAdminToken() async =>
      await _storage.read(key: keyAdminToken);

  Future<void> clearAdminToken() async {
    await _storage.delete(key: keyAdminToken);
  }
}

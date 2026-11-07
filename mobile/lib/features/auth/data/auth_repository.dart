import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ApiClient());
});

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<AuthResponse> login(String username, String password) async {
    final res = await _client.post(
      ApiEndpoints.login,
      data: {
        'username': username.trim(),
        'password': password,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> signup(String username, String password) async {
    final res = await _client.post(
      ApiEndpoints.signup,
      data: {
        'username': username.trim(),
        'password': password,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final res = await _client.post(
      ApiEndpoints.refresh,
      data: {
        'refresh_token': refreshToken,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return AuthSession.fromJson(data['session'] as Map<String, dynamic>? ?? {});
  }

  Future<StudentUser> getMe() async {
    final res = await _client.get(ApiEndpoints.me);
    final data = res.data as Map<String, dynamic>;
    return StudentUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    final res = await _client.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return data['success'] == true;
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort server notification; local credentials will be cleared regardless
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<StudentUser?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(repo, storage);
});

class AuthNotifier extends StateNotifier<AsyncValue<StudentUser?>> {
  final AuthRepository _repo;
  final SecureStorageService _storage;

  AuthNotifier(this._repo, this._storage) : super(const AsyncValue.loading()) {
    checkInitialSession();
  }

  Future<void> checkInitialSession() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }

      // Verify current user with backend
      final user = await _repo.getMe();
      state = AsyncValue.data(user);
    } catch (_) {
      // Try refresh token if access token expired
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final newSession = await _repo.refresh(refreshToken);
          final username = await _storage.getUsername() ?? 'Student';
          final userId = await _storage.getUserId() ?? '';
          await _storage.saveStudentSession(
            accessToken: newSession.accessToken,
            refreshToken: newSession.refreshToken,
            userId: userId,
            username: username,
          );
          final user = await _repo.getMe();
          state = AsyncValue.data(user);
          return;
        }
      } catch (_) {
        // Refresh also failed, clear session
      }

      await _storage.clearStudentSession();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repo.login(username, password);
      await _storage.saveStudentSession(
        accessToken: res.session.accessToken,
        refreshToken: res.session.refreshToken,
        userId: res.user.id,
        username: res.user.username,
      );
      state = AsyncValue.data(res.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signup(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repo.signup(username, password);
      await _storage.saveStudentSession(
        accessToken: res.session.accessToken,
        refreshToken: res.session.refreshToken,
        userId: res.user.id,
        username: res.user.username,
      );
      state = AsyncValue.data(res.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {}
    await _storage.clearStudentSession();
    state = const AsyncValue.data(null);
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    return await _repo.changePassword(currentPassword, newPassword);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/admin_repository.dart';

final adminAuthNotifierProvider =
    StateNotifierProvider<AdminAuthNotifier, AsyncValue<String?>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AdminAuthNotifier(repo, storage);
});

class AdminAuthNotifier extends StateNotifier<AsyncValue<String?>> {
  final AdminRepository _repo;
  final SecureStorageService _storage;

  AdminAuthNotifier(this._repo, this._storage)
      : super(const AsyncValue.loading()) {
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    try {
      final token = await _storage.getAdminToken();
      state = AsyncValue.data(token);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String accessCode) async {
    state = const AsyncValue.loading();
    try {
      final token = await _repo.login(accessCode);
      await _storage.saveAdminToken(token);
      state = AsyncValue.data(token);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearAdminToken();
    state = const AsyncValue.data(null);
  }
}

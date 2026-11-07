import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ApiClient());
});

class AdminRepository {
  final ApiClient _client;

  AdminRepository(this._client);

  Future<String> login(String accessCode) async {
    final res = await _client.post(
      ApiEndpoints.adminLogin,
      data: {'code': accessCode.trim()},
    );
    final data = res.data as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Invalid administrator response from server.');
    }
    return token;
  }

  Future<AdminDashboardStats> getDashboard(String adminToken) async {
    final res = await _client.get(
      ApiEndpoints.adminDashboard,
      options: Options(
        headers: {'Authorization': 'Bearer $adminToken'},
      ),
    );
    final data = res.data as Map<String, dynamic>;
    return AdminDashboardStats.fromJson(data);
  }

  Future<bool> createLesson({
    required String adminToken,
    required String title,
    required String moduleId,
    required String youtubeUrl,
    String? instructor,
    String? description,
  }) async {
    final res = await _client.post(
      ApiEndpoints.adminLessons,
      data: {
        'title': title.trim(),
        'module_id': moduleId,
        'youtube_url': youtubeUrl.trim(),
        if (instructor != null && instructor.isNotEmpty)
          'instructor': instructor.trim(),
        if (description != null && description.isNotEmpty)
          'description': description.trim(),
      },
      options: Options(
        headers: {'Authorization': 'Bearer $adminToken'},
      ),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> deleteLesson(String adminToken, String lessonId) async {
    final res = await _client.delete(
      '${ApiEndpoints.adminLessons}?id=$lessonId',
      options: Options(
        headers: {'Authorization': 'Bearer $adminToken'},
      ),
    );
    return res.statusCode == 200;
  }
}

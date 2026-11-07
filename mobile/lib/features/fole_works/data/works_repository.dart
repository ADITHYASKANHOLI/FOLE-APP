import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../home/data/home_repository.dart';
import '../domain/works_models.dart';

final worksRepositoryProvider = Provider<WorksRepository>((ref) {
  return WorksRepository(client: ref.watch(apiClientProvider));
});

final worksActivitiesProvider =
    FutureProvider<List<WorksActivityItem>>((ref) async {
  return await ref.watch(worksRepositoryProvider).getActivities();
});

final worksDetailProvider =
    FutureProvider.family<WorksActivityItem, String>((ref, slug) async {
  return await ref.watch(worksRepositoryProvider).getActivityDetail(slug);
});

class WorksRepository {
  final ApiClient _client;

  WorksRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<WorksActivityItem>> getActivities() async {
    final response =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.foleWorks);
    final list = response.data?['activities'] as List<dynamic>? ?? [];
    return list
        .map((a) => WorksActivityItem.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<WorksActivityItem> getActivityDetail(String slug) async {
    final response = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.foleWorksDetail(slug));
    final raw = response.data?['activity'] as Map<String, dynamic>?;
    if (raw == null) {
      throw Exception('Activity not found');
    }
    return WorksActivityItem.fromJson(raw);
  }

  Future<WorksActivityItem> getActivityBySlug(String slug) =>
      getActivityDetail(slug);
}

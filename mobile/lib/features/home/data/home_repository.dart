import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/home_models.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(client: ref.watch(apiClientProvider));
});

final homeFeedProvider = FutureProvider<HomeFeedData>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return await repo.getHomeFeed();
});

class HomeRepository {
  final ApiClient _client;

  HomeRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<HomeFeedData> getHomeFeed() async {
    final response = await _client.get<Map<String, dynamic>>(ApiEndpoints.home);
    if (response.data == null) {
      throw Exception('Empty response from home feed');
    }
    return HomeFeedData.fromJson(response.data!);
  }
}

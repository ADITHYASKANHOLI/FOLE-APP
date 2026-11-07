import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../home/data/home_repository.dart';
import '../domain/search_models.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(client: ref.watch(apiClientProvider));
});

final searchResultsProvider =
    FutureProvider.family<List<SearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return await ref.watch(searchRepositoryProvider).search(query);
});

class SearchRepository {
  final ApiClient _client;

  SearchRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<SearchResult>> search(String query) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.search,
      queryParameters: {'q': query},
    );

    final list = response.data?['results'] as List<dynamic>? ?? [];
    return list
        .map((r) => SearchResult.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

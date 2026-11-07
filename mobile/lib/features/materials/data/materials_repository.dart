import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../home/data/home_repository.dart';
import '../domain/material_models.dart';

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  return MaterialsRepository(client: ref.watch(apiClientProvider));
});

final materialsListProvider =
    FutureProvider.family<List<MaterialItem>, MaterialFilter>(
        (ref, filter) async {
  return await ref.watch(materialsRepositoryProvider).getMaterials(
        subjectId: filter.subjectId,
        moduleId: filter.moduleId,
        search: filter.search,
      );
});

class MaterialsRepository {
  final ApiClient _client;

  MaterialsRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<MaterialItem>> getMaterials({
    String? subjectId,
    String? moduleId,
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (subjectId != null && subjectId.isNotEmpty) {
      query['subject_id'] = subjectId;
    }
    if (moduleId != null && moduleId.isNotEmpty) {
      query['module_id'] = moduleId;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.materials,
      queryParameters: query,
    );

    final list = response.data?['data'] as List<dynamic>? ?? [];
    return list
        .map((m) => MaterialItem.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<DownloadAuthResponse> getDownloadAuthorization(
      String materialId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.materialDownload(materialId),
    );

    if (response.data == null) {
      throw Exception('Empty download response');
    }
    return DownloadAuthResponse.fromJson(response.data!);
  }
}

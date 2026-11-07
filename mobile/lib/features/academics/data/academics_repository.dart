import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../home/data/home_repository.dart';
import '../../home/domain/home_models.dart';
import '../domain/academic_models.dart';

final academicsRepositoryProvider = Provider<AcademicsRepository>((ref) {
  return AcademicsRepository(client: ref.watch(apiClientProvider));
});

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  return await ref.watch(academicsRepositoryProvider).getDepartments();
});

final semestersProvider = FutureProvider<List<Semester>>((ref) async {
  return await ref.watch(academicsRepositoryProvider).getSemesters();
});

final subjectsFilterProvider =
    FutureProvider.family<List<SubjectSummary>, SubjectFilter>(
        (ref, filter) async {
  return await ref.watch(academicsRepositoryProvider).getSubjects(
        departmentSlug: filter.departmentSlug,
        semester: filter.semester,
        search: filter.search,
      );
});

final subjectDetailProvider =
    FutureProvider.family<SubjectDetail, String>((ref, slug) async {
  return await ref.watch(academicsRepositoryProvider).getSubjectDetail(slug);
});

class AcademicsRepository {
  final ApiClient _client;

  AcademicsRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Department>> getDepartments() async {
    final response =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.departments);
    final list = response.data?['departments'] as List<dynamic>? ?? [];
    return list
        .map((d) => Department.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<List<Semester>> getSemesters({String? departmentId}) async {
    final query = departmentId != null ? {'department_id': departmentId} : null;
    final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.semesters,
        queryParameters: query);
    final list = response.data?['semesters'] as List<dynamic>? ?? [];
    return list
        .map((s) => Semester.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<List<SubjectSummary>> getSubjects({
    String? departmentSlug,
    int? semester,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (departmentSlug != null && departmentSlug.isNotEmpty) {
      query['department_slug'] = departmentSlug;
    }
    if (semester != null) {
      query['semester'] = semester;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.subjects,
        queryParameters: query);
    final list = response.data?['data'] as List<dynamic>? ?? [];
    return list
        .map((s) => SubjectSummary.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<SubjectDetail> getSubjectDetail(String slug) async {
    final response = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.subjectDetail(slug));
    final subjectRaw = response.data?['subject'] as Map<String, dynamic>?;
    if (subjectRaw == null) {
      throw Exception('Subject not found');
    }
    return SubjectDetail.fromJson(subjectRaw);
  }
}

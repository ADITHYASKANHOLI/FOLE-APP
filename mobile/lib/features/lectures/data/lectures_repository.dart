import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../home/data/home_repository.dart';
import '../domain/lecture_models.dart';

final lecturesRepositoryProvider = Provider<LecturesRepository>((ref) {
  return LecturesRepository(client: ref.watch(apiClientProvider));
});

final lessonDetailProvider =
    FutureProvider.family<LessonDetail, String>((ref, idOrSlug) async {
  return await ref.watch(lecturesRepositoryProvider).getLessonDetail(idOrSlug);
});

final lecturesBrowserProvider =
    FutureProvider.family<List<LectureListItem>, Map<String, dynamic>>(
        (ref, filters) async {
  return await ref.watch(lecturesRepositoryProvider).getLectures(
        dept: filters['dept']?.toString(),
        sem: filters['sem']?.toString(),
        subject: filters['subject']?.toString(),
        q: filters['q']?.toString(),
      );
});

class LecturesRepository {
  final ApiClient _client;

  LecturesRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<LessonDetail> getLessonDetail(String idOrSlug,
      {String? moduleId}) async {
    final query = moduleId != null ? {'module_id': moduleId} : null;
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.lessonDetail(idOrSlug),
      queryParameters: query,
    );

    final rawLesson = response.data?['lesson'] as Map<String, dynamic>?;
    if (rawLesson == null) {
      throw Exception('Lesson not found');
    }
    return LessonDetail.fromJson(rawLesson);
  }

  Future<List<LectureListItem>> getLectures({
    String? dept,
    String? sem,
    String? subject,
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (dept != null && dept.isNotEmpty) query['dept'] = dept;
    if (sem != null && sem.isNotEmpty) query['sem'] = sem;
    if (subject != null && subject.isNotEmpty) query['subject'] = subject;
    if (q != null && q.isNotEmpty) query['q'] = q;

    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.lectures,
      queryParameters: query,
    );

    final list = response.data?['data'] as List<dynamic>? ?? [];
    return list
        .map((l) => LectureListItem.fromJson(l as Map<String, dynamic>))
        .toList();
  }
}

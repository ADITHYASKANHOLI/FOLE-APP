import 'package:flutter_test/flutter_test.dart';
import 'package:engivault_mobile/features/admin/domain/admin_models.dart';

void main() {
  group('Admin Models', () {
    test('AdminLessonSummary parses correctly', () {
      final json = {
        'id': 'lec-01',
        'title': 'Vector Spaces and Subspaces',
        'youtube_video_id': 'dQw4w9WgXcQ',
        'created_at': '2026-11-01T10:00:00Z',
      };

      final lesson = AdminLessonSummary.fromJson(json);
      expect(lesson.id, 'lec-01');
      expect(lesson.title, 'Vector Spaces and Subspaces');
      expect(lesson.youtubeVideoId, 'dQw4w9WgXcQ');
      expect(lesson.createdAt, '2026-11-01T10:00:00Z');
    });

    test('AdminDashboardStats parses composite metrics and lessons', () {
      final json = {
        'stats': {
          'departments_count': 7,
          'subjects_count': 42,
          'modules_count': 168,
          'lessons_count': 512,
          'materials_count': 94,
          'students_count': 1205,
          'active_space_sessions': 8,
        },
        'recent_lessons': [
          {
            'id': 'lec-512',
            'title': 'Graph Coloring Algorithms',
            'youtube_video_id': 'xyz123abc45',
            'created_at': '2026-11-07T12:00:00Z',
          }
        ],
      };

      final stats = AdminDashboardStats.fromJson(json);
      expect(stats.departmentsCount, 7);
      expect(stats.subjectsCount, 42);
      expect(stats.modulesCount, 168);
      expect(stats.lessonsCount, 512);
      expect(stats.materialsCount, 94);
      expect(stats.studentsCount, 1205);
      expect(stats.activeSpaceSessions, 8);
      expect(stats.recentLessons.length, 1);
      expect(stats.recentLessons.first.title, 'Graph Coloring Algorithms');
      expect(stats.recentLessons.first.youtubeVideoId, 'xyz123abc45');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:engivault_mobile/features/academics/domain/academic_models.dart';
import 'package:engivault_mobile/features/auth/domain/auth_models.dart';
import 'package:engivault_mobile/features/fole_works/domain/works_models.dart';
import 'package:engivault_mobile/features/lectures/domain/lecture_models.dart';
import 'package:engivault_mobile/features/materials/domain/material_models.dart';

void main() {
  group('Auth Models', () {
    test('StudentUser parses correctly from json', () {
      final json = {
        'id': 'u1b2c3d4-1234',
        'username': 'rahul_v',
        'display_name': 'Rahul V',
        'is_organizer': true,
        'created_at': '2026-11-01T10:00:00Z',
      };
      final user = StudentUser.fromJson(json);
      expect(user.id, 'u1b2c3d4-1234');
      expect(user.username, 'rahul_v');
      expect(user.displayName, 'Rahul V');
      expect(user.isOrganizer, isTrue);
      expect(user.createdAt, '2026-11-01T10:00:00Z');
    });

    test('AuthSession parses correctly', () {
      final json = {
        'access_token': 'test_access_jwt',
        'refresh_token': 'test_refresh_jwt',
        'expires_in': 3600,
        'expires_at': 1794060000,
      };
      final session = AuthSession.fromJson(json);
      expect(session.accessToken, 'test_access_jwt');
      expect(session.refreshToken, 'test_refresh_jwt');
      expect(session.expiresIn, 3600);
      expect(session.expiresAt, 1794060000);
    });

    test('AuthResponse parses user and session', () {
      final json = {
        'user': {
          'id': 'u-01',
          'username': 'student_1',
          'display_name': 'Student One',
        },
        'session': {
          'access_token': 'acc-123',
          'refresh_token': 'ref-123',
          'expires_in': 1800,
        },
      };
      final res = AuthResponse.fromJson(json);
      expect(res.user.username, 'student_1');
      expect(res.session.accessToken, 'acc-123');
    });
  });

  group('Academic Models', () {
    test('SubjectDetail and nested modules parse correctly', () {
      final json = {
        'id': 'sub-mat203',
        'title': 'Discrete Mathematical Structures',
        'code': 'MAT 203',
        'slug': 'discrete-mathematical-structures',
        'description': 'Comprehensive KTU syllabus coverage',
        'semester_number': 3,
        'department_name': 'Computer Science and Engineering',
        'modules': [
          {
            'id': 'mod-01',
            'title': 'Module 1 - Sets and Relations',
            'slug': 'module-1-sets-relations',
            'module_number': 1,
            'lessons_count': 3,
            'lessons': [
              {
                'id': 'lec-01',
                'title': 'Equivalence Relations',
                'slug': 'equivalence-relations',
                'lesson_number': 1,
                'duration_seconds': 2400,
                'youtube_video_id': 'dQw4w9WgXcQ',
                'instructor': 'Dr. Sarah Ahmed',
              }
            ],
          }
        ],
        'materials': [
          {
            'id': 'mat-01',
            'title': 'Handwritten Notes Mod 1',
            'material_type': 'notes',
            'original_filename': 'Notes_Mod1.pdf',
            'file_size': 1024000,
            'subject_id': 'sub-mat203',
          }
        ],
      };

      final detail = SubjectDetail.fromJson(json);
      expect(detail.id, 'sub-mat203');
      expect(detail.title, 'Discrete Mathematical Structures');
      expect(detail.code, 'MAT 203');
      expect(detail.modules.length, 1);
      expect(detail.modules.first.lessons.length, 1);
      expect(detail.modules.first.lessons.first.youtubeVideoId, 'dQw4w9WgXcQ');
      expect(detail.materials.length, 1);
      expect(detail.materials.first.title, 'Handwritten Notes Mod 1');
    });
  });

  group('FOLE WORKS Models', () {
    test('WorksActivityItem parses correctly', () {
      final json = {
        'id': 'act-01',
        'title': 'Flutter & Supabase Masterclass',
        'slug': 'flutter-supabase-masterclass',
        'short_description': 'Build full-stack native mobile apps',
        'venue': 'FOLE SPACE Labs',
        'fee': 'Free',
        'category': 'Workshop',
        'status': 'upcoming',
        'flyer_url': 'https://engivault.app/flyer.png',
        'registration_url': 'https://forms.gle/sample',
      };

      final item = WorksActivityItem.fromJson(json);
      expect(item.id, 'act-01');
      expect(item.title, 'Flutter & Supabase Masterclass');
      expect(item.venue, 'FOLE SPACE Labs');
      expect(item.fee, 'Free');
      expect(item.category, 'Workshop');
      expect(item.status, 'upcoming');
      expect(item.flyerUrl, 'https://engivault.app/flyer.png');
      expect(item.registrationUrl, 'https://forms.gle/sample');
    });
  });

  group('Home and Department Models', () {
    test('Department parses correctly', () {
      final json = {
        'id': 'dept-cse',
        'name': 'Computer Science and Engineering',
        'code': 'CSE',
        'slug': 'computer-science-and-engineering',
      };

      final dept = Department.fromJson(json);
      expect(dept.name, 'Computer Science and Engineering');
      expect(dept.code, 'CSE');
      expect(dept.slug, 'computer-science-and-engineering');
    });

    test('LectureListItem parses correctly', () {
      final json = {
        'id': 'lec-01',
        'title': 'Fourier Transform Intro',
        'slug': 'fourier-transform-intro',
        'lesson_number': 1,
        'duration_seconds': 1420,
        'youtube_video_id': 'dQw4w9WgXcQ',
        'instructor': 'Dr. Sharma',
        'subject_title': 'Mathematics IV',
        'subject_slug': 'mathematics-iv',
        'module_title': 'Module 1: Complex Analysis',
        'module_slug': 'module-1',
      };

      final lec = LectureListItem.fromJson(json);
      expect(lec.id, 'lec-01');
      expect(lec.title, 'Fourier Transform Intro');
      expect(lec.durationSeconds, 1420);
      expect(lec.youtubeVideoId, 'dQw4w9WgXcQ');
    });

    test('MaterialItem parses and formats size', () {
      final json = {
        'id': 'mat-01',
        'title': 'Module 1 Complete Lecture Notes',
        'material_type': 'notes',
        'original_filename': 'Module1_Notes.pdf',
        'file_size': 2097152, // 2 MB
        'download_endpoint': '/api/mobile/v1/materials/mat-01/download',
      };

      final mat = MaterialItem.fromJson(json);
      expect(mat.id, 'mat-01');
      expect(mat.title, 'Module 1 Complete Lecture Notes');
      expect(mat.formattedSize, '2.0 MB');
    });
  });
}

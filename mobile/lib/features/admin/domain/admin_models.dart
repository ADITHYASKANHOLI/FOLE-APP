class AdminLessonSummary {
  final String id;
  final String title;
  final String? youtubeVideoId;
  final String? createdAt;

  const AdminLessonSummary({
    required this.id,
    required this.title,
    this.youtubeVideoId,
    this.createdAt,
  });

  factory AdminLessonSummary.fromJson(Map<String, dynamic> json) {
    return AdminLessonSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      youtubeVideoId: json['youtube_video_id']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class AdminDashboardStats {
  final int departmentsCount;
  final int subjectsCount;
  final int modulesCount;
  final int lessonsCount;
  final int materialsCount;
  final int studentsCount;
  final int activeSpaceSessions;
  final List<AdminLessonSummary> recentLessons;

  const AdminDashboardStats({
    required this.departmentsCount,
    required this.subjectsCount,
    required this.modulesCount,
    required this.lessonsCount,
    required this.materialsCount,
    required this.studentsCount,
    required this.activeSpaceSessions,
    required this.recentLessons,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final recent = json['recent_lessons'] as List<dynamic>? ?? [];

    return AdminDashboardStats(
      departmentsCount: (stats['departments_count'] as num?)?.toInt() ?? 0,
      subjectsCount: (stats['subjects_count'] as num?)?.toInt() ?? 0,
      modulesCount: (stats['modules_count'] as num?)?.toInt() ?? 0,
      lessonsCount: (stats['lessons_count'] as num?)?.toInt() ?? 0,
      materialsCount: (stats['materials_count'] as num?)?.toInt() ?? 0,
      studentsCount: (stats['students_count'] as num?)?.toInt() ?? 0,
      activeSpaceSessions:
          (stats['active_space_sessions'] as num?)?.toInt() ?? 0,
      recentLessons: recent
          .map((l) => AdminLessonSummary.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

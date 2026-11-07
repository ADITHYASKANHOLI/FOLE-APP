class DepartmentSummary {
  final String id;
  final String name;
  final String code;
  final String slug;
  final int displayOrder;
  final String? description;

  const DepartmentSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.slug,
    required this.displayOrder,
    this.description,
  });

  factory DepartmentSummary.fromJson(Map<String, dynamic> json) {
    return DepartmentSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
    );
  }
}

class SubjectSummary {
  final String id;
  final String title;
  final String? code;
  final String slug;
  final String? shortDescription;
  final String? departmentId;
  final int? semesterNumber;
  final int modulesCount;
  final int lessonsCount;
  final int materialsCount;

  const SubjectSummary({
    required this.id,
    required this.title,
    this.code,
    required this.slug,
    this.shortDescription,
    this.departmentId,
    this.semesterNumber,
    required this.modulesCount,
    required this.lessonsCount,
    required this.materialsCount,
  });

  factory SubjectSummary.fromJson(Map<String, dynamic> json) {
    return SubjectSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString(),
      slug: json['slug']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      departmentId: json['department_id']?.toString(),
      semesterNumber: (json['semester_number'] as num?)?.toInt(),
      modulesCount: (json['modules_count'] as num?)?.toInt() ?? 0,
      lessonsCount: (json['lessons_count'] as num?)?.toInt() ?? 0,
      materialsCount: (json['materials_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LectureSummary {
  final String id;
  final String title;
  final String slug;
  final String subjectTitle;
  final String subjectSlug;
  final String moduleTitle;
  final String moduleSlug;
  final String? youtubeVideoId;
  final int? durationSeconds;
  final String? instructor;

  const LectureSummary({
    required this.id,
    required this.title,
    required this.slug,
    required this.subjectTitle,
    required this.subjectSlug,
    required this.moduleTitle,
    required this.moduleSlug,
    this.youtubeVideoId,
    this.durationSeconds,
    this.instructor,
  });

  factory LectureSummary.fromJson(Map<String, dynamic> json) {
    return LectureSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      subjectTitle: json['subject_title']?.toString() ?? 'Engineering',
      subjectSlug: json['subject_slug']?.toString() ?? '',
      moduleTitle: json['module_title']?.toString() ?? 'Module',
      moduleSlug: json['module_slug']?.toString() ?? '',
      youtubeVideoId: json['youtube_video_id']?.toString(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      instructor: json['instructor']?.toString(),
    );
  }
}

class SpaceSummary {
  final bool isOpen;
  final int capacity;
  final int currentOccupancy;
  final int availableSeats;

  const SpaceSummary({
    required this.isOpen,
    required this.capacity,
    required this.currentOccupancy,
    required this.availableSeats,
  });

  factory SpaceSummary.fromJson(Map<String, dynamic> json) {
    return SpaceSummary(
      isOpen: json['is_open'] == true,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      currentOccupancy: (json['current_occupancy'] as num?)?.toInt() ?? 0,
      availableSeats: (json['available_seats'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeFeedData {
  final String siteName;
  final String tagline;
  final bool maintenanceMode;
  final String? announcement;
  final List<DepartmentSummary> departments;
  final List<SubjectSummary> featuredSubjects;
  final List<LectureSummary> latestLectures;
  final SpaceSummary? spaceStatus;

  const HomeFeedData({
    required this.siteName,
    required this.tagline,
    required this.maintenanceMode,
    this.announcement,
    required this.departments,
    required this.featuredSubjects,
    required this.latestLectures,
    this.spaceStatus,
  });

  factory HomeFeedData.fromJson(Map<String, dynamic> json) {
    final site = json['site'] as Map<String, dynamic>? ?? {};
    final deptsRaw = json['departments'] as List<dynamic>? ?? [];
    final subjectsRaw = json['featured_subjects'] as List<dynamic>? ?? [];
    final lecturesRaw = json['latest_lectures'] as List<dynamic>? ?? [];
    final spaceRaw = json['space_status'] as Map<String, dynamic>?;

    return HomeFeedData(
      siteName: site['site_name']?.toString() ?? 'ENGIVAULT',
      tagline: site['tagline']?.toString() ?? 'KTU Learning. Simplified.',
      maintenanceMode: site['maintenance_mode'] == true,
      announcement: site['announcement']?.toString(),
      departments: deptsRaw
          .map((d) => DepartmentSummary.fromJson(d as Map<String, dynamic>))
          .toList(),
      featuredSubjects: subjectsRaw
          .map((s) => SubjectSummary.fromJson(s as Map<String, dynamic>))
          .toList(),
      latestLectures: lecturesRaw
          .map((l) => LectureSummary.fromJson(l as Map<String, dynamic>))
          .toList(),
      spaceStatus: spaceRaw != null ? SpaceSummary.fromJson(spaceRaw) : null,
    );
  }
}

class Department {
  final String id;
  final String name;
  final String code;
  final String slug;
  final String? description;
  final int displayOrder;

  const Department({
    required this.id,
    required this.name,
    required this.code,
    required this.slug,
    this.description,
    required this.displayOrder,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class Semester {
  final String id;
  final int number;
  final String title;
  final String slug;
  final String? departmentId;

  const Semester({
    required this.id,
    required this.number,
    required this.title,
    required this.slug,
    this.departmentId,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id']?.toString() ?? '',
      number: (json['number'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      departmentId: json['department_id']?.toString(),
    );
  }
}

class AcademicLesson {
  final String id;
  final String title;
  final String slug;
  final int lessonNumber;
  final int? durationSeconds;
  final String? youtubeVideoId;
  final String? instructor;

  const AcademicLesson({
    required this.id,
    required this.title,
    required this.slug,
    required this.lessonNumber,
    this.durationSeconds,
    this.youtubeVideoId,
    this.instructor,
  });

  factory AcademicLesson.fromJson(Map<String, dynamic> json) {
    return AcademicLesson(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      lessonNumber: (json['lesson_number'] as num?)?.toInt() ?? 1,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      youtubeVideoId: json['youtube_video_id']?.toString(),
      instructor: json['instructor']?.toString(),
    );
  }
}

class AcademicModule {
  final String id;
  final String title;
  final String slug;
  final int moduleNumber;
  final String? description;
  final int lessonsCount;
  final List<AcademicLesson> lessons;

  const AcademicModule({
    required this.id,
    required this.title,
    required this.slug,
    required this.moduleNumber,
    this.description,
    required this.lessonsCount,
    required this.lessons,
  });

  factory AcademicModule.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'] as List<dynamic>? ?? [];
    return AcademicModule(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      moduleNumber: (json['module_number'] as num?)?.toInt() ?? 1,
      description: json['description']?.toString(),
      lessonsCount:
          (json['lessons_count'] as num?)?.toInt() ?? rawLessons.length,
      lessons: rawLessons
          .map((l) => AcademicLesson.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MaterialRef {
  final String id;
  final String title;
  final String materialType;
  final String originalFilename;
  final int? fileSize;

  const MaterialRef({
    required this.id,
    required this.title,
    required this.materialType,
    required this.originalFilename,
    this.fileSize,
  });

  factory MaterialRef.fromJson(Map<String, dynamic> json) {
    return MaterialRef(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      materialType: json['material_type']?.toString() ?? 'notes',
      originalFilename: json['original_filename']?.toString() ?? 'document.pdf',
      fileSize: (json['file_size'] as num?)?.toInt(),
    );
  }
}

class SubjectDetail {
  final String id;
  final String title;
  final String? code;
  final String slug;
  final String? description;
  final int? semesterNumber;
  final String? departmentId;
  final List<AcademicModule> modules;
  final List<MaterialRef> materials;

  const SubjectDetail({
    required this.id,
    required this.title,
    this.code,
    required this.slug,
    this.description,
    this.semesterNumber,
    this.departmentId,
    required this.modules,
    required this.materials,
  });

  factory SubjectDetail.fromJson(Map<String, dynamic> json) {
    final rawModules = json['modules'] as List<dynamic>? ?? [];
    final rawMaterials = json['materials'] as List<dynamic>? ?? [];

    return SubjectDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString(),
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      semesterNumber: (json['semester_number'] as num?)?.toInt(),
      departmentId: json['department_id']?.toString(),
      modules: rawModules
          .map((m) => AcademicModule.fromJson(m as Map<String, dynamic>))
          .toList(),
      materials: rawMaterials
          .map((m) => MaterialRef.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectFilter {
  final String? departmentSlug;
  final int? semester;
  final String? search;

  const SubjectFilter({
    this.departmentSlug,
    this.semester,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectFilter &&
          runtimeType == other.runtimeType &&
          departmentSlug == other.departmentSlug &&
          semester == other.semester &&
          search == other.search;

  @override
  int get hashCode =>
      departmentSlug.hashCode ^ semester.hashCode ^ search.hashCode;
}

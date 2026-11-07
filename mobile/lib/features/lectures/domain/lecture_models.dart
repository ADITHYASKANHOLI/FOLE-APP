import '../../academics/domain/academic_models.dart';

class LessonNavigationItem {
  final String id;
  final String title;
  final String slug;

  const LessonNavigationItem({
    required this.id,
    required this.title,
    required this.slug,
  });

  factory LessonNavigationItem.fromJson(Map<String, dynamic> json) {
    return LessonNavigationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

class LessonHierarchy {
  final String subjectTitle;
  final String subjectSlug;
  final String? subjectCode;
  final String moduleTitle;
  final String moduleSlug;
  final String? topicTitle;

  const LessonHierarchy({
    required this.subjectTitle,
    required this.subjectSlug,
    this.subjectCode,
    required this.moduleTitle,
    required this.moduleSlug,
    this.topicTitle,
  });

  factory LessonHierarchy.fromJson(Map<String, dynamic> json) {
    final sub = json['subject'] as Map<String, dynamic>? ?? {};
    final mod = json['module'] as Map<String, dynamic>? ?? {};
    final top = json['topic'] as Map<String, dynamic>? ?? {};

    return LessonHierarchy(
      subjectTitle: sub['title']?.toString() ?? 'Engineering',
      subjectSlug: sub['slug']?.toString() ?? '',
      subjectCode: sub['code']?.toString(),
      moduleTitle: mod['title']?.toString() ?? 'Module',
      moduleSlug: mod['slug']?.toString() ?? '',
      topicTitle: top['title']?.toString(),
    );
  }
}

class LessonDetail {
  final String id;
  final String title;
  final String slug;
  final int lessonNumber;
  final int? durationSeconds;
  final String? description;
  final String? youtubeVideoId;
  final String? youtubeWatchUrl;
  final String? youtubeEmbedUrl;
  final String? youtubeThumbnailUrl;
  final String? instructor;
  final LessonHierarchy hierarchy;
  final List<MaterialRef> materials;
  final LessonNavigationItem? prevLesson;
  final LessonNavigationItem? nextLesson;

  const LessonDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.lessonNumber,
    this.durationSeconds,
    this.description,
    this.youtubeVideoId,
    this.youtubeWatchUrl,
    this.youtubeEmbedUrl,
    this.youtubeThumbnailUrl,
    this.instructor,
    required this.hierarchy,
    required this.materials,
    this.prevLesson,
    this.nextLesson,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    final hierRaw = json['hierarchy'] as Map<String, dynamic>? ?? {};
    final matsRaw = json['materials'] as List<dynamic>? ?? [];
    final navRaw = json['navigation'] as Map<String, dynamic>? ?? {};

    return LessonDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      lessonNumber: (json['lesson_number'] as num?)?.toInt() ?? 1,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      description: json['description']?.toString(),
      youtubeVideoId: json['youtube_video_id']?.toString(),
      youtubeWatchUrl: json['youtube_watch_url']?.toString(),
      youtubeEmbedUrl: json['youtube_embed_url']?.toString(),
      youtubeThumbnailUrl: json['youtube_thumbnail_url']?.toString(),
      instructor: json['instructor']?.toString(),
      hierarchy: LessonHierarchy.fromJson(hierRaw),
      materials: matsRaw
          .map((m) => MaterialRef.fromJson(m as Map<String, dynamic>))
          .toList(),
      prevLesson: navRaw['prev_lesson'] != null
          ? LessonNavigationItem.fromJson(
              navRaw['prev_lesson'] as Map<String, dynamic>)
          : null,
      nextLesson: navRaw['next_lesson'] != null
          ? LessonNavigationItem.fromJson(
              navRaw['next_lesson'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LectureListItem {
  final String id;
  final String title;
  final String slug;
  final int lessonNumber;
  final int? durationSeconds;
  final String? youtubeVideoId;
  final String? instructor;
  final String subjectTitle;
  final String subjectSlug;
  final String moduleTitle;
  final String moduleSlug;

  const LectureListItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.lessonNumber,
    this.durationSeconds,
    this.youtubeVideoId,
    this.instructor,
    required this.subjectTitle,
    required this.subjectSlug,
    required this.moduleTitle,
    required this.moduleSlug,
  });

  factory LectureListItem.fromJson(Map<String, dynamic> json) {
    return LectureListItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      lessonNumber: (json['lesson_number'] as num?)?.toInt() ?? 1,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      youtubeVideoId: json['youtube_video_id']?.toString(),
      instructor: json['instructor']?.toString(),
      subjectTitle: json['subject_title']?.toString() ?? 'Engineering',
      subjectSlug: json['subject_slug']?.toString() ?? '',
      moduleTitle: json['module_title']?.toString() ?? 'Module',
      moduleSlug: json['module_slug']?.toString() ?? '',
    );
  }
}

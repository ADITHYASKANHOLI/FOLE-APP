import { NextRequest, NextResponse } from "next/server";
import {
  getLessonById,
  getLessonBySlug,
  getModuleById,
  getSubjectById,
  getTopicById,
  getLessonsForModule,
  getMaterialsForLesson,
  getAllLessons,
} from "@/lib/queries";
import {
  extractYouTubeVideoId,
  getYouTubeWatchUrl,
  getYouTubeEmbedUrl,
  getYouTubeThumbnailUrl,
} from "@/lib/utils/youtube";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface RouteParams {
  params: Promise<{ idOrSlug: string }>;
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const { idOrSlug } = await params;
    const { searchParams } = new URL(request.url);
    const moduleId = searchParams.get("module_id");

    let lesson = null;

    // 1. Try finding by UUID / ID
    if (/^[0-9a-fA-F-]{16,}$/.test(idOrSlug) || idOrSlug.startsWith("lec-") || idOrSlug.startsWith("lesson-")) {
      lesson = await getLessonById(idOrSlug);
    }

    // 2. Try finding by module + slug
    if (!lesson && moduleId) {
      lesson = await getLessonBySlug(moduleId, idOrSlug);
    }

    // 3. Fallback: Search all lessons for matching slug
    if (!lesson) {
      const all = await getAllLessons();
      lesson = all.find((l) => l.slug === idOrSlug || l.id === idOrSlug) || null;
    }

    if (!lesson) {
      return NextResponse.json(
        { error: "Lesson not found.", code: "NOT_FOUND" },
        { status: 404 }
      );
    }

    // Resolve hierarchy
    const [moduleData, topicData, materials, siblingLessons] = await Promise.all([
      lesson.module_id ? getModuleById(lesson.module_id) : Promise.resolve(null),
      lesson.topic_id ? getTopicById(lesson.topic_id) : Promise.resolve(null),
      getMaterialsForLesson(lesson.id),
      lesson.module_id ? getLessonsForModule(lesson.module_id) : Promise.resolve([]),
    ]);

    const subjectData = moduleData?.subject_id
      ? await getSubjectById(moduleData.subject_id)
      : null;

    // YouTube validation & canonical URLs
    const rawVideoInput =
      lesson.youtube_video_id ||
      (lesson as any).youtubeVideoId ||
      lesson.youtube_url ||
      (lesson as any).youtubeUrl ||
      "";

    const videoId = extractYouTubeVideoId(rawVideoInput);
    const watchUrl = videoId ? getYouTubeWatchUrl(videoId) : null;
    const embedUrl = videoId ? getYouTubeEmbedUrl(videoId) : null;
    const thumbnailUrl = videoId ? getYouTubeThumbnailUrl(videoId) : null;

    // Calculate previous / next lesson in module
    const currentIndex = siblingLessons.findIndex((l) => l.id === lesson?.id);
    const prevLesson =
      currentIndex > 0
        ? {
            id: siblingLessons[currentIndex - 1].id,
            title: siblingLessons[currentIndex - 1].title,
            slug: siblingLessons[currentIndex - 1].slug,
          }
        : null;

    const nextLesson =
      currentIndex >= 0 && currentIndex < siblingLessons.length - 1
        ? {
            id: siblingLessons[currentIndex + 1].id,
            title: siblingLessons[currentIndex + 1].title,
            slug: siblingLessons[currentIndex + 1].slug,
          }
        : null;

    return NextResponse.json({
      lesson: {
        id: lesson.id,
        title: lesson.title,
        slug: lesson.slug,
        lesson_number: lesson.lesson_number || 1,
        duration_seconds: lesson.duration_seconds || null,
        description: lesson.description || lesson.short_description || null,
        youtube_video_id: videoId,
        youtube_watch_url: watchUrl,
        youtube_embed_url: embedUrl,
        youtube_thumbnail_url: thumbnailUrl,
        instructor: lesson.instructor || lesson.faculty?.name || null,
        hierarchy: {
          subject: subjectData
            ? {
                id: subjectData.id,
                title: subjectData.title,
                slug: subjectData.slug,
                code: subjectData.code || null,
              }
            : null,
          module: moduleData
            ? {
                id: moduleData.id,
                title: moduleData.title,
                slug: moduleData.slug,
              }
            : null,
          topic: topicData
            ? {
                id: topicData.id,
                title: topicData.title,
                slug: topicData.slug,
              }
            : null,
        },
        materials: materials.map((m) => ({
          id: m.id,
          title: m.title,
          material_type: m.material_type,
          original_filename: m.original_filename,
          file_size: m.file_size || null,
        })),
        navigation: {
          prev_lesson: prevLesson,
          next_lesson: nextLesson,
        },
      },
    });
  } catch (err) {
    console.error("Lesson detail error:", err);
    return NextResponse.json(
      { error: "Failed to retrieve lesson details.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


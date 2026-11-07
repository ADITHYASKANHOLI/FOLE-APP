import { NextRequest, NextResponse } from "next/server";
import {
  getSubjectBySlug,
  getModulesForSubject,
  getLessonsForModule,
  getMaterialsForSubject,
} from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface RouteParams {
  params: Promise<{ slug: string }>;
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const { slug } = await params;
    const subject = await getSubjectBySlug(slug);

    if (!subject) {
      return NextResponse.json(
        { error: "Subject not found.", code: "NOT_FOUND" },
        { status: 404 }
      );
    }

    const [modules, materials] = await Promise.all([
      getModulesForSubject(subject.id),
      getMaterialsForSubject(subject.id),
    ]);

    const modulesWithLessons = await Promise.all(
      modules.map(async (mod) => {
        const lessons = await getLessonsForModule(mod.id);
        return {
          id: mod.id,
          title: mod.title,
          slug: mod.slug,
          module_number: mod.module_number || 1,
          description: mod.short_description || mod.description || null,
          lessons_count: lessons.length,
          lessons: lessons.map((l) => ({
            id: l.id,
            title: l.title,
            slug: l.slug,
            lesson_number: l.lesson_number || 1,
            duration_seconds: l.duration_seconds || null,
            youtube_video_id: l.youtube_video_id || (l as any).youtubeVideoId || null,
            instructor: l.instructor || l.faculty?.name || null,
          })),
        };
      })
    );

    return NextResponse.json({
      subject: {
        id: subject.id,
        title: subject.title,
        code: subject.code || null,
        slug: subject.slug,
        description: subject.description || subject.short_description || null,
        semester_number: subject.semester_number || null,
        department_id: subject.department_id || null,
        modules: modulesWithLessons,
        materials: materials.map((m) => ({
          id: m.id,
          title: m.title,
          material_type: m.material_type,
          original_filename: m.original_filename,
          file_size: m.file_size || null,
        })),
      },
    });
  } catch (err) {
    console.error("Subject detail error:", err);
    return NextResponse.json(
      { error: "Failed to retrieve subject details.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


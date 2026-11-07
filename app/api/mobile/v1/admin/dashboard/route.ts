import { NextRequest, NextResponse } from "next/server";
import { resolveAdminSession } from "@/lib/auth/unified-resolver";
import {
  getAllDepartments,
  getAllSubjects,
  getAllModules,
  getAllLessons,
  getAllMaterials,
} from "@/lib/queries";
import { isSupabaseConfigured, getSupabaseClient } from "@/lib/supabase/client";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const admin = await resolveAdminSession(request);
  if (!admin) {
    return NextResponse.json(
      { error: "Unauthorized. Administrator privileges required.", code: "UNAUTHORIZED_ADMIN" },
      { status: 401 }
    );
  }

  try {
    const [departments, subjects, modules, lessons, materials] = await Promise.all([
      getAllDepartments().catch(() => []),
      getAllSubjects().catch(() => []),
      getAllModules().catch(() => []),
      getAllLessons().catch(() => []),
      getAllMaterials().catch(() => []),
    ]);

    let studentsCount = 0;
    let activeSpaceSessions = 0;

    if (isSupabaseConfigured()) {
      try {
        const supabase = getSupabaseClient();
        const { count: profileCount } = await supabase
          .from("profiles")
          .select("*", { count: "exact", head: true });
        studentsCount = profileCount ?? 0;

        const { count: sessionCount } = await supabase
          .from("space_sessions")
          .select("*", { count: "exact", head: true })
          .eq("status", "active");
        activeSpaceSessions = sessionCount ?? 0;
      } catch {
        // Fallback gracefully
      }
    }

    return NextResponse.json({
      success: true,
      stats: {
        departments_count: departments.length,
        subjects_count: subjects.length,
        modules_count: modules.length,
        lessons_count: lessons.length,
        materials_count: materials.length,
        students_count: studentsCount,
        active_space_sessions: activeSpaceSessions,
      },
      recent_lessons: lessons.slice(0, 5).map((l: any) => ({
        id: l.id,
        title: l.title,
        created_at: l.created_at,
        youtube_video_id: l.youtube_video_id,
      })),
    });
  } catch (error: any) {
    console.error("GET /api/mobile/v1/admin/dashboard error:", error);
    return NextResponse.json(
      { error: "Failed to compile admin metrics", code: "DASHBOARD_METRICS_ERROR" },
      { status: 500 }
    );
  }
}


import { NextResponse } from "next/server";
import {
  getSiteSettings,
  getAllDepartments,
  getPublishedSubjects,
  getRecentPublishedLessons,
} from "@/lib/queries";
import { spaceService } from "@/lib/space/service";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const [settingsRes, deptsRes, subjectsRes, lessonsRes, spaceStatusRes] =
      await Promise.allSettled([
        getSiteSettings(),
        getAllDepartments(),
        getPublishedSubjects(),
        getRecentPublishedLessons(6),
        spaceService.getPublicSpaceStatus().catch(() => null),
      ]);

    const siteSettings = settingsRes.status === "fulfilled" ? settingsRes.value : null;
    const departments = deptsRes.status === "fulfilled" ? deptsRes.value : [];
    const subjects = subjectsRes.status === "fulfilled" ? subjectsRes.value : [];
    const latestLessons = lessonsRes.status === "fulfilled" ? lessonsRes.value : [];
    const spaceStatus = spaceStatusRes.status === "fulfilled" ? spaceStatusRes.value : null;

    return NextResponse.json({
      site: {
        site_name: siteSettings?.site_name || "ENGIVAULT",
        tagline: siteSettings?.tagline || "KTU Learning. Simplified.",
        maintenance_mode: Boolean(siteSettings?.maintenance_mode),
        announcement: siteSettings?.announcement || null,
      },
      departments: departments.map((d) => ({
        id: d.id,
        name: d.name,
        code: d.code,
        slug: d.slug,
        display_order: d.display_order,
        description: d.description || null,
      })),
      featured_subjects: subjects.slice(0, 8).map((s) => ({
        id: s.id,
        title: s.title,
        code: s.code || null,
        slug: s.slug,
        short_description: s.short_description || s.description || null,
        department_id: s.department_id || null,
        semester_number: s.semester_number || null,
        modules_count: s.modules_count || 0,
        lessons_count: s.lessons_count || 0,
        materials_count: s.materials_count || 0,
      })),
      latest_lectures: latestLessons.map((l) => ({
        id: l.id,
        title: l.title,
        slug: l.slug,
        subject_title: l.subject?.title || (l as any).module?.subject?.title || "Engineering",
        subject_slug: l.subject?.slug || (l as any).module?.subject?.slug || "",
        module_title: l.module?.title || "Module",
        module_slug: l.module?.slug || "",
        youtube_video_id: l.youtube_video_id || (l as any).youtubeVideoId || null,
        duration_seconds: l.duration_seconds || null,
        instructor: l.instructor || l.faculty?.name || null,
      })),
      space_status: spaceStatus
        ? {
            is_open: spaceStatus.is_open,
            capacity: spaceStatus.capacity,
            current_occupancy: spaceStatus.current_occupancy,
            available_seats: spaceStatus.available_seats,
          }
        : null,
    }, {
      headers: {
        "Cache-Control": "public, s-maxage=30, stale-while-revalidate=60",
      },
    });
  } catch (error) {
    console.error("Mobile home feed error:", error);
    return NextResponse.json(
      { error: "Failed to assemble home feed.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


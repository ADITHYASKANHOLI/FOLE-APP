import { NextRequest, NextResponse } from "next/server";
import {
  getAllLessons,
  getAllDepartments,
  getAllSemesters,
  getPublishedSubjects,
} from "@/lib/queries";
import { matchesSubjectQuery, matchesAcademicTarget } from "@/lib/utils/academic-search";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const dept = searchParams.get("dept");
    const sem = searchParams.get("sem");
    const subject = searchParams.get("subject");
    const q = searchParams.get("q");
    const page = Math.max(1, parseInt(searchParams.get("page") || "1", 10));
    const limit = Math.min(50, Math.max(1, parseInt(searchParams.get("limit") || "20", 10)));

    const [allLectures, departments, semesters, subjects] = await Promise.all([
      getAllLessons(),
      getAllDepartments(),
      getAllSemesters(),
      getPublishedSubjects(),
    ]);

    let filtered = allLectures.filter((lec) => lec.published !== false);

    // 1. Subject filter
    if (subject) {
      const selectedSubject = subjects.find((s) => s.slug === subject || s.id === subject);
      if (selectedSubject) {
        filtered = filtered.filter((l) => {
          const subId = l.module?.subject_id || l.subject?.id;
          return subId === selectedSubject.id;
        });
      }
    } else if (dept) {
      // 2. Department filter
      const selectedDept = departments.find((d) => d.slug === dept || d.id === dept);
      if (selectedDept) {
        filtered = filtered.filter((l) => {
          const sub =
            l.subject ||
            (l.module?.subject_id ? subjects.find((s) => s.id === l.module?.subject_id) : null);
          return !sub || sub.department_id === selectedDept.id || !sub.department_id;
        });
      }
    }

    // 3. Semester filter
    if (sem) {
      const selectedSem = semesters.find(
        (s) => String(s.number) === sem || String(s.semester_number) === sem || s.slug === sem
      );
      if (selectedSem) {
        const semNum = selectedSem.number || selectedSem.semester_number;
        filtered = filtered.filter((l) => {
          const sub =
            l.subject ||
            (l.module?.subject_id ? subjects.find((s) => s.id === l.module?.subject_id) : null);
          return (
            !sub ||
            sub.semester_number === semNum ||
            sub.semester_id === selectedSem.id ||
            !sub.semester_id
          );
        });
      }
    }

    // 4. Keyword search
    if (q && q.trim()) {
      filtered = filtered.filter((l) => {
        const parentSub =
          l.subject ||
          (l.module?.subject_id ? subjects.find((s) => s.id === l.module?.subject_id) : null);
        const subMatch = parentSub ? matchesSubjectQuery(parentSub, q) : false;
        const titleMatch = matchesAcademicTarget(l.title, q);
        const descMatch = matchesAcademicTarget(l.description || l.short_description || "", q);
        const moduleMatch = matchesAcademicTarget(l.module?.title || "", q);
        const topicMatch = matchesAcademicTarget(l.topic?.title || "", q);
        const facultyMatch = matchesAcademicTarget(l.faculty?.name || l.instructor || "", q);

        return subMatch || titleMatch || descMatch || moduleMatch || topicMatch || facultyMatch;
      });
    }

    const totalCount = filtered.length;
    const totalPages = Math.ceil(totalCount / limit) || 1;
    const startIndex = (page - 1) * limit;
    const paginatedLectures = filtered.slice(startIndex, startIndex + limit);

    return NextResponse.json({
      data: paginatedLectures.map((l) => {
        const parentSub =
          l.subject ||
          (l.module?.subject_id ? subjects.find((s) => s.id === l.module?.subject_id) : null);

        return {
          id: l.id,
          title: l.title,
          slug: l.slug,
          lesson_number: l.lesson_number || 1,
          duration_seconds: l.duration_seconds || null,
          youtube_video_id: l.youtube_video_id || (l as any).youtubeVideoId || null,
          instructor: l.instructor || l.faculty?.name || null,
          subject_title: parentSub?.title || "Engineering",
          subject_slug: parentSub?.slug || "",
          module_title: l.module?.title || "Module",
          module_slug: l.module?.slug || "",
        };
      }),
      pagination: {
        page,
        limit,
        total_count: totalCount,
        total_pages: totalPages,
        has_next: page < totalPages,
        has_prev: page > 1,
      },
    });
  } catch (err) {
    console.error("Lectures query error:", err);
    return NextResponse.json(
      { error: "Failed to query lectures.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


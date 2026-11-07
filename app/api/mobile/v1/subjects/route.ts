import { NextRequest, NextResponse } from "next/server";
import { getPublishedSubjects, getAllDepartments } from "@/lib/queries";
import { matchesSubjectQuery } from "@/lib/utils/academic-search";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const departmentSlug = searchParams.get("department_slug") || searchParams.get("dept");
    const semesterStr = searchParams.get("semester") || searchParams.get("sem");
    const search = searchParams.get("search") || searchParams.get("q");
    const page = Math.max(1, parseInt(searchParams.get("page") || "1", 10));
    const limit = Math.min(50, Math.max(1, parseInt(searchParams.get("limit") || "20", 10)));

    let subjects = await getPublishedSubjects();

    if (departmentSlug) {
      const departments = await getAllDepartments();
      const matchedDept = departments.find(
        (d) => d.slug === departmentSlug || d.id === departmentSlug || d.code.toLowerCase() === departmentSlug.toLowerCase()
      );
      if (matchedDept) {
        subjects = subjects.filter((s) => s.department_id === matchedDept.id || !s.department_id);
      }
    }

    if (semesterStr) {
      const semNum = parseInt(semesterStr, 10);
      if (!isNaN(semNum)) {
        subjects = subjects.filter((s) => s.semester_number === semNum || !s.semester_number);
      }
    }

    if (search && search.trim()) {
      subjects = subjects.filter((s) => matchesSubjectQuery(s, search));
    }

    const totalCount = subjects.length;
    const totalPages = Math.ceil(totalCount / limit) || 1;
    const startIndex = (page - 1) * limit;
    const paginatedSubjects = subjects.slice(startIndex, startIndex + limit);

    return NextResponse.json({
      data: paginatedSubjects.map((s) => ({
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
    console.error("Subjects fetch error:", err);
    return NextResponse.json(
      { error: "Failed to retrieve subjects.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


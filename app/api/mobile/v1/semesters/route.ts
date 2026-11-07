import { NextRequest, NextResponse } from "next/server";
import { getAllSemesters, getSemestersByDepartment } from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const departmentId = searchParams.get("department_id") || undefined;

    const semesters = departmentId
      ? await getSemestersByDepartment(departmentId)
      : await getAllSemesters();

    return NextResponse.json({
      semesters: semesters.map((s) => ({
        id: s.id,
        number: s.number || s.semester_number || 1,
        title: s.title,
        slug: s.slug,
        department_id: s.department_id || null,
      })),
    });
  } catch (err) {
    console.error("Semesters fetch error:", err);
    return NextResponse.json(
      { error: "Failed to retrieve semesters.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


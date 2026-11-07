import { NextResponse } from "next/server";
import { getAllDepartments } from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const departments = await getAllDepartments();
    return NextResponse.json({
      departments: departments.map((d) => ({
        id: d.id,
        name: d.name,
        code: d.code,
        slug: d.slug,
        description: d.description || null,
        display_order: d.display_order,
      })),
    });
  } catch (err) {
    console.error("Departments fetch error:", err);
    return NextResponse.json(
      { error: "Failed to retrieve departments.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


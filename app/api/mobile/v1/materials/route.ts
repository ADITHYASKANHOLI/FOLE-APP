import { NextRequest, NextResponse } from "next/server";
import { getPublishedMaterialsForCatalog } from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const subjectId = searchParams.get("subject_id");
    const moduleId = searchParams.get("module_id");
    const search = searchParams.get("search") || searchParams.get("q");
    const page = Math.max(1, parseInt(searchParams.get("page") || "1", 10));
    const limit = Math.min(50, Math.max(1, parseInt(searchParams.get("limit") || "20", 10)));

    let materials = await getPublishedMaterialsForCatalog();

    if (subjectId) {
      materials = materials.filter(
        (m) => m.subject_id === subjectId || (m as any).subject?.id === subjectId
      );
    }

    if (moduleId) {
      materials = materials.filter(
        (m) => m.module_id === moduleId || (m as any).module?.id === moduleId
      );
    }

    if (search && search.trim()) {
      const qLower = search.toLowerCase().trim();
      materials = materials.filter(
        (m) =>
          m.title.toLowerCase().includes(qLower) ||
          m.original_filename?.toLowerCase().includes(qLower) ||
          (m as any).subject?.title?.toLowerCase().includes(qLower)
      );
    }

    const totalCount = materials.length;
    const totalPages = Math.ceil(totalCount / limit) || 1;
    const startIndex = (page - 1) * limit;
    const paginatedMaterials = materials.slice(startIndex, startIndex + limit);

    return NextResponse.json({
      data: paginatedMaterials.map((m) => ({
        id: m.id,
        title: m.title,
        material_type: m.material_type || "notes",
        original_filename: m.original_filename || "notes.pdf",
        file_size: m.file_size || null,
        subject_id: m.subject_id || (m as any).subject?.id || null,
        subject_title: (m as any).subject?.title || null,
        module_id: m.module_id || (m as any).module?.id || null,
        module_title: (m as any).module?.title || null,
        download_endpoint: `/api/mobile/v1/materials/${m.id}/download`,
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
    console.error("Materials query error:", err);
    return NextResponse.json(
      { error: "Failed to retrieve materials.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


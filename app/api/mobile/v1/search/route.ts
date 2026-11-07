import { NextRequest, NextResponse } from "next/server";
import { searchContent } from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const q = searchParams.get("q") || "";

    if (!q.trim()) {
      return NextResponse.json({ results: [] });
    }

    const rawResults = await searchContent(q);

    const formatted = rawResults.map((item) => ({
      id: item.id,
      type: item.type,
      title: item.title,
      slug: (item as any).slug || null,
      subject_slug: (item as any).subject_slug || null,
      module_slug: (item as any).module_slug || null,
      breadcrumbs: (item as any).breadcrumbs || [],
    }));

    return NextResponse.json({ results: formatted });
  } catch (err) {
    console.error("Mobile search error:", err);
    return NextResponse.json(
      { error: "Search failed.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


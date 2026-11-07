import { NextRequest, NextResponse } from "next/server";
import { isSupabaseConfigured } from "@/lib/supabase/client";
import { createAdminClient, isSupabaseAdminConfigured } from "@/lib/supabase/admin";
import { getPublishedMaterialsForCatalog } from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;

    if (!id) {
      return NextResponse.json(
        { error: "Material ID is required.", code: "MISSING_ID" },
        { status: 400 }
      );
    }

    if (isSupabaseConfigured() && isSupabaseAdminConfigured()) {
      const supabase = createAdminClient();
      const { data, error } = await supabase
        .from("materials")
        .select(`
          id,
          storage_path,
          published,
          deleted_at,
          original_filename,
          file_size,
          mime_type
        `)
        .eq("id", id)
        .maybeSingle();

      if (error || !data) {
        return NextResponse.json(
          { error: "Study material not found.", code: "NOT_FOUND" },
          { status: 404 }
        );
      }

      if (!data.published || data.deleted_at !== null) {
        return NextResponse.json(
          { error: "This study material is not publicly available.", code: "FORBIDDEN" },
          { status: 403 }
        );
      }

      const expiresInSeconds = 60 * 30; // 30 minutes
      const { data: signedData, error: signError } = await supabase.storage
        .from("engivault-materials")
        .createSignedUrl(data.storage_path, expiresInSeconds, {
          download: data.original_filename || true,
        });

      if (signError || !signedData?.signedUrl) {
        return NextResponse.json(
          { error: "Failed to generate download authorization.", code: "STORAGE_ERROR" },
          { status: 500 }
        );
      }

      const expiresAt = new Date(Date.now() + expiresInSeconds * 1000).toISOString();

      return NextResponse.json({
        download_url: signedData.signedUrl,
        expires_at: expiresAt,
        filename: data.original_filename || "study_material.pdf",
        file_size: data.file_size || null,
        mime_type: data.mime_type || "application/pdf",
      });
    }

    // Offline / Dev mode fallback
    const materials = await getPublishedMaterialsForCatalog();
    const matched = materials.find((m) => m.id === id);

    if (!matched) {
      return NextResponse.json(
        { error: "Study material not found.", code: "NOT_FOUND" },
        { status: 404 }
      );
    }

    // In dev mode, redirect to web download endpoint or return local dummy path
    const requestHost = (request as NextRequest).nextUrl?.origin || new URL(request.url).origin;
    return NextResponse.json({
      download_url: `${requestHost}/api/materials/download?id=${id}`,
      expires_at: new Date(Date.now() + 1800 * 1000).toISOString(),
      filename: matched.original_filename || "study_material.pdf",
      file_size: matched.file_size || 1024,
      mime_type: "application/pdf",
    });
  } catch (err) {
    console.error("Material download authorization error:", err);
    return NextResponse.json(
      { error: "Failed to prepare material download.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}

import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth } from "@/lib/auth/unified-resolver";
import { spaceService } from "@/lib/space/service";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  const student = await resolveStudentAuth(request);
  if (!student) {
    return NextResponse.json(
      { error: "Authentication required.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  try {
    let sessionId: string | undefined;
    try {
      const body = await request.json();
      sessionId = body?.session_id || body?.sessionId;
    } catch {}

    const result = await spaceService.extendOpenSpace(student.id, sessionId);

    if (!result.success) {
      return NextResponse.json(
        { error: result.error || "Unable to extend session.", code: "EXTENSION_FAILED" },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      message: "Session extended successfully.",
      session: result.session,
    });
  } catch (error: any) {
    console.error("Mobile session extend error:", error);
    return NextResponse.json(
      { error: "Failed to extend session.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


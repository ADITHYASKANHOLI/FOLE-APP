import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth } from "@/lib/auth/unified-resolver";
import { spaceService } from "@/lib/space/service";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function POST(request: NextRequest, { params }: RouteParams) {
  const { id } = await params;
  const student = await resolveStudentAuth(request);

  if (!student) {
    return NextResponse.json(
      { error: "Authentication required.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  try {
    const result = await spaceService.cancelEventRegistration(id, student.id);

    if (!result.success) {
      return NextResponse.json(
        { error: result.error || "Unable to cancel registration.", code: "CANCELLATION_FAILED" },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      message: "Registration cancelled successfully.",
    });
  } catch (error: any) {
    console.error("Mobile event cancellation error:", error);
    return NextResponse.json(
      { error: "Internal cancellation service error.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


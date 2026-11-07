import { NextRequest, NextResponse } from "next/server";
import { spaceService } from "@/lib/space/service";
import { resolveStudentAuth } from "@/lib/auth/unified-resolver";
import {
  isMissingSpaceSchemaError,
  FOLE_SPACE_SETUP_REQUIRED_MESSAGE,
  FOLE_SPACE_NOT_CONFIGURED_CODE,
} from "@/lib/space/errors";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const student = await resolveStudentAuth(request);
    const status = await spaceService.getSpaceStatus(student?.id);

    if ((status as any).configured === false) {
      return NextResponse.json(
        {
          error: FOLE_SPACE_SETUP_REQUIRED_MESSAGE,
          code: FOLE_SPACE_NOT_CONFIGURED_CODE,
        },
        { status: 503 }
      );
    }

    return NextResponse.json(status, {
      headers: {
        "Cache-Control": student
          ? "private, no-cache, no-store, max-age=0, must-revalidate"
          : "public, s-maxage=10, stale-while-revalidate=20",
      },
    });
  } catch (error: any) {
    if (isMissingSpaceSchemaError(error) || error?.code === FOLE_SPACE_NOT_CONFIGURED_CODE) {
      return NextResponse.json(
        {
          error: FOLE_SPACE_SETUP_REQUIRED_MESSAGE,
          code: FOLE_SPACE_NOT_CONFIGURED_CODE,
        },
        { status: 503 }
      );
    }

    console.error("Failed to fetch space status for mobile:", error);
    return NextResponse.json(
      { error: "Unable to retrieve space status.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


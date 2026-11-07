import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth } from "@/lib/auth/unified-resolver";
import { spaceService } from "@/lib/space/service";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const student = await resolveStudentAuth(request);
  if (!student) {
    return NextResponse.json(
      { error: "Authentication required. Please sign in with your student account.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  try {
    const data = await spaceService.getMySpaceData(student.id);
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Mobile personal space error:", error);
    return NextResponse.json(
      { error: "Unable to load personal space data.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


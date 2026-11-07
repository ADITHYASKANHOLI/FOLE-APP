import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth } from "@/lib/auth/unified-resolver";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const student = await resolveStudentAuth(request);

  if (!student) {
    return NextResponse.json(
      { error: "Authentication required.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  return NextResponse.json({
    user: {
      id: student.id,
      username: student.username,
      display_name: student.displayName || student.username,
      is_organizer: student.isOrganizer,
    },
  });
}


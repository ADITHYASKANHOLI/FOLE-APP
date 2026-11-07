import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth, resolveAdminSession } from "@/lib/auth/unified-resolver";
import { spaceService } from "@/lib/space/service";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const admin = await resolveAdminSession(request);
  const student = await resolveStudentAuth(request);

  if (!admin && (!student || !student.isOrganizer)) {
    return NextResponse.json(
      { error: "Organizer or Administrator privileges required.", code: "FORBIDDEN" },
      { status: 403 }
    );
  }

  try {
    const events = admin
      ? await spaceService.getAllEventsForAdmin()
      : await spaceService.getOrganizerEvents(student!.id);

    return NextResponse.json({ events });
  } catch (error: any) {
    console.error("Mobile organizer events error:", error);
    return NextResponse.json(
      { error: "Failed to load organizer events.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


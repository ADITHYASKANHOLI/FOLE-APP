import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth, resolveAdminSession } from "@/lib/auth/unified-resolver";
import { canManageEvent } from "@/lib/space/permissions";
import { spaceService } from "@/lib/space/service";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  const { id } = await params;
  const admin = await resolveAdminSession(request);
  const student = await resolveStudentAuth(request);

  if (!admin && (!student || !student.isOrganizer)) {
    return NextResponse.json(
      { error: "Organizer access required.", code: "FORBIDDEN" },
      { status: 403 }
    );
  }

  if (!admin && student) {
    const isAuthorized = await canManageEvent(id, student.id);
    if (!isAuthorized) {
      return NextResponse.json(
        { error: "You are not authorized to view the check-in desk for this event.", code: "FORBIDDEN" },
        { status: 403 }
      );
    }
  }

  try {
    const data = await spaceService.getEventDeskData(id, student?.id);
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Mobile desk data error:", error);
    return NextResponse.json(
      { error: error?.message || "Failed to load desk data.", code: "DESK_ERROR" },
      { status: 400 }
    );
  }
}


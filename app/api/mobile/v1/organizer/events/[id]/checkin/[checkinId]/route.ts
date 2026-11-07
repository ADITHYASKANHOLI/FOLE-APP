import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth, resolveAdminSession } from "@/lib/auth/unified-resolver";
import { canManageEvent } from "@/lib/space/permissions";
import { spaceService } from "@/lib/space/service";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface RouteParams {
  params: Promise<{ id: string; checkinId: string }>;
}

export async function DELETE(request: NextRequest, { params }: RouteParams) {
  const { id: eventId, checkinId } = await params;
  const admin = await resolveAdminSession(request);
  const student = await resolveStudentAuth(request);

  if (!admin && (!student || !student.isOrganizer)) {
    return NextResponse.json(
      { error: "Organizer access required.", code: "FORBIDDEN" },
      { status: 403 }
    );
  }

  const userId = student?.id || "admin";

  if (!admin && student) {
    const isAuthorized = await canManageEvent(eventId, student.id);
    if (!isAuthorized) {
      return NextResponse.json(
        { error: "You are not authorized to modify attendance for this event.", code: "FORBIDDEN" },
        { status: 403 }
      );
    }
  }

  try {
    const result = await spaceService.revokeCheckIn(checkinId, userId);
    if (!result.success) {
      return NextResponse.json(
        { error: result.error || "Failed to revoke check-in.", code: "REVOKE_FAILED" },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      message: "Check-in revoked successfully.",
    });
  } catch (error: any) {
    console.error("Mobile revoke check-in error:", error);
    return NextResponse.json(
      { error: error?.message || "Revoke failed.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


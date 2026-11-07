import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth, resolveAdminSession } from "@/lib/auth/unified-resolver";
import { canManageEvent } from "@/lib/space/permissions";
import { spaceService } from "@/lib/space/service";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function POST(request: NextRequest, { params }: RouteParams) {
  const { id: eventId } = await params;
  const admin = await resolveAdminSession(request);
  const student = await resolveStudentAuth(request);

  if (!admin && (!student || !student.isOrganizer)) {
    return NextResponse.json(
      { error: "Organizer access required.", code: "FORBIDDEN" },
      { status: 403 }
    );
  }

  const scannerId = student?.id || "admin";

  if (!admin && student) {
    const isAuthorized = await canManageEvent(eventId, student.id);
    if (!isAuthorized) {
      return NextResponse.json(
        { error: "You are not authorized to check in attendees for this event.", code: "FORBIDDEN" },
        { status: 403 }
      );
    }
  }

  try {
    const body = await request.json();
    const registrationId = body?.registration_id || body?.registrationId;

    if (!registrationId) {
      return NextResponse.json(
        { error: "Registration ID is required.", code: "MISSING_ID" },
        { status: 400 }
      );
    }

    const result = await spaceService.checkinManual(eventId, scannerId, registrationId);
    if (!result.success) {
      return NextResponse.json(
        { error: result.error, code: "CHECKIN_FAILED" },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      checkin: result.checkin,
      message: "Check-in confirmed!",
    });
  } catch (error: any) {
    console.error("Mobile manual check-in error:", error);
    return NextResponse.json(
      { error: error?.message || "Check-in failed.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


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

  const userId = student?.id || "admin";

  if (!admin && student) {
    const isAuthorized = await canManageEvent(eventId, student.id);
    if (!isAuthorized) {
      return NextResponse.json(
        { error: "You are not authorized to update status for this event.", code: "FORBIDDEN" },
        { status: 403 }
      );
    }
  }

  try {
    const body = await request.json();
    const action = body?.action;

    let result;
    switch (action) {
      case "live":
        result = await spaceService.setEventLive(eventId, userId);
        break;
      case "end":
        result = await spaceService.endEventSession(eventId, userId);
        break;
      case "publish":
        result = await spaceService.publishEvent(eventId, userId);
        break;
      case "unpublish":
        result = await spaceService.unpublishEvent(eventId, userId);
        break;
      case "cancel":
        result = await spaceService.cancelEvent(eventId, userId);
        break;
      default:
        return NextResponse.json(
          { error: `Invalid action '${action}'. Expected: live, end, publish, unpublish, cancel.`, code: "INVALID_ACTION" },
          { status: 400 }
        );
    }

    if (!result.success) {
      return NextResponse.json(
        { error: (result as any).error || "Failed to update event state.", code: "STATE_CHANGE_FAILED" },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      message: `Event state updated successfully: ${action}`,
      event: (result as any).event,
    });
  } catch (error: any) {
    console.error("Mobile event status error:", error);
    return NextResponse.json(
      { error: error?.message || "Failed to update event status.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


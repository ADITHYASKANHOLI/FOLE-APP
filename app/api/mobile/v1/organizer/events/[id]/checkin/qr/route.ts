import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth, resolveAdminSession } from "@/lib/auth/unified-resolver";
import { canManageEvent } from "@/lib/space/permissions";
import { spaceService } from "@/lib/space/service";
import { deskQrScanSchema } from "@/lib/space/validation";
import {
  checkDbRateLimit,
  getClientIp,
  hashIdentifier,
  rateLimitResponse,
} from "@/lib/security/db-rate-limit";

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

  const ip = getClientIp(request);
  const rateLimitKey = hashIdentifier(`mobile-desk-scan:${scannerId}:${eventId}:${ip}`);
  const rateLimit = await checkDbRateLimit(rateLimitKey, {
    windowSeconds: 60,
    maxAttempts: 30,
  });

  if (!rateLimit.allowed) {
    return rateLimitResponse(
      "Scanning rate limit reached. Please wait a moment.",
      rateLimit.resetInSeconds
    );
  }

  try {
    const body = await request.json();
    const parsed = deskQrScanSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid QR code payload format. Expected FS1.<ticket_code>", code: "INVALID_FORMAT" },
        { status: 400 }
      );
    }

    const result = await spaceService.checkinQr(eventId, scannerId, parsed.data.qr_payload);
    if (!result.success) {
      return NextResponse.json(
        {
          error: result.error,
          code: (result as any).code || "CHECKIN_FAILED",
          checked_in_at: (result as any).checked_in_at,
        },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      checkin: result.checkin,
      message: "Check-in confirmed!",
    });
  } catch (error: any) {
    console.error("Mobile QR check-in error:", error);
    return NextResponse.json(
      { error: error?.message || "Check-in failed.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


import { NextRequest, NextResponse } from "next/server";
import { resolveStudentAuth } from "@/lib/auth/unified-resolver";
import { spaceService } from "@/lib/space/service";
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
  const { id } = await params;
  const student = await resolveStudentAuth(request);

  if (!student) {
    return NextResponse.json(
      { error: "Authentication required.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  const ip = getClientIp(request);
  const rateLimitKey = hashIdentifier(`mobile-virtual-chk:${student.id}:${id}:${ip}`);
  const rateLimit = await checkDbRateLimit(rateLimitKey, {
    windowSeconds: 5 * 60,
    maxAttempts: 5,
  });

  if (!rateLimit.allowed) {
    return rateLimitResponse(
      "Too many check-in attempts. Please wait.",
      rateLimit.resetInSeconds
    );
  }

  try {
    const result = await spaceService.virtualCheckIn(id, student.id);

    if (!result.success) {
      return NextResponse.json(
        { error: result.error || "Virtual check-in failed.", code: "CHECKIN_FAILED" },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      message: "Virtual check-in confirmed!",
      checkin: result.checkin,
    });
  } catch (error: any) {
    console.error("Mobile virtual check-in error:", error);
    return NextResponse.json(
      { error: "Check-in service encountered an error.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


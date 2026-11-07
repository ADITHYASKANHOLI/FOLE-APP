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

export async function POST(request: NextRequest) {
  const student = await resolveStudentAuth(request);
  if (!student) {
    return NextResponse.json(
      { error: "Authentication required. Please sign in with your student account.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  const ip = getClientIp(request);
  const rateLimitKey = hashIdentifier(`mobile-space-checkin:${student.id}:${ip}`);
  const rateLimit = await checkDbRateLimit(rateLimitKey, {
    windowSeconds: 5 * 60,
    maxAttempts: 10,
  });

  if (!rateLimit.allowed) {
    return rateLimitResponse(
      "Too many check-in requests. Please wait a moment before trying again.",
      rateLimit.resetInSeconds
    );
  }

  try {
    const result = await spaceService.checkinOpenSpace(student.id);

    if (!result.success) {
      return NextResponse.json(
        { error: result.error || "Unable to check in.", code: "CHECKIN_FAILED" },
        { status: 409 }
      );
    }

    return NextResponse.json({
      success: true,
      session: result.session,
      serverNow: result.serverNow,
    });
  } catch (error: any) {
    console.error("Mobile Open Space check-in error:", error);
    return NextResponse.json(
      { error: "Internal check-in service error. Please try again.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


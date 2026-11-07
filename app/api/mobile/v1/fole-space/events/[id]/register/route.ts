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
      { error: "Authentication required to register for events.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  const ip = getClientIp(request);
  const rateLimitKey = hashIdentifier(`mobile-event-reg:${student.id}:${id}:${ip}`);
  const rateLimit = await checkDbRateLimit(rateLimitKey, {
    windowSeconds: 5 * 60,
    maxAttempts: 10,
  });

  if (!rateLimit.allowed) {
    return rateLimitResponse(
      "Too many registration requests. Please wait a moment.",
      rateLimit.resetInSeconds
    );
  }

  try {
    const result = await spaceService.registerForEvent(id, student.id);

    if (!result.success) {
      return NextResponse.json(
        { error: result.error || "Registration failed.", code: "REGISTRATION_FAILED" },
        { status: 400 }
      );
    }

    return NextResponse.json(
      {
        success: true,
        registration: result.registration,
        message: "Registration successful!",
      },
      { status: 201 }
    );
  } catch (error: any) {
    console.error("Mobile event registration error:", error);
    return NextResponse.json(
      { error: "Internal registration service error.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


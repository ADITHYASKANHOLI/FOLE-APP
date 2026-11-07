import { NextRequest, NextResponse } from "next/server";
import { verifyCodeSchema } from "@/lib/validation/schemas";
import { verifyAdminAccessCode, createSignedToken, SESSION_MAX_AGE } from "@/lib/auth/session";
import { logActivity } from "@/lib/queries";
import {
  checkDbRateLimit,
  getClientIp,
  hashIdentifier,
  rateLimitResponse,
} from "@/lib/security/db-rate-limit";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  const ip = getClientIp(request);
  const ipHash = hashIdentifier(`mobile-admin-login:ip:${ip}`);

  const rateLimit = await checkDbRateLimit(ipHash, {
    windowSeconds: 15 * 60,
    maxAttempts: 6,
  });

  if (!rateLimit.allowed) {
    return rateLimitResponse(
      "Too many administrator authentication attempts. Please try again in 15 minutes.",
      rateLimit.resetInSeconds
    );
  }

  try {
    const body = await request.json();
    const result = verifyCodeSchema.safeParse(body);

    if (!result.success) {
      return NextResponse.json(
        { error: "Invalid access code format.", code: "VALIDATION_FAILED" },
        { status: 400 }
      );
    }

    const { code } = result.data;

    if (!process.env.ADMIN_ACCESS_CODE && !process.env.ADMIN_ACCESS_CODE_HASH) {
      console.error("ADMIN_ACCESS_CODE environment variable is missing on server.");
      return NextResponse.json(
        { error: "Server administrator authentication configuration is missing.", code: "SERVER_UNCONFIGURED" },
        { status: 500 }
      );
    }

    const isValid = verifyAdminAccessCode(code);

    if (!isValid) {
      await logActivity("Failed Mobile Admin Login Attempt", "security", { ip });
      return NextResponse.json(
        { error: "Invalid administrator access code.", code: "INVALID_CREDENTIALS" },
        { status: 401 }
      );
    }

    // Generate signed HMAC token for mobile
    const token = createSignedToken({ role: "admin" });

    await logActivity("Administrator Mobile Login", "auth", { ip });

    return NextResponse.json({
      success: true,
      token,
      expires_in: SESSION_MAX_AGE,
    });
  } catch (error) {
    console.error("Mobile admin login error:", error);
    return NextResponse.json(
      { error: "Internal server error during verification.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


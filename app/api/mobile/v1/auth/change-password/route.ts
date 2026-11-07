import { NextRequest, NextResponse } from "next/server";
import { studentChangePasswordSchema } from "@/lib/validation/schemas";
import { resolveStudentAuth, extractBearerToken } from "@/lib/auth/unified-resolver";
import { createAdminClient, isSupabaseAdminConfigured } from "@/lib/supabase/admin";
import { createClient as createSupabaseAnonClient } from "@supabase/supabase-js";
import { isSupabaseConfigured } from "@/lib/supabase/client";
import { usernameToInternalEmail } from "@/lib/auth/student";
import {
  checkDbRateLimit,
  getClientIp,
  hashIdentifier,
  rateLimitResponse,
} from "@/lib/security/db-rate-limit";
import { logActivity } from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  const student = await resolveStudentAuth(request);
  if (!student) {
    return NextResponse.json(
      { error: "Authentication required to change password.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  const ip = getClientIp(request);
  const ipHash = hashIdentifier(`mobile-change-password:ip:${ip}`);

  const rateLimit = await checkDbRateLimit(ipHash, {
    windowSeconds: 15 * 60,
    maxAttempts: 6,
  });

  if (!rateLimit.allowed) {
    return rateLimitResponse(
      "Too many password change attempts. Please try again in 15 minutes.",
      rateLimit.resetInSeconds
    );
  }

  try {
    const body = await request.json();
    // Accept either current_password / new_password or currentPassword / newPassword
    const payload = {
      currentPassword: body.current_password || body.currentPassword,
      newPassword: body.new_password || body.newPassword,
      confirmPassword: body.confirm_password || body.confirmPassword || body.new_password || body.newPassword,
    };

    const result = studentChangePasswordSchema.safeParse(payload);
    if (!result.success) {
      const firstIssue = result.error.issues[0]?.message || "Invalid password data.";
      return NextResponse.json({ error: firstIssue, code: "VALIDATION_FAILED" }, { status: 400 });
    }

    const { currentPassword, newPassword } = result.data;

    if (isSupabaseConfigured() && isSupabaseAdminConfigured()) {
      const internalEmail = usernameToInternalEmail(student.username);
      const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
      const anonKey =
        process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

      const anonClient = createSupabaseAnonClient(url, anonKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });

      // 1. Re-verify current password
      const { error: verifyError } = await anonClient.auth.signInWithPassword({
        email: internalEmail,
        password: currentPassword,
      });

      if (verifyError) {
        return NextResponse.json(
          { error: "Current password does not match.", code: "INVALID_CURRENT_PASSWORD" },
          { status: 401 }
        );
      }

      // 2. Update to new password via Admin Client
      const adminClient = createAdminClient();
      const { error: updateError } = await adminClient.auth.admin.updateUserById(
        student.id,
        { password: newPassword }
      );

      if (updateError) {
        return NextResponse.json(
          { error: "Failed to update password. Please try again.", code: "UPDATE_FAILED" },
          { status: 500 }
        );
      }

      await logActivity("Student Mobile Password Changed", "auth", {
        username: student.username,
        userId: student.id,
      });

      return NextResponse.json({
        success: true,
        message: "Password updated successfully.",
      });
    }

    return NextResponse.json({
      success: true,
      message: "Password updated successfully (dev mode).",
    });
  } catch (error) {
    console.error("Password change error:", error);
    return NextResponse.json(
      { error: "Internal error processing password update.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


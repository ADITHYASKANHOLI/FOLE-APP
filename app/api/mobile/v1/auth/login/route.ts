import { NextRequest, NextResponse } from "next/server";
import { studentLoginSchema } from "@/lib/validation/schemas";
import { usernameToInternalEmail } from "@/lib/auth/student";
import { createClient as createSupabaseAnonClient } from "@supabase/supabase-js";
import { isSupabaseConfigured } from "@/lib/supabase/client";
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
  const ip = getClientIp(request);
  const ipHash = hashIdentifier(`mobile-student-login:ip:${ip}`);

  // 1. IP-level rate limiting (6 attempts / 15 minutes)
  const ipRateLimit = await checkDbRateLimit(ipHash, {
    windowSeconds: 15 * 60,
    maxAttempts: 6,
  });

  if (!ipRateLimit.allowed) {
    return rateLimitResponse(
      "Too many login attempts from this network. Please try again in 15 minutes.",
      ipRateLimit.resetInSeconds
    );
  }

  try {
    const body = await request.json();
    const result = studentLoginSchema.safeParse(body);

    if (!result.success) {
      return NextResponse.json(
        { error: "Invalid username or password format.", code: "VALIDATION_FAILED" },
        { status: 400 }
      );
    }

    const { username, password } = result.data;
    const cleanUsername = username.toLowerCase().trim();

    // 2. Account-level rate limiting
    const userHash = hashIdentifier(`mobile-student-login:user:${cleanUsername}`);
    const userRateLimit = await checkDbRateLimit(userHash, {
      windowSeconds: 15 * 60,
      maxAttempts: 6,
    });

    if (!userRateLimit.allowed) {
      return rateLimitResponse(
        "Too many attempts for this account. Please try again in 15 minutes.",
        userRateLimit.resetInSeconds
      );
    }

    // 3. Live Supabase Authentication
    if (isSupabaseConfigured()) {
      const internalEmail = usernameToInternalEmail(cleanUsername);
      const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
      const anonKey =
        process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

      const client = createSupabaseAnonClient(url, anonKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });

      const { data: authData, error: authError } = await client.auth.signInWithPassword({
        email: internalEmail,
        password,
      });

      if (authError || !authData.user || !authData.session) {
        return NextResponse.json(
          { error: "Invalid username or password.", code: "INVALID_CREDENTIALS" },
          { status: 401 }
        );
      }

      await logActivity("Student Mobile Login", "auth", {
        username: cleanUsername,
        userId: authData.user.id,
      });

      return NextResponse.json({
        user: {
          id: authData.user.id,
          username: authData.user.user_metadata?.username || cleanUsername,
          display_name: authData.user.user_metadata?.display_name || cleanUsername,
        },
        session: {
          access_token: authData.session.access_token,
          refresh_token: authData.session.refresh_token,
          expires_in: authData.session.expires_in,
          expires_at: authData.session.expires_at,
        },
      });
    }

    // 4. Offline / Dev Fallback
    const mockSession = {
      user: {
        id: `mock-${cleanUsername}`,
        username: cleanUsername,
        display_name: cleanUsername,
      },
      session: {
        access_token: `dev-mock-student:${cleanUsername}`,
        refresh_token: `dev-mock-refresh:${cleanUsername}`,
        expires_in: 3600,
        expires_at: Math.floor(Date.now() / 1000) + 3600,
      },
    };

    return NextResponse.json(mockSession);
  } catch (error) {
    console.error("Mobile student login error:", error);
    return NextResponse.json(
      { error: "Authentication service encountered an unexpected error.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


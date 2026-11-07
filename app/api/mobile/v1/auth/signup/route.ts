import { NextRequest, NextResponse } from "next/server";
import { studentSignupSchema } from "@/lib/validation/schemas";
import { usernameToInternalEmail } from "@/lib/auth/student";
import { createAdminClient, isSupabaseAdminConfigured } from "@/lib/supabase/admin";
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
  const ipHash = hashIdentifier(`mobile-student-signup:ip:${ip}`);

  const rateLimit = await checkDbRateLimit(ipHash, {
    windowSeconds: 15 * 60,
    maxAttempts: 5,
  });

  if (!rateLimit.allowed) {
    return rateLimitResponse(
      "Too many account creation attempts. Please try again later.",
      rateLimit.resetInSeconds
    );
  }

  try {
    const body = await request.json();
    const result = studentSignupSchema.safeParse(body);

    if (!result.success) {
      const firstIssue = result.error.issues[0]?.message || "Invalid registration data.";
      return NextResponse.json({ error: firstIssue, code: "VALIDATION_FAILED" }, { status: 400 });
    }

    const { username, password } = result.data;
    const cleanUsername = username.toLowerCase().trim();

    if (isSupabaseConfigured() && isSupabaseAdminConfigured()) {
      const internalEmail = usernameToInternalEmail(cleanUsername);
      const supabaseAdmin = createAdminClient();

      // Check if username taken
      const { data: existingProfile } = await supabaseAdmin
        .from("profiles")
        .select("id")
        .ilike("username", cleanUsername)
        .maybeSingle();

      if (existingProfile) {
        return NextResponse.json(
          { error: "Username is already taken. Please choose another.", code: "USERNAME_TAKEN" },
          { status: 409 }
        );
      }

      // Create user with Supabase Admin API
      const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
        email: internalEmail,
        password,
        email_confirm: true,
        user_metadata: {
          username: cleanUsername,
          display_name: cleanUsername,
        },
      });

      if (authError || !authData.user) {
        if (
          authError?.message?.toLowerCase().includes("already registered") ||
          authError?.message?.toLowerCase().includes("unique")
        ) {
          return NextResponse.json(
            { error: "Username is already taken. Please choose another.", code: "USERNAME_TAKEN" },
            { status: 409 }
          );
        }

        console.error("[MOBILE SIGNUP] Auth creation error:", authError?.message);
        return NextResponse.json(
          { error: "Unable to create student account. Please try again.", code: "CREATION_FAILED" },
          { status: 500 }
        );
      }

      // Upsert profile record
      const { error: profileError } = await supabaseAdmin.from("profiles").upsert(
        {
          id: authData.user.id,
          username: cleanUsername,
          display_name: cleanUsername,
          role: "student",
        },
        { onConflict: "id" }
      );

      if (profileError) {
        console.error("[MOBILE SIGNUP] Profile write error:", profileError.message);
      }

      await logActivity("Student Mobile Registration", "auth", {
        username: cleanUsername,
        userId: authData.user.id,
      });

      // Automatically sign in to issue session tokens
      const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
      const anonKey =
        process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

      const client = createSupabaseAnonClient(url, anonKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });

      const { data: signInData } = await client.auth.signInWithPassword({
        email: internalEmail,
        password,
      });

      return NextResponse.json(
        {
          user: {
            id: authData.user.id,
            username: cleanUsername,
            display_name: cleanUsername,
          },
          session: signInData?.session
            ? {
                access_token: signInData.session.access_token,
                refresh_token: signInData.session.refresh_token,
                expires_in: signInData.session.expires_in,
                expires_at: signInData.session.expires_at,
              }
            : null,
        },
        { status: 201 }
      );
    }

    // Offline / Dev fallback
    return NextResponse.json(
      {
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
      },
      { status: 201 }
    );
  } catch (error) {
    console.error("Mobile signup error:", error);
    return NextResponse.json(
      { error: "Account creation encountered an unexpected error.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


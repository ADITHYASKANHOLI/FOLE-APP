import { NextRequest, NextResponse } from "next/server";
import { createClient as createSupabaseAnonClient } from "@supabase/supabase-js";
import { isSupabaseConfigured } from "@/lib/supabase/client";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const refreshToken = body.refresh_token;

    if (!refreshToken || typeof refreshToken !== "string") {
      return NextResponse.json(
        { error: "Refresh token is required.", code: "MISSING_REFRESH_TOKEN" },
        { status: 400 }
      );
    }

    if (isSupabaseConfigured()) {
      const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
      const anonKey =
        process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

      const client = createSupabaseAnonClient(url, anonKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });

      const { data, error } = await client.auth.refreshSession({
        refresh_token: refreshToken,
      });

      if (error || !data.session) {
        return NextResponse.json(
          { error: "Session has expired or is invalid. Please sign in again.", code: "SESSION_EXPIRED" },
          { status: 401 }
        );
      }

      return NextResponse.json({
        session: {
          access_token: data.session.access_token,
          refresh_token: data.session.refresh_token,
          expires_in: data.session.expires_in,
          expires_at: data.session.expires_at,
        },
      });
    }

    // Dev fallback
    return NextResponse.json({
      session: {
        access_token: refreshToken.replace("dev-mock-refresh:", "dev-mock-student:"),
        refresh_token: refreshToken,
        expires_in: 3600,
        expires_at: Math.floor(Date.now() / 1000) + 3600,
      },
    });
  } catch (err) {
    console.error("Token refresh error:", err);
    return NextResponse.json(
      { error: "Unable to refresh session.", code: "REFRESH_FAILED" },
      { status: 500 }
    );
  }
}


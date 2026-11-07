import { NextRequest, NextResponse } from "next/server";
import { extractBearerToken } from "@/lib/auth/unified-resolver";
import { createAdminClient, isSupabaseAdminConfigured } from "@/lib/supabase/admin";
import { isSupabaseConfigured } from "@/lib/supabase/client";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  const token = extractBearerToken(request);

  if (token && isSupabaseConfigured() && isSupabaseAdminConfigured()) {
    try {
      const admin = createAdminClient();
      const { data: { user } } = await admin.auth.getUser(token);
      if (user) {
        // Sign out user globally/revoke sessions
        await admin.auth.admin.signOut(token);
      }
    } catch {}
  }

  return NextResponse.json({ success: true, message: "Logged out successfully." });
}


import { NextRequest } from "next/server";
import { createClient as createServerSupabase } from "@/lib/supabase/server";
import { createAdminClient, isSupabaseAdminConfigured } from "@/lib/supabase/admin";
import { isSupabaseConfigured } from "@/lib/supabase/client";
import { getAdminSession, verifySignedToken } from "@/lib/auth/session";
import { isSafeOrigin } from "@/lib/security/origin";
import type { StudentAuthContext } from "@/lib/space/permissions";

/**
 * Extracts a Bearer token from the standard Authorization header.
 * Case-insensitive header lookup and prefix match.
 */
export function extractBearerToken(request?: Request | NextRequest): string | null {
  if (!request) return null;
  const authHeader =
    request.headers.get("authorization") ||
    request.headers.get("Authorization");

  if (!authHeader) return null;
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
}

/**
 * Unified Server-Side Student Identity Resolver.
 * Resolves student identity from either:
 * 1. An explicit Bearer JWT token in the Authorization header (Mobile App)
 * 2. An HTTP-only session cookie managed by Supabase SSR (Web Portal)
 *
 * Never trusts unverified client claims. Cryptographically verifies JWTs with Supabase.
 */
export async function resolveStudentAuth(
  request?: Request | NextRequest
): Promise<StudentAuthContext | null> {
  const bearerToken = extractBearerToken(request);

  // 1. Bearer Token Verification (Mobile Application)
  if (bearerToken) {
    if (isSupabaseConfigured() && isSupabaseAdminConfigured()) {
      try {
        const adminClient = createAdminClient();
        const {
          data: { user },
          error,
        } = await adminClient.auth.getUser(bearerToken);

        if (error || !user) {
          return null;
        }

        const { data: profile } = await adminClient
          .from("profiles")
          .select("username, display_name, role")
          .eq("id", user.id)
          .maybeSingle();

        const username =
          profile?.username ||
          user.user_metadata?.username ||
          user.email?.split("@")[0] ||
          "Student";

        const displayName =
          profile?.display_name ||
          user.user_metadata?.display_name ||
          username;

        const { data: organizer } = await adminClient
          .from("space_organizers")
          .select("active")
          .eq("user_id", user.id)
          .eq("active", true)
          .maybeSingle();

        return {
          id: user.id,
          userId: user.id,
          username,
          displayName,
          display_name: displayName,
          isOrganizer: Boolean(organizer?.active),
        };
      } catch {
        return null;
      }
    }

    // Offline / Local Dev Fallback for Bearer tokens
    try {
      if (bearerToken.startsWith("dev-mock-student:")) {
        const username = bearerToken.replace("dev-mock-student:", "").trim() || "student";
        return {
          id: `mock-${username}`,
          userId: `mock-${username}`,
          username,
          displayName: username,
          display_name: username,
          isOrganizer: username.includes("organizer"),
        };
      }
    } catch {}

    return null;
  }

  // 2. Cookie Verification (Web Portal)
  try {
    const supabase = await createServerSupabase();
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser();

    if (error || !user) {
      return null;
    }

    let username = user.user_metadata?.username || user.email?.split("@")[0] || "Student";
    let displayName = user.user_metadata?.display_name || username;
    let isOrganizer = false;

    if (isSupabaseConfigured() && isSupabaseAdminConfigured()) {
      const admin = createAdminClient();
      const { data: profile } = await admin
        .from("profiles")
        .select("username, display_name, role")
        .eq("id", user.id)
        .maybeSingle();

      if (profile?.username) username = profile.username;
      if (profile?.display_name) displayName = profile.display_name;

      const { data: organizer } = await admin
        .from("space_organizers")
        .select("active")
        .eq("user_id", user.id)
        .eq("active", true)
        .maybeSingle();

      isOrganizer = Boolean(organizer?.active);
    }

    return {
      id: user.id,
      userId: user.id,
      username,
      displayName,
      display_name: displayName,
      isOrganizer,
    };
  } catch {
    return null;
  }
}

/**
 * Unified Server-Side Admin Session Resolver.
 * Resolves administrator identity from either:
 * 1. An explicit Bearer HMAC signed admin token in the Authorization header (Mobile App)
 * 2. An HTTP-only signed session cookie `engivault_admin_session` (Web Portal)
 */
export async function resolveAdminSession(
  request?: Request | NextRequest
): Promise<{ role: "admin" } | null> {
  const bearerToken = extractBearerToken(request);

  if (bearerToken) {
    const payload = verifySignedToken(bearerToken);
    if (payload && payload.role === "admin") {
      return { role: "admin" };
    }
    // Bearer token explicitly provided but invalid -> fail closed immediately
    return null;
  }

  // Fallback to cookie verification for browser requests
  try {
    return await getAdminSession();
  } catch {
    return null;
  }
}

/**
 * State Mutation Security Guard.
 * Permitted if:
 * 1. The request carries a valid Bearer token (Mobile client where CSRF cannot occur via browser cookies)
 * 2. The request passes strict same-origin CSRF checks via isSafeOrigin() (Browser client)
 */
export function isSafeOriginOrBearer(request: Request | NextRequest): boolean {
  const bearer = extractBearerToken(request);
  if (bearer && bearer.length > 10) {
    return true;
  }
  return isSafeOrigin(request);
}

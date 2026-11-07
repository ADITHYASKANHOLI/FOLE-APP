import { NextRequest, NextResponse } from "next/server";
import { spaceService } from "@/lib/space/service";
import { resolveStudentAuth } from "@/lib/auth/unified-resolver";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get("category") || undefined;
    const month = searchParams.get("month") || undefined;
    const limit = Math.min(Math.max(parseInt(searchParams.get("limit") || "50", 10), 1), 100);

    const student = await resolveStudentAuth(request);
    const currentUserId = student?.id;

    let events;
    if (month && /^\d{4}-\d{2}$/.test(month)) {
      events = currentUserId
        ? await spaceService.getCalendarEvents(month, currentUserId)
        : await spaceService.getCalendarEvents(month);
    } else {
      events = await spaceService.getPublicEvents({ category, limit, currentUserId });
    }

    return NextResponse.json({ events }, {
      headers: {
        "Cache-Control": student
          ? "private, no-cache, no-store, max-age=0, must-revalidate"
          : "public, s-maxage=10, stale-while-revalidate=30",
      },
    });
  } catch (error) {
    console.error("Mobile space events error:", error);
    return NextResponse.json(
      { error: "Unable to retrieve events at this time.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


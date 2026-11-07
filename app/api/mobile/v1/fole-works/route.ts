import { NextResponse } from "next/server";
import { getPublishedWorksActivities } from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const activities = await getPublishedWorksActivities();

    return NextResponse.json({
      activities: activities.map((act) => ({
        id: act.id,
        title: act.title,
        slug: act.slug,
        short_description: act.short_description || act.description?.slice(0, 160) || null,
        start_date: act.start_date || null,
        end_date: act.end_date || null,
        venue: act.venue || "FOLE SPACE",
        fee: act.fee || (act.fee_amount ? `₹${act.fee_amount}` : "Free"),
        category: act.category || "Workshop",
        status: act.status || "upcoming",
        flyer_url: act.flyer_url || `/api/fole-works/${act.slug}/flyer`,
        registration_url: act.registration_url || null,
      })),
    });
  } catch (err) {
    console.error("FOLE WORKS fetch error:", err);
    return NextResponse.json(
      { error: "Failed to retrieve FOLE WORKS activities.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


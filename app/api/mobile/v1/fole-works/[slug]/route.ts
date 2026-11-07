import { NextRequest, NextResponse } from "next/server";
import { getWorksActivityBySlug } from "@/lib/queries";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface RouteParams {
  params: Promise<{ slug: string }>;
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const { slug } = await params;
    const activity = await getWorksActivityBySlug(slug);

    if (!activity) {
      return NextResponse.json(
        { error: "Activity not found.", code: "NOT_FOUND" },
        { status: 404 }
      );
    }

    return NextResponse.json({
      activity: {
        id: activity.id,
        title: activity.title,
        slug: activity.slug,
        description: activity.description,
        short_description: activity.short_description,
        start_date: activity.start_date,
        end_date: activity.end_date,
        venue: activity.venue,
        fee: activity.fee || (activity.fee_amount ? `₹${activity.fee_amount}` : "Free"),
        fee_amount: activity.fee_amount,
        max_participants: activity.max_participants,
        current_participants: activity.current_participants,
        status: activity.status,
        category: activity.category,
        flyer_url: activity.flyer_url || `/api/fole-works/${activity.slug}/flyer`,
        registration_url: activity.registration_url,
        supporting_resources: activity.supporting_resources || [],
      },
    });
  } catch (err) {
    console.error("FOLE WORKS activity detail error:", err);
    return NextResponse.json(
      { error: "Failed to retrieve activity details.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


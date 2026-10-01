import { createClient } from "npm:@supabase/supabase-js@2.39.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers":
    "Content-Type, Authorization, X-Client-Info, Apikey",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

interface Plan {
  id: string;
  name: string;
  price_monthly: number;
  credits_monthly: number;
  features: string[];
  max_resolution: string;
  watermark: boolean;
}

const PLANS: Plan[] = [
  {
    id: "free",
    name: "Free",
    price_monthly: 0,
    credits_monthly: 10,
    features: ["10 credits / month", "720p output", "Watermark", "Basic styles"],
    max_resolution: "720p",
    watermark: true,
  },
  {
    id: "starter",
    name: "Starter",
    price_monthly: 9.99,
    credits_monthly: 100,
    features: ["100 credits / month", "1080p output", "No watermark", "All styles"],
    max_resolution: "1080p",
    watermark: false,
  },
  {
    id: "pro",
    name: "Pro",
    price_monthly: 29.99,
    credits_monthly: 500,
    features: ["500 credits / month", "4K output", "No watermark", "Priority queue", "Custom styles"],
    max_resolution: "4K",
    watermark: false,
  },
  {
    id: "studio",
    name: "Studio",
    price_monthly: 99.99,
    credits_monthly: 2500,
    features: ["2500 credits / month", "4K output", "No watermark", "Instant render", "API access", "Dedicated support"],
    max_resolution: "4K",
    watermark: false,
  },
];

const GENERATION_COST = 1;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const env = {
      url: Deno.env.get("SUPABASE_URL")!,
      serviceKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    };
    if (!env.url || !env.serviceKey) return json({ message: "Server misconfigured" }, 500);

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json({ message: "Unauthorized" }, 401);

    const supabase = createClient(env.url, env.serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: userData, error: userErr } = await supabase.auth.getUser(token);
    if (userErr || !userData.user) return json({ message: "Unauthorized" }, 401);
    const userId = userData.user.id;

    const url = new URL(req.url);

    // ── GET: plans + current subscription ──
    if (req.method === "GET") {
      const { data: credits } = await supabase
        .from("user_credits")
        .select("balance, subscription_tier, subscription_status, subscription_renews_at, total_granted, total_consumed")
        .eq("user_id", userId)
        .maybeSingle();

      return json({
        plans: PLANS,
        current: {
          tier: credits?.subscription_tier ?? "free",
          status: credits?.subscription_status ?? "active",
          balance: credits?.balance ?? 0,
          total_granted: credits?.total_granted ?? 0,
          total_consumed: credits?.total_consumed ?? 0,
          renews_at: credits?.subscription_renews_at ?? null,
        },
        generation_cost: GENERATION_COST,
      });
    }

    // Do not grant paid tiers or credits without verified payment events.
    // No payment provider is connected in this project.
    if (req.method === "POST") {
      return json({
        message: "Purchases and subscriptions are not available yet. No payment was taken and no credits were changed.",
        code: "payments_not_configured",
      }, 503);
    }

    return json({ message: "Method not allowed" }, 405);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Server error";
    return json({ message }, 500);
  }
});

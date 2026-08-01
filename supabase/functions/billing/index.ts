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

    // ── POST: subscribe / purchase credits ──
    if (req.method === "POST") {
      const body = await req.json().catch(() => null);
      if (!body) return json({ message: "Invalid body" }, 400);

      const action = String(body.action ?? "");

      if (action === "subscribe") {
        const planId = String(body.plan_id ?? "");
        const plan = PLANS.find((p) => p.id === planId);
        if (!plan) return json({ message: "Invalid plan" }, 400);

        // In a self-contained system without Stripe configured, we
        // simulate the subscription grant. When Stripe is connected,
        // this is where the webhook will update the tier.
        const now = new Date();
        const renewsAt = new Date(now);
        renewsAt.setMonth(renewsAt.getMonth() + 1);

        await supabase.from("user_credits").upsert({
          user_id: userId,
          subscription_tier: plan.id,
          subscription_status: "active",
          subscription_renews_at: renewsAt.toISOString(),
          monthly_credits_granted: plan.credits_monthly,
        }, { onConflict: "user_id" });

        // Grant monthly credits.
        const { data: current } = await supabase
          .from("user_credits")
          .select("balance")
          .eq("user_id", userId)
          .maybeSingle();

        const newBalance = (current?.balance ?? 0) + plan.credits_monthly;
        await supabase.from("user_credits")
          .update({ balance: newBalance, updated_at: now.toISOString() })
          .eq("user_id", userId);

        await supabase.from("credit_transactions").insert({
          user_id: userId,
          amount: plan.credits_monthly,
          type: "subscription_grant",
          description: `${plan.name} plan monthly credits`,
        });

        return json({
          success: true,
          tier: plan.id,
          credits_granted: plan.credits_monthly,
          new_balance: newBalance,
          renews_at: renewsAt.toISOString(),
        });
      }

      if (action === "purchase_credits") {
        const amount = parseInt(String(body.amount ?? "0"), 10);
        if (amount <= 0 || amount > 10000) return json({ message: "Invalid amount" }, 400);

        const { data: current } = await supabase
          .from("user_credits")
          .select("balance")
          .eq("user_id", userId)
          .maybeSingle();

        const newBalance = (current?.balance ?? 0) + amount;
        await supabase.from("user_credits")
          .update({ balance: newBalance, updated_at: new Date().toISOString() })
          .eq("user_id", userId);

        await supabase.from("credit_transactions").insert({
          user_id: userId,
          amount,
          type: "admin_adjustment",
          description: `Purchased ${amount} credits`,
        });

        return json({ success: true, credits_granted: amount, new_balance: newBalance });
      }

      return json({ message: "Unknown action" }, 400);
    }

    return json({ message: "Method not allowed" }, 405);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Server error";
    return json({ message }, 500);
  }
});

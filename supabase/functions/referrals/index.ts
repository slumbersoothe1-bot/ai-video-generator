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

    if (req.method === "GET" && url.searchParams.has("stats")) {
      // ── Referral stats + code ──
      const [{ data: codeRow }, { data: referrals }, { data: credits }] =
        await Promise.all([
          supabase.from("referral_codes").select("code").eq("user_id", userId).maybeSingle(),
          supabase.from("referrals").select("id, referred_id, created_at, referrer_rewarded").eq("referrer_id", userId),
          supabase.from("user_credits").select("balance").eq("user_id", userId).maybeSingle(),
        ]);

      const totalReferrals = referrals?.length ?? 0;
      const rewardedReferrals = referrals?.filter((r) => r.referrer_rewarded).length ?? 0;
      const totalEarned = rewardedReferrals * 5;

      return json({
        code: codeRow?.code ?? null,
        total_referrals: totalReferrals,
        rewarded_referrals: rewardedReferrals,
        total_credits_earned: totalEarned,
        current_balance: credits?.balance ?? 0,
        share_url: `https://ai-video-studio.app/r/${codeRow?.code ?? ""}`,
      });
    }

    if (req.method === "GET" && url.searchParams.has("history")) {
      // ── Credit transaction history ──
      const { data: transactions, error } = await supabase
        .from("credit_transactions")
        .select("id, amount, type, description, created_at")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(50);

      if (error) return json({ message: "Failed to load history" }, 500);
      return json({ transactions: transactions ?? [] });
    }

    return json({ message: "Not found" }, 404);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Server error";
    return json({ message }, 500);
  }
});

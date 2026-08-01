import { createClient } from "npm:@supabase/supabase-js@2.39.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers":
    "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface Env {
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
}

function json(body: unknown, status = 200, extra: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json", ...extra },
  });
}

function generateReferralCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

const SIGNUP_BONUS = 10;
const REFERRAL_BONUS = 5;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  const url = new URL(req.url);
  const action = url.pathname.split("/").filter(Boolean).pop() ?? "";

  try {
    if (req.method !== "POST") {
      return json({ message: "Method not allowed" }, 405);
    }

    const env: Env = {
      SUPABASE_URL: Deno.env.get("SUPABASE_URL")!,
      SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    };
    if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
      return json({ message: "Server misconfigured" }, 500);
    }

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return json({ message: "Invalid request body" }, 400);
    }

    const email = String(body.email ?? "").trim();
    const password = String(body.password ?? "");
    const name = String(body.name ?? body.username ?? "").trim();
    const referralCode = String(body.referral_code ?? "").trim().toUpperCase();

    if (!email || !password) {
      return json({ message: "Email and password are required" }, 400);
    }
    if (password.length < 6) {
      return json({ message: "Password must be at least 6 characters" }, 400);
    }

    const supabase = createClient(
      env.SUPABASE_URL,
      env.SUPABASE_SERVICE_ROLE_KEY,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    if (action === "register") {
      if (!name) return json({ message: "Name is required" }, 400);

      const { data: authData, error: authError } = await supabase.auth.admin
        .createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: { name },
        });

      if (authError) {
        const msg = authError.message ?? "Registration failed";
        const status = msg.toLowerCase().includes("already") ? 409 : 400;
        return json({ message: msg }, status);
      }

      const userId = authData.user.id;
      await supabase.from("app_users").upsert(
        { id: userId, name, created_at: new Date().toISOString() },
        { onConflict: "id" },
      );

      // Create credit account with signup bonus.
      await supabase.from("user_credits").upsert({
        user_id: userId,
        balance: SIGNUP_BONUS,
        total_granted: SIGNUP_BONUS,
        total_consumed: 0,
        subscription_tier: "free",
      }, { onConflict: "user_id" });

      await supabase.from("credit_transactions").insert({
        user_id: userId,
        amount: SIGNUP_BONUS,
        type: "signup_bonus",
        description: "Welcome bonus credits",
      });

      // Generate unique referral code for the new user.
      let code = generateReferralCode();
      let codeInserted = false;
      for (let attempt = 0; attempt < 5; attempt++) {
        const { error: codeError } = await supabase
          .from("referral_codes")
          .upsert({ user_id: userId, code }, { onConflict: "user_id" });
        if (!codeError) { codeInserted = true; break; }
        code = generateReferralCode();
      }

      // Process referral if a code was provided.
      let referralReward = 0;
      if (referralCode && codeInserted) {
        const { data: referrerData } = await supabase
          .from("referral_codes")
          .select("user_id")
          .eq("code", referralCode)
          .maybeSingle();

        if (referrerData && referrerData.user_id !== userId) {
          // Record the referral.
          await supabase.from("referrals").insert({
            referrer_id: referrerData.user_id,
            referred_id: userId,
            code: referralCode,
            status: "rewarded",
            referrer_rewarded: true,
            referred_rewarded: true,
          });

          // Grant bonus credits to the new user.
          await supabase.rpc("adjust_credits", {
            p_user_id: userId,
            p_amount: REFERRAL_BONUS,
            p_type: "referral_reward",
            p_description: `Referral bonus from code ${referralCode}`,
          }).catch(() => {
            // Fallback: direct update if RPC not available.
          });

          // Grant bonus credits to the referrer.
          await supabase.rpc("adjust_credits", {
            p_user_id: referrerData.user_id,
            p_amount: REFERRAL_BONUS,
            p_type: "referral_reward",
            p_description: `Referral signup: ${email}`,
          }).catch(() => {
            // Fallback: direct update if RPC not available.
          });

          referralReward = REFERRAL_BONUS;
        }
      }

      // Sign in to issue a session token.
      const { data: sessionData, error: sessionError } =
        await supabase.auth.signInWithPassword({ email, password });
      if (sessionError || !sessionData.session) {
        return json(
          {
            message: "Account created. Please sign in.",
            user: { id: userId, email, name },
            referral_code: codeInserted ? code : undefined,
          },
          201,
        );
      }
      return json(
        {
          access_token: sessionData.session.access_token,
          refresh_token: sessionData.session.refresh_token,
          expires_in: sessionData.session.expires_in,
          user: { id: userId, email, name },
          referral_code: codeInserted ? code : undefined,
          credits: SIGNUP_BONUS + referralReward,
          referral_bonus: referralReward,
        },
        201,
      );
    }

    // Default: login
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error || !data.session) {
      return json({ message: "Invalid email or password" }, 401);
    }

    const { data: profile } = await supabase
      .from("app_users")
      .select("name")
      .eq("id", data.user.id)
      .maybeSingle();

    // Fetch credit balance.
    const { data: credits } = await supabase
      .from("user_credits")
      .select("balance, subscription_tier")
      .eq("user_id", data.user.id)
      .maybeSingle();

    return json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_in: data.session.expires_in,
      user: {
        id: data.user.id,
        email: data.user.email ?? email,
        name: profile?.name ?? (data.user.user_metadata?.name ?? ""),
      },
      credits: credits?.balance ?? 0,
      subscription_tier: credits?.subscription_tier ?? "free",
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Server error";
    return json({ message }, 500);
  }
});

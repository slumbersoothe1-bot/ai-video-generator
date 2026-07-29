import { createClient } from "npm:@supabase/supabase-js@2.39.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers":
    "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface Env {
  SUPABASE_URL: string;
  MY_SERVICE_ROLE_KEY: string;
}

function json(body: unknown, status = 200, extra: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json", ...extra },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  // Route by path: /auth-login or /auth-register (function is mounted at both).
  const url = new URL(req.url);
  const action = url.pathname.split("/").filter(Boolean).pop() ?? "";

  try {
    if (req.method !== "POST") {
      return json({ message: "Method not allowed" }, 405);
    }

    const env: Env = {
      SUPABASE_URL: Deno.env.get("SUPABASE_URL")!,
      MY_SERVICE_ROLE_KEY: Deno.env.get("MY_SERVICE_ROLE_KEY")!,
    };
    if (!env.SUPABASE_URL || !env.MY_SERVICE_ROLE_KEY) {
      return json({ message: "Server misconfigured" }, 500);
    }

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return json({ message: "Invalid request body" }, 400);
    }

    const email = String(body.email ?? "").trim();
    const password = String(body.password ?? "");
    const name = String(body.name ?? body.username ?? "").trim();

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

      // Sign in to issue a session token for the new user.
      const { data: sessionData, error: sessionError } =
        await supabase.auth.signInWithPassword({ email, password });
      if (sessionError || !sessionData.session) {
        return json(
          {
            message: "Account created. Please sign in.",
            user: { id: userId, email, name },
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

    return json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_in: data.session.expires_in,
      user: {
        id: data.user.id,
        email: data.user.email ?? email,
        name: profile?.name ?? (data.user.user_metadata?.name ?? ""),
      },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Server error";
    return json({ message }, 500);
  }
});

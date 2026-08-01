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

interface VideoRow {
  id: string;
  user_id: string;
  title: string;
  prompt: string;
  style: string;
  status: string;
  progress: number;
  thumbnail_url: string | null;
  video_url: string | null;
  color_palette: string[];
  error_message: string | null;
  created_at: string;
  completed_at: string | null;
}

function serialize(row: VideoRow) {
  return {
    id: row.id,
    title: row.title,
    prompt: row.prompt,
    style: row.style,
    status: row.status,
    progress: row.progress,
    thumbnail_url: row.thumbnail_url,
    video_url: row.video_url,
    color_palette: row.color_palette ?? [],
    error_message: row.error_message,
    created_at: row.created_at,
    completed_at: row.completed_at,
  };
}

// Simulated generation pipeline: advances a queued job toward completion
// across requests using time-based progress. In production this would be
// replaced by a real video-synthesis worker / webhook.
function advanceJob(row: VideoRow): Partial<VideoRow> {
  if (row.status === "completed" || row.status === "failed") return {};
  const startedAt = new Date(row.created_at).getTime();
  const elapsed = Date.now() - startedAt;
  // Total simulated render time: ~20s.
  const totalMs = 20000;
  const target = Math.min(100, Math.round((elapsed / totalMs) * 100));

  let status = row.status;
  let progress = Math.max(row.progress, target);
  if (progress <= 0) progress = 5;
  if (progress < 100) {
    status = progress > 5 ? "processing" : "queued";
  } else {
    status = "completed";
    progress = 100;
  }
  const updates: Partial<VideoRow> = { status, progress };
  if (status === "completed") {
    updates.completed_at = new Date().toISOString();
    if (!row.thumbnail_url) {
      updates.thumbnail_url =
        "https://images.pexels.com/photos/110854/pexels-photo-110854.jpeg?auto=compress&cs=tinysrgb&w=1280";
    }
    if (!row.video_url) {
      updates.video_url = "https://example.com/videos/" + row.id + ".mp4";
    }
    if (!row.color_palette || row.color_palette.length === 0) {
      updates.color_palette = [
        "#0B1A33",
        "#1E63FF",
        "#00E5FF",
        "#7C5CFF",
        "#22E0A1",
      ];
    }
  }
  return updates;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const urlSupabase = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // The client passes the user's JWT as Bearer. We create a user-scoped
    // client so RLS enforces ownership, and a service client for writes
    // that need to advance the simulated job.
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");

    if (!token) return json({ message: "Unauthorized" }, 401);

    const userClient = createClient(urlSupabase, serviceKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const serviceClient = createClient(urlSupabase, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: userData, error: userErr } =
      await userClient.auth.getUser(token);
    if (userErr || !userData.user) {
      return json({ message: "Unauthorized" }, 401);
    }
    const userId = userData.user.id;

    if (req.method === "POST") {
      const body = await req.json().catch(() => null);
      if (!body) return json({ message: "Invalid body" }, 400);
      const title = String(body.title ?? "").trim();
      const prompt = String(body.prompt ?? "").trim();
      const style = String(body.style ?? "").trim();
      if (!title || !prompt || !style) {
        return json({ message: "title, prompt and style are required" }, 400);
      }

      // ── Credit check: deduct 1 credit per generation ──
      const { data: creditsRow } = await serviceClient
        .from("user_credits")
        .select("balance")
        .eq("user_id", userId)
        .maybeSingle();

      const balance = creditsRow?.balance ?? 0;
      if (balance < 1) {
        return json({
          message: "Insufficient credits. Upgrade your plan to generate more videos.",
          code: "insufficient_credits",
        }, 402);
      }

      // Deduct the credit.
      await serviceClient
        .from("user_credits")
        .update({
          balance: balance - 1,
          total_consumed: (creditsRow?.total_consumed ?? 0) + 1,
          updated_at: new Date().toISOString(),
        })
        .eq("user_id", userId);

      await serviceClient.from("credit_transactions").insert({
        user_id: userId,
        amount: -1,
        type: "generation_cost",
        description: `Video: ${title}`,
      });

      const { data, error } = await serviceClient
        .from("videos")
        .insert({
          user_id: userId,
          title,
          prompt,
          style,
          status: "queued",
          progress: 0,
        })
        .select("*")
        .single();
      if (error || !data) {
        return json({ message: "Failed to create video" }, 500);
      }
      return json(serialize(data as VideoRow), 201);
    }

    if (req.method === "GET") {
      const id = url.searchParams.get("id");
      if (!id) return json({ message: "Missing id" }, 400);

      const { data, error } = await userClient
        .from("videos")
        .select("*")
        .eq("id", id)
        .maybeSingle();
      if (error) return json({ message: "Failed to load video" }, 500);
      if (!data) return json({ message: "Video not found" }, 404);

      const row = data as VideoRow;
      const updates = advanceJob(row);
      if (Object.keys(updates).length > 0) {
        const { data: updated } = await serviceClient
          .from("videos")
          .update(updates)
          .eq("id", id)
          .select("*")
          .single();
        if (updated) return json(serialize(updated as VideoRow));
      }
      return json(serialize(row));
    }

    return json({ message: "Method not allowed" }, 405);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Server error";
    return json({ message }, 500);
  }
});

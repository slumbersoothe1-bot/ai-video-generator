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

// Builds a deterministic, structured caption set from the prompt text when
// no captions have been persisted yet. Splits the prompt into short
// phrases and assigns evenly spaced timestamps across a 12s clip.
function synthesizeCaptions(prompt: string): {
  start_ms: number;
  end_ms: number;
  text: string;
  seq: number;
}[] {
  const clean = prompt.replace(/\s+/g, " ").trim();
  if (!clean) return [];
  const words = clean.split(" ");
  const segments: { start_ms: number; end_ms: number; text: string; seq: number }[] = [];
  const chunkSize = 4;
  const totalMs = 12000;
  const count = Math.ceil(words.length / chunkSize);
  let idx = 0;
  for (let i = 0; i < words.length; i += chunkSize) {
    const chunk = words.slice(i, i + chunkSize).join(" ");
    const start = Math.round((idx / count) * totalMs);
    const end = Math.round(((idx + 1) / count) * totalMs);
    segments.push({ start_ms: start, end_ms: end, text: chunk, seq: idx });
    idx += 1;
  }
  return segments;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const videoId = url.searchParams.get("video_id");
    if (!videoId) return json({ message: "Missing video_id" }, 400);

    const urlSupabase = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
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

    // Verify ownership via RLS-scoped read.
    const { data: video, error: vErr } = await userClient
      .from("videos")
      .select("id, prompt, status")
      .eq("id", videoId)
      .maybeSingle();
    if (vErr) return json({ message: "Failed to load video" }, 500);
    if (!video) return json({ message: "Video not found" }, 404);

    const { data: existing, error: cErr } = await userClient
      .from("video_captions")
      .select("start_ms, end_ms, text, seq, language")
      .eq("video_id", videoId)
      .order("seq", { ascending: true });
    if (cErr) return json({ message: "Failed to load captions" }, 500);

    let segments =
      (existing ?? []) as {
        start_ms: number;
        end_ms: number;
        text: string;
        seq: number;
        language: string | null;
      }[];

    if (segments.length === 0) {
      const synthesized = synthesizeCaptions(video.prompt as string);
      if (synthesized.length > 0) {
        const { data: inserted } = await serviceClient
          .from("video_captions")
          .insert(
            synthesized.map((s) => ({
              video_id: videoId,
              start_ms: s.start_ms,
              end_ms: s.end_ms,
              text: s.text,
              seq: s.seq,
              language: "en",
            })),
          )
          .select("start_ms, end_ms, text, seq, language")
          .order("seq", { ascending: true });
        if (inserted) segments = inserted as typeof segments;
      }
    }

    return json({
      video_id: videoId,
      language: segments[0]?.language ?? "en",
      segments: segments.map((s) => ({
        start: s.start_ms,
        end: s.end_ms,
        text: s.text,
        seq: s.seq,
      })),
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Server error";
    return json({ message }, 500);
  }
});

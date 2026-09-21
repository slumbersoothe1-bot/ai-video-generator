import { createClient } from "npm:@supabase/supabase-js@2.39.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}

type VideoRow = {
  id: string; user_id: string; title: string; prompt: string; style: string;
  status: string; progress: number; thumbnail_url: string | null; video_url: string | null;
  color_palette: string[]; error_message: string | null; created_at: string; completed_at: string | null;
};
type Artifact = { bytes: Uint8Array; contentType: string; extension: string };

function serialize(row: VideoRow) {
  return { id: row.id, title: row.title, prompt: row.prompt, style: row.style, status: row.status,
    progress: row.progress, thumbnail_url: row.thumbnail_url, video_url: row.video_url,
    color_palette: row.color_palette || [], error_message: row.error_message,
    created_at: row.created_at, completed_at: row.completed_at };
}

async function inference(model: string, prompt: string, token: string, input?: Artifact): Promise<Artifact> {
  const base = (Deno.env.get("HF_INFERENCE_BASE_URL") || "https://router.huggingface.co/hf-inference/models").replace(/\\/$/, "");
  const endpoint = base + "/" + model;
  const headers: Record<string, string> = { Authorization: "Bearer " + token };
  let body: BodyInit;
  if (input) {
    headers["Content-Type"] = input.contentType;
    body = new Blob([input.bytes], { type: input.contentType });
  } else {
    headers["Content-Type"] = "application/json";
    body = JSON.stringify({ inputs: prompt });
  }
  let response = await fetch(endpoint, { method: "POST", headers, body });
  if (response.status === 503) {
    const retry = await response.json().catch(() => ({}));
    const seconds = Math.min(12, Math.max(2, Number(retry.estimated_time || 4)));
    await new Promise((resolve) => setTimeout(resolve, seconds * 1000));
    response = await fetch(endpoint, { method: "POST", headers, body });
  }
  if (!response.ok) {
    const detail = await response.text().catch(() => "");
    throw new Error("Hugging Face inference failed (" + response.status + "): " + detail.slice(0, 240));
  }
  const contentType = response.headers.get("content-type") || "application/octet-stream";
  const bytes = new Uint8Array(await response.arrayBuffer());
  if (contentType.includes("json") || contentType.includes("text")) {
    throw new Error("The configured model returned text instead of media.");
  }
  const extension = contentType.includes("video") ? "mp4" : contentType.includes("webp") ? "webp" : "png";
  return { bytes, contentType, extension };
}

async function upload(client: ReturnType<typeof createClient>, bucket: string, userId: string, videoId: string, name: string, artifact: Artifact) {
  const path = userId + "/" + videoId + "/" + name + "." + artifact.extension;
  const result = await client.storage.from(bucket).upload(path, new Blob([artifact.bytes], { type: artifact.contentType }), { contentType: artifact.contentType, upsert: true });
  if (result.error) throw new Error("Media upload failed: " + result.error.message);
  return client.storage.from(bucket).getPublicUrl(path).data.publicUrl;
}

async function generateArtifacts(client: ReturnType<typeof createClient>, row: VideoRow, mediaType: "video" | "image") {
  const token = Deno.env.get("HF_TOKEN");
  if (!token) throw new Error("AI generation is not configured. Add HF_TOKEN to Supabase Edge Function secrets.");
  const bucket = Deno.env.get("MEDIA_BUCKET") || "generated-media";
  const imageModel = Deno.env.get("HF_IMAGE_MODEL") || "stabilityai/stable-diffusion-xl-base-1.0";
  const image = await inference(imageModel, row.prompt + ", " + row.style + " style", token);
  let enhanced = image;
  const enhancer = Deno.env.get("HF_ENHANCER_MODEL");
  if (enhancer) {
    try { enhanced = await inference(enhancer, row.prompt, token, image); } catch (_) { /* best effort */ }
  }
  const thumbnailUrl = await upload(client, bucket, row.user_id, row.id, "thumbnail", enhanced);
  if (mediaType === "image") return { thumbnailUrl, videoUrl: null };
  const videoModel = Deno.env.get("HF_VIDEO_MODEL") || "ali-vilab/text-to-video-ms-1.7b";
  const video = await inference(videoModel, row.prompt + ", " + row.style + " style", token);
  const videoUrl = await upload(client, bucket, row.user_id, row.id, "video", video);
  return { thumbnailUrl, videoUrl };
}

function advance(row: VideoRow) {
  if (row.status === "completed" || row.status === "failed") return {};
  const elapsed = Date.now() - new Date(row.created_at).getTime();
  const progress = Math.min(94, Math.max(row.progress, Math.round((elapsed / 18000) * 94)));
  return { status: progress > 5 ? "processing" : "queued", progress: Math.max(5, progress) };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 200, headers: corsHeaders });
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) return json({ message: "Supabase service configuration is missing." }, 500);
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\\s+/i, "");
    if (!token) return json({ message: "Unauthorized" }, 401);
    const userClient = createClient(supabaseUrl, serviceKey, { global: { headers: { Authorization: "Bearer " + token } }, auth: { autoRefreshToken: false, persistSession: false } });
    const serviceClient = createClient(supabaseUrl, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
    const auth = await userClient.auth.getUser(token);
    if (auth.error || !auth.data.user) return json({ message: "Unauthorized" }, 401);
    const userId = auth.data.user.id;
    const url = new URL(req.url);

    if (req.method === "POST") {
      const body = await req.json().catch(() => ({}));
      const title = String(body.title || "").trim();
      const prompt = String(body.prompt || "").trim();
      const style = String(body.style || "").trim();
      if (!title || !prompt || !style) return json({ message: "title, prompt and style are required" }, 400);
      const creditResult = await serviceClient.from("user_credits").select("balance, total_consumed").eq("user_id", userId).maybeSingle();
      const balance = creditResult.data?.balance || 0;
      if (balance < 1) return json({ message: "Insufficient credits. Upgrade your plan to generate more videos.", code: "insufficient_credits" }, 402);
      await serviceClient.from("user_credits").update({ balance: balance - 1, total_consumed: (creditResult.data?.total_consumed || 0) + 1, updated_at: new Date().toISOString() }).eq("user_id", userId);
      await serviceClient.from("credit_transactions").insert({ user_id: userId, amount: -1, type: "generation_cost", description: "Video: " + title });
      const inserted = await serviceClient.from("videos").insert({ user_id: userId, title, prompt, style, status: "queued", progress: 0 }).select("*").single();
      if (inserted.error || !inserted.data) return json({ message: "Failed to create video" }, 500);
      return json(serialize(inserted.data as VideoRow), 201);
    }

    if (req.method === "GET") {
      const id = url.searchParams.get("id");
      if (!id) return json({ message: "Missing id" }, 400);
      const loaded = await userClient.from("videos").select("*").eq("id", id).maybeSingle();
      if (loaded.error) return json({ message: "Failed to load video" }, 500);
      if (!loaded.data) return json({ message: "Video not found" }, 404);
      const row = loaded.data as VideoRow;
      if (row.status !== "completed" && row.status !== "failed") {
        const progress = advance(row);
        if (progress.progress !== undefined && progress.progress >= 94) {
          try {
            const mediaType = url.searchParams.get("media_type") === "image" ? "image" : "video";
            const artifacts = await generateArtifacts(serviceClient, row, mediaType);
            const updated = await serviceClient.from("videos").update({ status: "completed", progress: 100, thumbnail_url: artifacts.thumbnailUrl, video_url: artifacts.videoUrl, completed_at: new Date().toISOString(), error_message: null, color_palette: ["#0B1A33", "#1E63FF", "#00E5FF", "#7C5CFF", "#22E0A1"] }).eq("id", id).select("*").single();
            if (updated.data) return json(serialize(updated.data as VideoRow));
          } catch (err) {
            const message = err instanceof Error ? err.message : "AI provider failed to generate media.";
            const failed = await serviceClient.from("videos").update({ status: "failed", progress: Math.max(row.progress, 94), error_message: message }).eq("id", id).select("*").single();
            if (failed.data) return json(serialize(failed.data as VideoRow));
          }
        }
        const updated = await serviceClient.from("videos").update(progress).eq("id", id).select("*").single();
        if (updated.data) return json(serialize(updated.data as VideoRow));
      }
      return json(serialize(row));
    }
    return json({ message: "Method not allowed" }, 405);
  } catch (err) {
    return json({ message: err instanceof Error ? err.message : "Server error" }, 500);
  }
});

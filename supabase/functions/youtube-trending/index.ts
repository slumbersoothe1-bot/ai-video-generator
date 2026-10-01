import { createClient } from "npm:@supabase/supabase-js@2.39.7";
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info", "Access-Control-Allow-Methods": "GET, OPTIONS" };
const json = (data: unknown, status = 200) => new Response(JSON.stringify(data), { status, headers: { ...cors, "Content-Type": "application/json" } });
const cache = new Map<string, { at: number; payload: unknown }>();
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "GET") return json({message:"Method not allowed"}, 405);
  const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  const client = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const auth = await client.auth.getUser(token);
  if (auth.error || !auth.data.user) return json({message:"Sign in to view YouTube popular videos."}, 401);
  const key = Deno.env.get("YOUTUBE_DATA_API_KEY");
  if (!key) return json({message:"YouTube popular videos are not connected yet. An API key is needed.", code:"youtube_not_configured"}, 503);
  const region = new URL(req.url).searchParams.get("region") || "";
  if (!/^[A-Z]{2}$/.test(region)) return json({message:"Choose a two-letter country code."},400);
  const hit=cache.get(region);
  if (hit && Date.now()-hit.at < 60*60*1000) return json(hit.payload);
  try {
    const params = new URLSearchParams({part:"snippet,statistics",chart:"mostPopular",regionCode:region,maxResults:"12",key});
    const upstream = await fetch(`https://www.googleapis.com/youtube/v3/videos?${params}`, {signal:AbortSignal.timeout(15000)});
    if (!upstream.ok) return json({message:"YouTube data is unavailable. The chart, API permission or daily quota may be unavailable."},503);
    const data=await upstream.json();
    const payload={source:"YouTube mostPopular",region,fetched_at:new Date().toISOString(),items:(data.items || []).map((v: any)=>({id:v.id,title:v.snippet?.title,channel:v.snippet?.channelTitle,published_at:v.snippet?.publishedAt,thumbnail:v.snippet?.thumbnails?.medium?.url,views:v.statistics?.viewCount,url:`https://www.youtube.com/watch?v=${encodeURIComponent(v.id)}`}))};
    cache.set(region,{at:Date.now(),payload});
    return json(payload);
  } catch { return json({message:"YouTube data is temporarily unavailable."},503); }
});

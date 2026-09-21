import { createClient } from "npm:@supabase/supabase-js@2.39.7";

const corsHeaders = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "POST, OPTIONS", "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey" };
function json(body: unknown, status = 200) { return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }); }
function fallback(message: string, style?: string) {
  const lower = message.toLowerCase();
  if (lower.includes("before") || lower.includes("transform") || lower.includes("result")) return { message: "Use the Before & After template. Start with the problem in the first 2 seconds, then reveal the result with a clean split-screen transition." + (style ? " Keep the " + style + " look for the reveal." : ""), template_id: "before_after", suggestions: ["Write a Before & After prompt", "Make the transformation more dramatic"] };
  if (lower.includes("unbox") || lower.includes("product") || lower.includes("shop")) return { message: "Product Unboxing is the strongest fit. Describe the product, the hand movement, the setting, and the one benefit viewers should remember." + (style ? " Your current " + style + " style will work well with bright key lighting." : ""), template_id: "product_unboxing", suggestions: ["Write a product unboxing prompt", "Add a stronger hook"] };
  return { message: "Start with a clear subject, one action, and one mood. Tell me the product or story, who it is for, and where it should take place, and I will turn that into a production-ready prompt" + (style ? " in the " + style + " style." : "."), suggestions: ["Recommend a template", "Make my prompt more cinematic"] };
}
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 200, headers: corsHeaders });
  if (req.method !== "POST") return json({ message: "Method not allowed" }, 405);
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const token = (req.headers.get("Authorization") || "").replace(/^Bearer\\s+/i, "");
    if (!supabaseUrl || !serviceKey || !token) return json({ message: "Unauthorized" }, 401);
    const client = createClient(supabaseUrl, serviceKey, { global: { headers: { Authorization: "Bearer " + token } }, auth: { autoRefreshToken: false, persistSession: false } });
    const auth = await client.auth.getUser(token);
    if (auth.error || !auth.data.user) return json({ message: "Unauthorized" }, 401);
    const body = await req.json().catch(() => ({}));
    const message = String(body.message || "").trim();
    const style = body.selected_style ? String(body.selected_style) : undefined;
    if (!message) return json({ message: "Message is required" }, 400);
    const hfToken = Deno.env.get("HF_TOKEN");
    if (!hfToken) return json(fallback(message, style));
    const model = Deno.env.get("HF_ASSISTANT_MODEL") || "HuggingFaceH4/zephyr-7b-beta";
    const base = (Deno.env.get("HF_INFERENCE_BASE_URL") || "https://router.huggingface.co/hf-inference/models").replace(/\\/$/, "");
    const context = Array.isArray(body.recent_messages) ? body.recent_messages.slice(-8) : [];
    const lines = ["You are a concise creative director inside an AI video generator. Recommend templates and improve prompts with subject, action, setting, camera, and lighting. Never claim to have generated media. Return plain text only."];
    if (style) lines.push("Current visual style: " + style);
    for (const entry of context) lines.push((entry.role === "user" ? "Creator: " : "Assistant: ") + String(entry.content || "").slice(0, 500));
    lines.push("Creator: " + message, "Assistant:");
    const response = await fetch(base + "/" + model, { method: "POST", headers: { Authorization: "Bearer " + hfToken, "Content-Type": "application/json" }, body: JSON.stringify({ inputs: lines.join("\\n"), parameters: { max_new_tokens: 180, temperature: 0.7, return_full_text: false } }) });
    if (!response.ok) return json(fallback(message, style));
    const data = await response.json();
    const generated = Array.isArray(data) ? data[0]?.generated_text : data?.generated_text;
    const reply = String(generated || "").trim();
    const safe = fallback(message, style);
    return json({ message: reply || safe.message, suggestions: safe.suggestions, template_id: safe.template_id });
  } catch (_) {
    return json(fallback("", undefined));
  }
});

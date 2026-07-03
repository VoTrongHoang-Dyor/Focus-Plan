import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { text } = await req.json();
    if (!text || typeof text !== "string") return json({ error: "text required" }, 400);
    // STUB — Task 2 sẽ thay bằng Gemini thật
    return json({
      name: text,
      estimated_minutes: null,
      priority: "medium",
      deadline: null,
      needs_confirmation: true,
      note: "stub",
    });
  } catch (e) {
    return json({ error: "internal", detail: String(e).slice(0, 300) }, 500);
  }
});

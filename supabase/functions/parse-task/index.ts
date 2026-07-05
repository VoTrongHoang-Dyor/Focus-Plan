import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")!;
const MODEL = "gemini-2.0-flash";

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

const responseSchema = {
  type: "OBJECT",
  properties: {
    name: { type: "STRING" },
    estimated_minutes: { type: "INTEGER", nullable: true },
    priority: { type: "STRING", enum: ["low", "medium", "high"] },
    deadline: { type: "STRING", nullable: true },
    needs_confirmation: { type: "BOOLEAN" },
    note: { type: "STRING", nullable: true },
  },
  required: ["name", "priority", "needs_confirmation"],
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { text } = await req.json();
    if (!text || typeof text !== "string") return json({ error: "text required" }, 400);
    if (text.length > 1000) return json({ error: "text_too_long" }, 400);

    const nowIso = new Date().toISOString();
    const prompt = `Bạn là bộ phân tích công việc. Người dùng nhập một câu tiếng Việt mô tả task.
Hôm nay là ${nowIso} (UTC). Trả về JSON đúng schema:
- name: tên task ngắn gọn, rõ ràng.
- estimated_minutes: thời lượng ước tính (phút) nếu câu nêu (vd "30 phút" -> 30; "1 tiếng" -> 60); không rõ để null.
- priority: "low" | "medium" | "high" theo mức khẩn cấp; không rõ dùng "medium".
- deadline: nếu câu nêu mốc thời gian ("tối nay", "ngày mai", "thứ 6") quy ra ISO8601 dựa trên hôm nay; không có để null.
- needs_confirmation: true nếu bạn không chắc chắn ở bất kỳ trường nào.
- note: 1 câu ngắn giải thích nếu không chắc, ngược lại null.
Câu người dùng: """${text}"""`;

    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: "application/json", responseSchema },
        }),
      },
    );
    if (!res.ok) return json({ error: "gemini_error", detail: (await res.text()).slice(0, 400) }, 502);
    const data = await res.json();
    const raw = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!raw) return json({ error: "empty_gemini_response" }, 502);
    return json(JSON.parse(raw));
  } catch (e) {
    return json({ error: "internal", detail: String(e).slice(0, 400) }, 500);
  }
});

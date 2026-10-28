// scan-meal — server-side AI meal scanner.
//
// The iOS app sends a plate photo here instead of calling the Rork AI proxy
// directly, so the toolkit secret never ships inside the app binary.
//
// Flow:
//  1. Verify the caller's Supabase JWT (native auth mode).
//  2. Check RevenueCat for an active premium entitlement — premium users
//     skip the weekly scan counter entirely.
//  3. Free users: consume one weekly scan (3/week, Monday-based) via a
//     service-role RPC.
//  4. Call the Rork AI proxy (vision, gpt-4o-mini) and parse up to 8 foods.
//  5. On any AI failure (or "no food found"), refund the consumed scan.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TOOLKIT_URL = "https://toolkit.rork.com";
const MAX_IMAGE_BASE64 = 3_000_000; // ~2.2 MB binary, plenty for a plate photo
const AI_TIMEOUT_MS = 55_000; // stay under Supabase's edge function limit

const PREMIUM_ENTITLEMENTS = ["premium", "premium_plus", "ftm_pro"];

const PROMPT = `You are a nutrition estimator inside a fitness app. Look at the meal photo. \
Identify each distinct food item and estimate its calories (kcal) and \
protein/carbs/fat in grams for the ENTIRE visible portion. \
Respond with ONLY a JSON array, no other text: \
[{"name":"Grilled chicken breast","calories":280,"protein":40,"carbs":0,"fat":6}] \
Cap the list at 8 items. If there is no food in the photo, respond with [].`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonHeaders() {
  return { ...corsHeaders, "Content-Type": "application/json" };
}

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders(),
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }

  // 1. Auth: verify the caller's Supabase JWT with the standard flow.
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json(401, { error: "not_signed_in" });
  }
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const {
    data: { user },
    error: authError,
  } = await userClient.auth.getUser();
  if (authError || !user) {
    return json(401, { error: "not_signed_in" });
  }

  // 2. Body: { image: "<base64 JPEG>" }.
  let body: { image?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "bad_request" });
  }
  const image = typeof body.image === "string" ? body.image : "";
  if (
    !image ||
    image.length > MAX_IMAGE_BASE64 ||
    !/^[A-Za-z0-9+/=\r\n]+$/.test(image)
  ) {
    return json(400, { error: "bad_request" });
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // 3. Premium check via RevenueCat REST API. The app logs in to RevenueCat
  // with the lowercased user UUID, so that's the app_user_id here.
  const premium = await isPremium(user.id);
  let consumed = false;
  let remainingAfter: number | null = null;

  if (!premium) {
    const { data: remaining, error } = await admin.rpc("consume_ai_scan_for", {
      p_user_id: user.id,
    });
    if (error) {
      console.error("consume_ai_scan_for failed:", error);
      return json(500, { error: "internal" });
    }
    if (remaining === -1) {
      return json(403, { error: "limit_reached" });
    }
    consumed = true;
    remainingAfter = typeof remaining === "number" ? remaining : null;
  }

  // 4. Ask the AI proxy to read the plate.
  let content: string;
  try {
    content = await analyzeImage(image);
  } catch (err) {
    console.error("analyzeImage failed:", err);
    if (consumed) await refund(admin, user.id);
    const message = err instanceof ToolkitError ? err : null;
    if (message?.status === 429) {
      return json(429, { error: "too_many_requests" });
    }
    return json(503, { error: "unavailable" });
  }

  const foods = parseFoods(content);
  if (foods.length === 0) {
    // The model saw no food — give the scan back.
    if (consumed) await refund(admin, user.id);
    return json(422, { error: "no_food" });
  }

  // remaining_ai_scans() reads auth.uid(), which is empty for the service
  // role, so report the count returned by the consume call instead.
  return json(200, {
    foods,
    remaining: premium ? null : remainingAfter,
  });
});

class ToolkitError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function analyzeImage(imageBase64: string): Promise<string> {
  const secret = Deno.env.get("EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY");
  if (!secret) {
    throw new ToolkitError(500, "toolkit secret not configured");
  }

  const payload = {
    model: "openai/gpt-4o-mini",
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: PROMPT },
          {
            type: "image_url",
            image_url: {
              url: `data:image/jpeg;base64,${imageBase64}`,
            },
          },
        ],
      },
    ],
    max_tokens: 1000,
  };

  const response = await fetch(`${TOOLKIT_URL}/v2/vercel/v1/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${secret}`,
    },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(AI_TIMEOUT_MS),
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => "");
    throw new ToolkitError(
      response.status,
      `toolkit ${response.status}: ${detail.slice(0, 300)}`,
    );
  }

  const chat = await response.json();
  const content = chat?.choices?.[0]?.message?.content;
  if (typeof content !== "string") {
    throw new ToolkitError(502, "toolkit returned no message content");
  }
  return content;
}

interface ScannedFood {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
}

/// Strips code fences / prose and decodes the first JSON array found.
function parseFoods(content: string): ScannedFood[] {
  let text = content.trim();
  if (text.startsWith("```")) {
    text = text
      .replaceAll("```json", "")
      .replaceAll("```", "")
      .trim();
  }
  const start = text.indexOf("[");
  const end = text.lastIndexOf("]");
  if (start === -1 || end <= start) return [];

  let parsed: unknown;
  try {
    parsed = JSON.parse(text.slice(start, end + 1));
  } catch {
    return [];
  }
  if (!Array.isArray(parsed)) return [];

  const foods: ScannedFood[] = [];
  for (const raw of parsed.slice(0, 8)) {
    if (typeof raw !== "object" || raw === null) continue;
    const row = raw as Record<string, unknown>;
    foods.push({
      name: typeof row.name === "string" ? row.name : "Unknown item",
      calories: number(row.calories),
      protein: number(row.protein),
      carbs: number(row.carbs),
      fat: number(row.fat),
    });
  }
  return foods;
}

function number(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "number") return 0;
  if (typeof value === "string") {
    return Number.parseFloat(value.replace(",", ".")) || 0;
  }
  return 0;
}

function isPremium(userID: string): Promise<boolean> {
  const secret = Deno.env.get("REVENUECAT_SECRET_KEY");
  if (!secret) {
    // Without the secret we cannot confirm premium — fail closed but never
    // block free scans: treat everyone as free (the counter still applies).
    console.error("REVENUECAT_SECRET_KEY is not configured");
    return Promise.resolve(false);
  }
  const appUserID = userID.toLowerCase();
  return fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserID)}`,
    {
      headers: { Authorization: `Bearer ${secret}` },
      signal: AbortSignal.timeout(10_000),
    },
  )
    .then(async (response) => {
      if (!response.ok) {
        // 404/401 → no subscriber data; treat as free.
        return false;
      }
      const info = await response.json();
      const entitlements = info?.subscriber?.entitlements;
      if (typeof entitlements !== "object" || entitlements === null) {
        return false;
      }
      return Object.entries(entitlements)
        .filter(([id]) => PREMIUM_ENTITLEMENTS.includes(id))
        .some(([, ent]) => {
          const expires = (ent as { expires_date?: string }).expires_date;
          if (!expires) return true; // lifetime entitlement
          return new Date(expires).getTime() > Date.now();
        });
    })
    .catch((err) => {
      console.error("RevenueCat check failed:", err);
      return false;
    });
}

async function refund(
  admin: ReturnType<typeof createClient>,
  userID: string,
): Promise<void> {
  const { error } = await admin.rpc("refund_ai_scan_for", {
    p_user_id: userID,
  });
  if (error) console.error("refund_ai_scan_for failed:", error);
}

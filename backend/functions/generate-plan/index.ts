// generate-plan: builds a Premium member's training program with AI.
//
// The app sends the member's onboarding answers (goal, schedule, job, sleep,
// stress, other sports, injuries, equipment, FTM-specific safety answers,
// preferences). This function:
//  1. Verifies the Supabase JWT.
//  2. Confirms Premium with RevenueCat (server-side; the app can't fake it).
//  3. Applies a daily cap on plan builds (PLAN_BUILDS_PER_DAY).
//  4. Asks the AI for a program in strict JSON, written to Mason's coaching
//     rules, then validates and cleans every field before returning it.
//  5. Refunds the build if the AI fails, so a failed attempt never counts.
//
// Answers are used only to write the plan. Nothing here stores them.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TOOLKIT_URL = "https://toolkit.rork.com";
const PREMIUM_ENTITLEMENTS = ["premium", "premium_plus", "ftm_pro"];
const PLAN_BUILDS_PER_DAY = 5;
const MAX_BODY_BYTES = 20_000;

// Stronger model first for plan quality, cheaper model as a fallback. Either
// can be swapped with the PLAN_MODEL / PLAN_FALLBACK_MODEL secrets.
const PRIMARY_MODEL = Deno.env.get("PLAN_MODEL") ?? "openai/gpt-4.1";
const FALLBACK_MODEL = Deno.env.get("PLAN_FALLBACK_MODEL") ?? "openai/gpt-4o-mini";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  // 1. Auth
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json(401, { error: "not_signed_in" });
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return json(401, { error: "not_signed_in" });

  // Body
  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) return json(400, { error: "bad_request" });
  let body: Record<string, unknown>;
  try {
    body = JSON.parse(raw);
  } catch {
    return json(400, { error: "bad_request" });
  }
  const answers = readAnswers(body);
  if (!answers) return json(400, { error: "bad_request" });

  // 2. Premium
  if (!(await isPremium(user.id))) return json(403, { error: "not_premium" });

  // 3. Daily cap
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  let consumed = false;
  const { data: left, error: capError } = await admin.rpc("consume_ai_daily", {
    p_user_id: user.id,
    p_kind: "plan",
    p_limit: PLAN_BUILDS_PER_DAY,
  });
  if (capError) {
    console.error("consume_ai_daily failed:", capError);
  } else if (left === -1) {
    return json(429, { error: "daily_limit", limit: PLAN_BUILDS_PER_DAY });
  } else {
    consumed = true;
  }

  // 4. AI
  const prompt = buildPrompt(answers);
  let plan: Plan | null = null;
  let lastStatus = 503;
  for (const [model, timeout] of [[PRIMARY_MODEL, 75_000], [FALLBACK_MODEL, 45_000]] as const) {
    try {
      const content = await chat(model, prompt, timeout);
      plan = cleanPlan(content, answers.daysPerWeek);
      if (plan) break;
      console.error(`${model} returned an unusable plan`);
    } catch (err) {
      console.error(`${model} failed:`, err);
      if (err instanceof ToolkitError) lastStatus = err.status;
    }
  }

  if (!plan) {
    if (consumed) {
      const { error } = await admin.rpc("refund_ai_daily", { p_user_id: user.id, p_kind: "plan" });
      if (error) console.error("refund_ai_daily failed:", error);
    }
    return json(lastStatus === 429 ? 429 : 503, {
      error: lastStatus === 429 ? "too_many_requests" : "unavailable",
    });
  }

  return json(200, plan);
});

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

interface Answers {
  goal: string;
  experience: string;
  trainingHistory: string;
  daysPerWeek: number;
  weekdays: string[];
  sessionMinutes: number;
  timeOfDay: string;
  lifestyle: string;
  workSchedule: string;
  otherActivities: string[];
  otherActivitiesNote: string;
  sleep: string;
  stress: string;
  equipment: string;
  equipmentItems: string[];
  focusAreas: string[];
  successLooksLike: string;
  injuries: string[];
  injuryNotes: string;
  binding: string;
  topSurgery: string;
  testosterone: string;
  style: string;
  cardio: string;
  gymComfort: string;
  likes: string;
  dislikes: string;
  age: number | null;
  heightCm: number | null;
  bodyweightKg: number | null;
}

function str(v: unknown, max = 60): string {
  return typeof v === "string" ? v.replace(/[\u0000-\u001f]/g, " ").trim().slice(0, max) : "";
}

function list(v: unknown, maxItems = 12, max = 40): string[] {
  return Array.isArray(v) ? v.map((x) => str(x, max)).filter(Boolean).slice(0, maxItems) : [];
}

function num(v: unknown, lo: number, hi: number): number | null {
  return typeof v === "number" && Number.isFinite(v) && v >= lo && v <= hi ? v : null;
}

function readAnswers(body: Record<string, unknown>): Answers | null {
  const a = (body.answers ?? {}) as Record<string, unknown>;
  const weekdayNumbers = Array.isArray(a.weekdays)
    ? (a.weekdays as unknown[]).filter((d): d is number =>
      typeof d === "number" && Number.isInteger(d) && d >= 1 && d <= 7
    )
    : [];
  const days = [...new Set(weekdayNumbers)];
  if (days.length < 2 || days.length > 6) return null;
  const goal = str(a.goal);
  const experience = str(a.experience);
  if (!goal || !experience) return null;

  return {
    goal,
    experience,
    trainingHistory: str(a.trainingHistory),
    daysPerWeek: days.length,
    weekdays: days.map((d) => WEEKDAYS[d - 1]),
    sessionMinutes: num(a.sessionMinutes, 20, 120) ?? 60,
    timeOfDay: str(a.timeOfDay),
    lifestyle: str(a.lifestyle),
    workSchedule: str(a.workSchedule),
    otherActivities: list(a.otherActivities),
    otherActivitiesNote: str(a.otherActivitiesNote, 200),
    sleep: str(a.sleep),
    stress: str(a.stress),
    equipment: str(a.equipment),
    equipmentItems: list(a.equipmentItems, 15),
    focusAreas: list(a.focusAreas),
    successLooksLike: str(a.successLooksLike, 300),
    injuries: list(a.injuries),
    injuryNotes: str(a.injuryNotes, 300),
    binding: str(a.binding),
    topSurgery: str(a.topSurgery),
    testosterone: str(a.testosterone),
    style: str(a.style),
    cardio: str(a.cardio),
    gymComfort: str(a.gymComfort),
    likes: str(a.likes, 200),
    dislikes: str(a.dislikes, 200),
    age: num(a.age, 13, 100),
    heightCm: num(a.heightCm, 100, 250),
    bodyweightKg: num(a.bodyweightKg, 30, 300),
  };
}

// ---------------------------------------------------------------------------
// Prompt
// ---------------------------------------------------------------------------

const SYSTEM = `You are Mason, a strength coach who writes training programs for trans masculine people in the FTM: Fitness & Nutrition app. Your philosophy:
- X-frame development: broader shoulders and lats, strong legs, a tighter-looking waist. Side and rear delts, lats and upper back get real volume.
- Safety first: quality over ego. Most working sets stop 1-2 reps short of failure. Beginners earn barbells after mastering machines and dumbbells.
- Wellbeing over numbers: poor sleep or high stress means less volume, not more.
- Progressive overload done simply: add a rep, then add weight.

Hard rules:
1. Write exactly the requested number of training days, one per listed weekday, in order.
2. Every session must fit the stated session length. Count roughly 2.5 minutes per working set including rest, plus 5 minutes of warm-up. Use 3 to 8 exercises per day.
3. Only use equipment the person has. Never program a barbell, rack, cable or machine they don't have.
4. Injuries or pain: avoid movements that load the painful area, choose pain-free alternatives, and say so in the exercise cue.
5. Top surgery: if recovering, NO pressing, overhead work, pull-ups, rows or loaded upper-body pulling; program lower body and core that doesn't load the chest, and add a note that upper-body work returns only after the surgeon clears it. If healed, reintroduce pressing gradually with lighter loads and controlled range.
6. Binding: never recommend training in a binder. If they bind, keep conditioning moderate and add a note about using a compression sports top instead and stopping if breathing feels restricted.
7. Testosterone: never give hormone, dose, medication or supplement advice. If they're early on testosterone, note that strength may climb quickly and connective tissue needs time, so progress steadily.
8. Shift work, nights, a physical job or poor sleep: lower total volume and put the hardest session on the best-rested day if one is obvious.
9. Respect their preferences: include exercises they like when sensible, avoid ones they dislike, and if they prefer a quieter setup, favor exercises that need one station (dumbbells, a bench, one machine) over busy barbell areas.
10. Their goal and focus areas decide where extra volume goes. Fat loss gets a short conditioning finisher only if cardio fits their preference and session length.
11. Use common gym exercise names. Reps are a range like "8-12" or a time like "30-45 sec". Rest is in seconds.
12. Never give medical advice. Notes are short, warm, plain language, no em dashes.

Respond with ONLY a JSON object in this exact shape:
{"name":"short plan name","summary":"2-3 sentences on why this plan fits them","days":[{"title":"Day 1 — Upper (Width)","focus":"Delts / Lats / Arms","exercises":[{"name":"Lat Pulldown","muscleGroup":"Back","sets":3,"reps":"8-12","restSeconds":90,"cue":"one short coaching cue, plus any safety note for them"}]}],"notes":["3 to 6 short notes: how to progress, how to adjust on a rough week, and any safety notes from their answers"]}`;

function line(label: string, value: string | string[] | number | null): string {
  if (value === null || value === "" || (Array.isArray(value) && value.length === 0)) return "";
  return `- ${label}: ${Array.isArray(value) ? value.join(", ") : value}\n`;
}

function buildPrompt(a: Answers): string {
  return "Build a training program for this person.\n" +
    line("Main goal", a.goal) +
    line("Focus areas", a.focusAreas) +
    line("Success in 12 weeks looks like", a.successLooksLike) +
    line("Experience level", a.experience) +
    line("Training history", a.trainingHistory) +
    line("Training days per week", a.daysPerWeek) +
    line("Training weekdays", a.weekdays) +
    line("Session length (minutes)", a.sessionMinutes) +
    line("Usually trains", a.timeOfDay) +
    line("Day-to-day activity", a.lifestyle) +
    line("Work schedule", a.workSchedule) +
    line("Other activities", a.otherActivities) +
    line("Other activities detail", a.otherActivitiesNote) +
    line("Sleep", a.sleep) +
    line("Stress", a.stress) +
    line("Equipment access", a.equipment) +
    line("Equipment available", a.equipmentItems) +
    line("Injuries or pain", a.injuries) +
    line("Injury detail", a.injuryNotes) +
    line("Chest binding", a.binding) +
    line("Top surgery", a.topSurgery) +
    line("Testosterone", a.testosterone) +
    line("Training style preference", a.style) +
    line("Cardio preference", a.cardio) +
    line("Gym setup preference", a.gymComfort) +
    line("Exercises they like", a.likes) +
    line("Exercises they dislike", a.dislikes) +
    line("Age", a.age) +
    line("Height (cm)", a.heightCm) +
    line("Bodyweight (kg)", a.bodyweightKg) +
    `\nWrite exactly ${a.daysPerWeek} days, titled "Day 1 — ..." through "Day ${a.daysPerWeek} — ...".`;
}

// ---------------------------------------------------------------------------
// AI call
// ---------------------------------------------------------------------------

class ToolkitError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function chat(model: string, prompt: string, timeoutMs: number): Promise<string> {
  const secret = Deno.env.get("RORK_TOOLKIT_SECRET_KEY") ??
    Deno.env.get("EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY");
  if (!secret) throw new ToolkitError(500, "toolkit secret not configured");

  const response = await fetch(`${TOOLKIT_URL}/v2/vercel/v1/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${secret}` },
    body: JSON.stringify({
      model,
      messages: [
        { role: "system", content: SYSTEM },
        { role: "user", content: prompt },
      ],
      response_format: { type: "json_object" },
      temperature: 0.4,
      max_tokens: 4000,
    }),
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (!response.ok) {
    const detail = await response.text().catch(() => "");
    throw new ToolkitError(response.status, `toolkit ${response.status}: ${detail.slice(0, 300)}`);
  }
  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== "string") throw new ToolkitError(502, "no message content");
  return content;
}

// ---------------------------------------------------------------------------
// Output validation
// ---------------------------------------------------------------------------

interface PlanExercise {
  name: string;
  muscleGroup: string;
  sets: number;
  reps: string;
  restSeconds: number;
  cue: string;
}
interface PlanDay {
  title: string;
  focus: string;
  exercises: PlanExercise[];
}
interface Plan {
  name: string;
  summary: string;
  days: PlanDay[];
  notes: string[];
}

function clampInt(v: unknown, lo: number, hi: number, fallback: number): number {
  const n = typeof v === "number" ? v : Number.parseInt(String(v ?? ""), 10);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(hi, Math.max(lo, Math.round(n)));
}

function text(v: unknown, max: number): string {
  return typeof v === "string" ? v.replaceAll("— ", "").replace(/\s+/g, " ").trim().slice(0, max) : "";
}

function cleanPlan(content: string, daysPerWeek: number): Plan | null {
  let parsed: unknown;
  try {
    const start = content.indexOf("{");
    const end = content.lastIndexOf("}");
    if (start === -1 || end <= start) return null;
    parsed = JSON.parse(content.slice(start, end + 1));
  } catch {
    return null;
  }
  if (typeof parsed !== "object" || parsed === null) return null;
  const p = parsed as Record<string, unknown>;
  if (!Array.isArray(p.days)) return null;

  const days: PlanDay[] = [];
  for (const [i, rawDay] of (p.days as unknown[]).slice(0, daysPerWeek).entries()) {
    if (typeof rawDay !== "object" || rawDay === null) return null;
    const d = rawDay as Record<string, unknown>;
    const exercises: PlanExercise[] = [];
    for (const rawEx of Array.isArray(d.exercises) ? (d.exercises as unknown[]).slice(0, 9) : []) {
      if (typeof rawEx !== "object" || rawEx === null) continue;
      const e = rawEx as Record<string, unknown>;
      const name = text(e.name, 60);
      if (!name) continue;
      exercises.push({
        name,
        muscleGroup: text(e.muscleGroup, 30) || "Full body",
        sets: clampInt(e.sets, 1, 6, 3),
        reps: text(e.reps, 20) || "8-12",
        restSeconds: clampInt(e.restSeconds, 20, 300, 90),
        cue: text(e.cue, 300),
      });
    }
    if (exercises.length < 2) return null;
    // Titles keep the app's "Day N — Name" format even if the model drifts.
    const rawTitle = typeof d.title === "string" ? d.title.trim() : "";
    const label = rawTitle.replace(/^day\s*\d+\s*[—:-]*\s*/i, "").slice(0, 40) || "Training";
    days.push({
      title: `Day ${i + 1} — ${label}`,
      focus: text(d.focus, 60) || label,
      exercises,
    });
  }
  if (days.length !== daysPerWeek) return null;

  const notes = Array.isArray(p.notes)
    ? (p.notes as unknown[]).map((n) => text(n, 300)).filter(Boolean).slice(0, 6)
    : [];

  return {
    name: text(p.name, 50) || "Your AI Plan",
    summary: text(p.summary, 500),
    days,
    notes,
  };
}

// ---------------------------------------------------------------------------
// Premium check (same logic as scan-meal)
// ---------------------------------------------------------------------------

async function isPremium(userID: string): Promise<boolean> {
  const secret = Deno.env.get("REVENUECAT_SECRET_KEY");
  if (!secret) {
    console.error("REVENUECAT_SECRET_KEY is not configured");
    return false;
  }
  try {
    const response = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userID.toLowerCase())}`,
      { headers: { Authorization: `Bearer ${secret}` }, signal: AbortSignal.timeout(10_000) },
    );
    if (!response.ok) return false;
    const info = await response.json();
    const entitlements = info?.subscriber?.entitlements;
    if (typeof entitlements !== "object" || entitlements === null) return false;
    return Object.entries(entitlements)
      .filter(([id]) => PREMIUM_ENTITLEMENTS.includes(id))
      .some(([, ent]) => {
        const expires = (ent as { expires_date?: string }).expires_date;
        return !expires || new Date(expires).getTime() > Date.now();
      });
  } catch (err) {
    console.error("RevenueCat check failed:", err);
    return false;
  }
}

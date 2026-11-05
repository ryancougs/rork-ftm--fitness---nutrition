-- Daily AI limits for Premium + in-app feedback (replaces the support email).
--
-- 1. ai_daily_usage: per-user, per-day counters for AI features, so one
--    Premium account can't run up the AI bill.
--      kind 'scan'  -> AI meal scans (Premium cap set in scan-meal)
--      kind 'plan'  -> AI training plan builds (cap set in generate-plan)
--    Only the edge functions (service_role) can change the counters.
--
-- 2. support_messages: "Help & feedback" form in the app. Signed-in users
--    can send; nobody can read them from the app. Read them in the Supabase
--    dashboard (Table editor > support_messages).
--
-- Safe to re-run.

-- ---------------------------------------------------------------------------
-- 1. Daily AI usage
-- ---------------------------------------------------------------------------

create table if not exists public.ai_daily_usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  kind text not null check (kind in ('scan', 'plan')),
  count integer not null default 0,
  primary key (user_id, day, kind)
);

alter table public.ai_daily_usage enable row level security;

drop policy if exists "Users read own daily AI usage" on public.ai_daily_usage;
create policy "Users read own daily AI usage" on public.ai_daily_usage
  for select to authenticated using (user_id = auth.uid());

revoke all on public.ai_daily_usage from anon;

-- Consume one use. Returns uses left today after this one, or -1 when the
-- limit is already used (the denied attempt doesn't inflate the counter).
create or replace function public.consume_ai_daily(p_user_id uuid, p_kind text, p_limit integer)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  today date := (now() at time zone 'utc')::date;
  used integer;
begin
  insert into public.ai_daily_usage (user_id, day, kind, count)
  values (p_user_id, today, p_kind, 1)
  on conflict (user_id, day, kind)
  do update set count = public.ai_daily_usage.count + 1
  returning count into used;

  if used > p_limit then
    update public.ai_daily_usage
    set count = p_limit
    where user_id = p_user_id and day = today and kind = p_kind;
    return -1;
  end if;

  return p_limit - used;
end;
$$;

-- Give one use back when the AI call fails.
create or replace function public.refund_ai_daily(p_user_id uuid, p_kind text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.ai_daily_usage
  set count = greatest(0, count - 1)
  where user_id = p_user_id
    and day = (now() at time zone 'utc')::date
    and kind = p_kind;
end;
$$;

-- Edge functions only. Revoke from PUBLIC too (see 20261105 migration).
revoke execute on function public.consume_ai_daily(uuid, text, integer) from public, anon, authenticated;
revoke execute on function public.refund_ai_daily(uuid, text) from public, anon, authenticated;
grant execute on function public.consume_ai_daily(uuid, text, integer) to service_role;
grant execute on function public.refund_ai_daily(uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- 2. In-app feedback
-- ---------------------------------------------------------------------------

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  topic text not null default 'Other',
  message text not null,
  reply_email text,
  app_version text,
  created_at timestamptz not null default now()
);

alter table public.support_messages enable row level security;

drop policy if exists "Feedback: send as yourself" on public.support_messages;
create policy "Feedback: send as yourself" on public.support_messages
  for insert to authenticated with check (
    user_id = auth.uid()
    and char_length(btrim(message)) between 1 and 2000
    and char_length(topic) between 1 and 60
    and coalesce(char_length(reply_email), 0) <= 200
    and coalesce(char_length(app_version), 0) <= 40
  );

revoke all on public.support_messages from anon;

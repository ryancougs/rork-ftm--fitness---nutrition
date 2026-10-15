-- Harden ai_scan_usage for the server-side scan-meal edge function.
--
-- Clients no longer consume scans themselves: the edge function consumes
-- (and refunds) server-side as the service role, so write access moves off
-- the client entirely. Read-only RLS stays so the app can display the
-- user's own usage.

drop policy if exists "Users manage own scan usage" on public.ai_scan_usage;
create policy "Users read own scan usage"
  on public.ai_scan_usage
  for select
  using (auth.uid() = user_id);

-- Consume one scan atomically for an explicit user id (the edge function
-- runs as service_role, so there is no JWT user context for auth.uid()).
-- Returns scans remaining (0..3) after the consume, or -1 when the weekly
-- limit is already used. Denied attempts do not inflate the counter.
create or replace function public.consume_ai_scan_for(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  ws date := public.current_week_start();
  used integer;
begin
  insert into public.ai_scan_usage (user_id, week_start, scan_count)
  values (p_user_id, ws, 1)
  on conflict (user_id, week_start)
  do update set scan_count = public.ai_scan_usage.scan_count + 1
  returning scan_count into used;

  if used > 3 then
    update public.ai_scan_usage
    set scan_count = 3
    where user_id = p_user_id and week_start = ws;
    return -1;
  end if;

  return 3 - used;
end;
$$;

-- Refund a consumed scan when the AI call fails or finds no food.
-- Returns scans remaining after the refund.
create or replace function public.refund_ai_scan_for(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  ws date := public.current_week_start();
  used integer;
begin
  update public.ai_scan_usage
  set scan_count = greatest(0, scan_count - 1)
  where user_id = p_user_id and week_start = ws
  returning scan_count into used;

  return greatest(0, 3 - coalesce(used, 0));
end;
$$;

-- Edge-function-only: no client, authenticated or not, may call these.
revoke execute on function public.consume_ai_scan_for(uuid) from anon, authenticated;
revoke execute on function public.refund_ai_scan_for(uuid) from anon, authenticated;

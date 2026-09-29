-- AI meal scan usage: free tier gets 3 scans per user per week (Monday-based,
-- matching the app's check-in weeks). Tracked server-side so reinstalling the
-- app doesn't reset the allowance.

create table if not exists public.ai_scan_usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  week_start date not null,
  scan_count integer not null default 0,
  primary key (user_id, week_start)
);

alter table public.ai_scan_usage enable row level security;

drop policy if exists "Users manage own scan usage" on public.ai_scan_usage;
create policy "Users manage own scan usage"
  on public.ai_scan_usage
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.current_week_start()
returns date
language sql
stable
as $$
  select (date_trunc('week', now()))::date;
$$;

-- Consumes one scan atomically. Returns scans remaining (0..3) after the
-- consume, -1 when the weekly limit is already used, or -2 when there is no
-- authenticated session.
create or replace function public.consume_ai_scan()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  ws date := public.current_week_start();
  used integer;
begin
  if uid is null then
    return -2;
  end if;

  insert into public.ai_scan_usage (user_id, week_start, scan_count)
  values (uid, ws, 1)
  on conflict (user_id, week_start)
  do update set scan_count = public.ai_scan_usage.scan_count + 1
  returning scan_count into used;

  if used > 3 then
    return -1;
  end if;

  return 3 - used;
end;
$$;

create or replace function public.remaining_ai_scans()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select greatest(0, 3 - coalesce((
    select scan_count
    from public.ai_scan_usage
    where user_id = auth.uid()
      and week_start = public.current_week_start()
  ), 0));
$$;

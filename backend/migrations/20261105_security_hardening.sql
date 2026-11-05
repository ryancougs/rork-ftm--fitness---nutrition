-- Security hardening before App Store launch (Nov 5, 2026).
--
-- 1. FREE SCAN BYPASS (critical). The Oct 1 migration revoked
--    consume_ai_scan_for / refund_ai_scan_for from anon and authenticated,
--    but Postgres also grants EXECUTE on every new function to PUBLIC, and
--    anon/authenticated inherit from PUBLIC. So any signed-in user could
--    still call them through the API with the anon key from the app:
--      - refund_ai_scan_for(own id) over and over = unlimited free AI scans
--        (each one costs real money on the AI proxy)
--      - consume_ai_scan_for(someone else's id) = burn another user's scans
--    Fix: revoke from PUBLIC too and grant only to service_role (the
--    scan-meal edge function).
--
-- 2. RLS BASELINE. Only the scan tables' policies lived in this repo, so the
--    rest were never reviewed. This resets every app table to a known,
--    owner-only policy set. Service role (edge functions, dashboard) bypasses
--    RLS and is unaffected.
--
-- 3. COMMUNITY GUARDS. Server-side length limits, and nobody can post under
--    a display name that looks like the coach or the app team.
--
-- Safe to re-run.

-- ---------------------------------------------------------------------------
-- 1. Scan functions: edge-function only
-- ---------------------------------------------------------------------------

revoke execute on function public.consume_ai_scan_for(uuid) from public, anon, authenticated;
revoke execute on function public.refund_ai_scan_for(uuid) from public, anon, authenticated;
grant execute on function public.consume_ai_scan_for(uuid) to service_role;
grant execute on function public.refund_ai_scan_for(uuid) to service_role;

-- The old client-side consume function is unused since scans moved to the
-- edge function. Nobody should be able to call it.
revoke execute on function public.consume_ai_scan() from public, anon, authenticated;

-- remaining_ai_scans() only reads the caller's own row; signed-in users keep it.
revoke execute on function public.remaining_ai_scans() from public, anon;
grant execute on function public.remaining_ai_scans() to authenticated;

-- ---------------------------------------------------------------------------
-- 2. RLS baseline: drop whatever policies exist, then recreate known ones
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
  p record;
begin
  foreach t in array array[
    'profiles', 'check_ins', 'food_logs', 'workout_logs',
    'community_posts', 'community_reports', 'ai_scan_usage'
  ] loop
    if to_regclass('public.' || t) is not null then
      execute format('alter table public.%I enable row level security', t);
      for p in
        select policyname from pg_policies
        where schemaname = 'public' and tablename = t
      loop
        execute format('drop policy %I on public.%I', p.policyname, t);
      end loop;
    end if;
  end loop;
end $$;

-- Profiles: only your own row.
create policy "Own profile: read" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "Own profile: create" on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy "Own profile: update" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "Own profile: delete" on public.profiles
  for delete to authenticated using (id = auth.uid());

-- Check-ins, food logs, workout logs: only your own rows.
create policy "Own check-ins" on public.check_ins
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Own food logs" on public.food_logs
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Own workout logs" on public.workout_logs
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Scan usage: read your own count only. Writes happen in the edge function.
create policy "Users read own scan usage" on public.ai_scan_usage
  for select to authenticated using (user_id = auth.uid());

-- Community posts: signed-in users read everything; you can only create and
-- delete your own; nobody edits (no update policy). Reserved names blocked.
create policy "Community: signed-in users read" on public.community_posts
  for select to authenticated using (true);
create policy "Community: post as yourself" on public.community_posts
  for insert to authenticated with check (
    user_id = auth.uid()
    and char_length(btrim(body)) between 1 and 500
    and char_length(btrim(display_name)) between 1 and 40
    and lower(regexp_replace(display_name, '[^a-zA-Z]', '', 'g'))
      !~ '(mason|coach|admin|moderator|ftmteam|ftmfitness|support|official|transfit)'
  );
create policy "Community: delete own posts" on public.community_posts
  for delete to authenticated using (user_id = auth.uid());

-- Reports: you can file a report as yourself. Nobody can read reports from
-- the app (keeps reporters anonymous); moderators use the dashboard.
create policy "Reports: file as yourself" on public.community_reports
  for insert to authenticated with check (
    reporter_id = auth.uid()
    and char_length(reason) between 1 and 200
  );

-- Anonymous (signed-out) callers get nothing from any app table.
revoke all on public.profiles, public.check_ins, public.food_logs,
  public.workout_logs, public.community_posts, public.community_reports,
  public.ai_scan_usage
  from anon;

-- ---------------------------------------------------------------------------
-- 4. Deleting a post (or a whole account) must not be blocked by reports
--    that point at it. Without cascade, "Delete account" fails for anyone
--    whose post was ever reported, which is an App Review requirement.
-- ---------------------------------------------------------------------------

alter table public.community_reports
  drop constraint if exists community_reports_post_id_fkey,
  add constraint community_reports_post_id_fkey
    foreign key (post_id) references public.community_posts (id) on delete cascade;

alter table public.community_reports
  drop constraint if exists community_reports_reporter_id_fkey,
  add constraint community_reports_reporter_id_fkey
    foreign key (reporter_id) references public.profiles (id) on delete cascade;

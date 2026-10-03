-- ============================================================
-- Revisit tracking (server-authoritative)
--
-- The client has long called `register_revisit` and read
-- visit_count / last_visited_at / revisit_history from
-- user_achievements, but none of it was defined in migrations.
-- This migration makes it reproducible and closes the gaps:
--   * revisit columns exist (no-op where prod already has them;
--     prod's hand-made jsonb revisit_history becomes timestamptz[]).
--   * Clients can no longer write the revisit columns directly
--     (column-level grants) — only these RPCs change them.
--   * register_revisit enforces the cooldown server-side and accepts
--     an optional visited_at so background-detected revisits keep
--     their real timestamp instead of the app-resume time.
--   * add_retroactive_revisit / edit_revisit_entry sync the diary
--     edits that used to be local-only and were lost on reinstall.
--
-- Cooldowns mirror AchievementsNotifier.cooldownFor — change both
-- together.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. COLUMNS
-- ────────────────────────────────────────────────────────────
alter table public.user_achievements
  add column if not exists visit_count     integer not null default 1,
  add column if not exists last_visited_at timestamptz;

-- Prod's hand-made visit_count may be nullable / lack the default.
update public.user_achievements set visit_count = 1 where visit_count is null;
alter table public.user_achievements
  alter column visit_count set default 1,
  alter column visit_count set not null;

-- revisit_history: prod created it by hand as jsonb (an array of ISO
-- strings). Convert it to timestamptz[] in place, keeping every parseable
-- entry. PostgREST serializes both as a JSON array of timestamp strings,
-- so already-installed app builds read it unchanged.
do $$
declare
  v_type text;
  v_row  record;
  v_txt  text;
  v_arr  timestamptz[];
begin
  select format_type(atttypid, atttypmod) into v_type
  from pg_attribute
  where attrelid = 'public.user_achievements'::regclass
    and attname = 'revisit_history' and not attisdropped;

  if v_type is null then
    alter table public.user_achievements
      add column revisit_history timestamptz[] not null default '{}';

  elsif v_type = 'jsonb' then
    alter table public.user_achievements
      add column revisit_history_ts timestamptz[] not null default '{}';

    for v_row in
      select id, revisit_history from public.user_achievements
    loop
      v_arr := '{}';
      if jsonb_typeof(v_row.revisit_history) = 'array' then
        for v_txt in
          select jsonb_array_elements_text(v_row.revisit_history)
        loop
          begin
            v_arr := array_append(v_arr, v_txt::timestamptz);
          exception when others then
            null;  -- skip a malformed entry rather than abort the migration
          end;
        end loop;
      end if;

      update public.user_achievements
      set revisit_history_ts = (select coalesce(array_agg(t order by t), '{}')
                                from unnest(v_arr) t)
      where id = v_row.id;
    end loop;

    alter table public.user_achievements drop column revisit_history;
    alter table public.user_achievements
      rename column revisit_history_ts to revisit_history;

  elsif v_type <> 'timestamp with time zone[]' then
    raise exception 'user_achievements.revisit_history is %, expected jsonb or timestamptz[]', v_type;
  end if;
end $$;

-- ────────────────────────────────────────────────────────────
-- 2. LOCK DOWN REVISIT COLUMNS
-- Clients keep inserting/upserting unlock rows, but visit_count,
-- last_visited_at and revisit_history are RPC-only. user_id and
-- achievement_id are granted because PostgREST upserts list every
-- payload column in ON CONFLICT DO UPDATE SET (RLS still pins the
-- row to auth.uid()).
-- ────────────────────────────────────────────────────────────
revoke insert, update on public.user_achievements from anon, authenticated;

grant insert (user_id, achievement_id, unlocked_at, visit_date, notes,
              is_retroactive, photos)
  on public.user_achievements to authenticated;

grant update (user_id, achievement_id, unlocked_at, visit_date, notes,
              is_retroactive, photos)
  on public.user_achievements to authenticated;

-- ────────────────────────────────────────────────────────────
-- 3. HELPERS
-- ────────────────────────────────────────────────────────────
create or replace function public.revisit_cooldown(p_achievement_id text)
returns interval
language sql
stable
set search_path = public
as $$
  select case
    when (select collection_id
          from public.achievement_definitions
          where id = p_achievement_id)
         in ('continents', 'europe', 'americas', 'africa',
             'asia', 'south-america', 'oceania', 'capitals')
      then interval '7 days'
    else interval '1 hour'
  end;
$$;

create or replace function public.revisit_state(
  p_row public.user_achievements, p_accepted boolean)
returns json
language sql
immutable
as $$
  select json_build_object(
    'accepted',        p_accepted,
    'visit_count',     p_row.visit_count,
    'last_visited_at', p_row.last_visited_at,
    'revisit_history', p_row.revisit_history);
$$;

-- ────────────────────────────────────────────────────────────
-- 4. register_revisit — GPS-detected revisit, cooldown enforced
-- ────────────────────────────────────────────────────────────
drop function if exists public.register_revisit(text);

create or replace function public.register_revisit(
  ach_id text, visited_at timestamptz default null)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row  public.user_achievements;
  v_at   timestamptz := coalesce(visited_at, now());
begin
  if v_user is null then
    return json_build_object('accepted', false);
  end if;

  select * into v_row
  from public.user_achievements
  where user_id = v_user and achievement_id = ach_id
  for update;

  if not found then
    return json_build_object('accepted', false);
  end if;

  -- Background-detected revisits may arrive late (app resumed hours or
  -- days after), but never from the future or from long ago.
  if v_at > now() + interval '5 minutes'
     or v_at < now() - interval '30 days'
     or v_at < coalesce(v_row.last_visited_at, v_row.unlocked_at)
               + public.revisit_cooldown(ach_id) then
    return public.revisit_state(v_row, false);
  end if;

  update public.user_achievements
  set visit_count     = visit_count + 1,
      last_visited_at = v_at,
      revisit_history = array_append(revisit_history, v_at)
  where id = v_row.id
  returning * into v_row;

  return public.revisit_state(v_row, true);
end;
$$;

-- ────────────────────────────────────────────────────────────
-- 5. add_retroactive_revisit — user logs a past visit by hand.
-- No cooldown and last_visited_at is untouched, so it can't block or
-- unlock GPS revisits. Revisits award no XP.
-- ────────────────────────────────────────────────────────────
create or replace function public.add_retroactive_revisit(
  ach_id text, visited_at timestamptz)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row  public.user_achievements;
begin
  if v_user is null or visited_at is null then
    return json_build_object('accepted', false);
  end if;

  select * into v_row
  from public.user_achievements
  where user_id = v_user and achievement_id = ach_id
  for update;

  if not found then
    return json_build_object('accepted', false);
  end if;

  if visited_at > now() + interval '5 minutes'
     or visited_at = any(v_row.revisit_history) then
    return public.revisit_state(v_row, false);
  end if;

  update public.user_achievements
  set visit_count     = visit_count + 1,
      revisit_history = (select array_agg(t order by t)
                         from unnest(array_append(revisit_history, visited_at)) t)
  where id = v_row.id
  returning * into v_row;

  return public.revisit_state(v_row, true);
end;
$$;

-- ────────────────────────────────────────────────────────────
-- 6. edit_revisit_entry — change the date of one diary entry.
-- ────────────────────────────────────────────────────────────
create or replace function public.edit_revisit_entry(
  ach_id text, old_at timestamptz, new_at timestamptz)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row     public.user_achievements;
  v_history timestamptz[];
  v_idx     integer;
begin
  if v_user is null or old_at is null or new_at is null then
    return json_build_object('accepted', false);
  end if;

  select * into v_row
  from public.user_achievements
  where user_id = v_user and achievement_id = ach_id
  for update;

  if not found then
    return json_build_object('accepted', false);
  end if;

  v_idx := array_position(v_row.revisit_history, old_at);
  if v_idx is null or new_at > now() + interval '5 minutes' then
    return public.revisit_state(v_row, false);
  end if;

  v_history := v_row.revisit_history;
  v_history[v_idx] := new_at;

  update public.user_achievements
  set revisit_history = (select array_agg(t order by t)
                         from unnest(v_history) t)
  where id = v_row.id
  returning * into v_row;

  return public.revisit_state(v_row, true);
end;
$$;

-- ────────────────────────────────────────────────────────────
-- 7. EXECUTE GRANTS — signed-in users only
-- ────────────────────────────────────────────────────────────
revoke execute on function public.revisit_cooldown(text) from public, anon, authenticated;
revoke execute on function public.revisit_state(public.user_achievements, boolean)
  from public, anon, authenticated;

revoke execute on function public.register_revisit(text, timestamptz) from public, anon;
revoke execute on function public.add_retroactive_revisit(text, timestamptz) from public, anon;
revoke execute on function public.edit_revisit_entry(text, timestamptz, timestamptz) from public, anon;

grant execute on function public.register_revisit(text, timestamptz) to authenticated;
grant execute on function public.add_retroactive_revisit(text, timestamptz) to authenticated;
grant execute on function public.edit_revisit_entry(text, timestamptz, timestamptz) to authenticated;

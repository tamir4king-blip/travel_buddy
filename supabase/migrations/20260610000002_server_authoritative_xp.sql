-- ============================================================
-- Server-authoritative XP
--
-- Before this migration, clients computed total_xp locally and wrote it
-- straight to profiles — any modded client could top the leaderboard.
-- After it:
--   * profiles.total_xp / level / is_premium are no longer writable by
--     clients (column-level grants).
--   * XP is awarded by AFTER INSERT/UPDATE triggers on the rows clients
--     already sync (user_achievements, user_quest_completions,
--     user_completed_collections, user_master_achievements), priced from
--     the *_definitions tables seeded in 20260610000001.
--   * Every award is recorded once in xp_ledger; its unique constraint
--     makes awards idempotent (delete + re-insert cannot double-award).
--
-- The XP formulas mirror lib/shared/utils/xp_rules.dart — change both
-- together.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. XP LEDGER  (append-only, one row per award)
-- ────────────────────────────────────────────────────────────
create table public.xp_ledger (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  source     text not null,   -- 'achievement' | 'quest' | 'collection' | 'master'
  source_id  text not null,   -- achievement/quest id; quests append ':<n>' per repeat
  amount     integer not null,
  created_at timestamptz not null default now(),

  unique (user_id, source, source_id)
);

create index idx_xp_ledger_user on public.xp_ledger(user_id);

alter table public.xp_ledger enable row level security;

-- Users may inspect their own XP history; only triggers write rows.
create policy "Users can view their own xp ledger"
  on public.xp_ledger for select
  using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- 2. LEVEL CURVE  (mirror of XpRules.levelForXp)
-- ────────────────────────────────────────────────────────────
create or replace function public.calculate_level(p_total_xp integer)
returns integer
language sql
immutable
as $$
  select case
    when p_total_xp < 100  then 1
    when p_total_xp < 250  then 2
    when p_total_xp < 500  then 3
    when p_total_xp < 850  then 4
    when p_total_xp < 1300 then 5
    when p_total_xp < 1850 then 6
    when p_total_xp < 2500 then 7
    when p_total_xp < 3300 then 8
    when p_total_xp < 4250 then 9
    when p_total_xp < 5400 then 10
    else 10 + ((p_total_xp - 5400) / 1500)
  end;
$$;

-- ────────────────────────────────────────────────────────────
-- 3. AWARD HELPER  (idempotent via the ledger's unique constraint)
-- ────────────────────────────────────────────────────────────
create or replace function public.award_xp_once(
  p_user uuid, p_source text, p_source_id text, p_amount integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_amount is null or p_amount <= 0 then
    return;
  end if;

  insert into public.xp_ledger (user_id, source, source_id, amount)
  values (p_user, p_source, p_source_id, p_amount)
  on conflict (user_id, source, source_id) do nothing;

  -- Conflict means this exact award already happened — never double-award.
  if not found then
    return;
  end if;

  update public.profiles
  set total_xp = total_xp + p_amount,
      level    = public.calculate_level(total_xp + p_amount)
  where id = p_user;
end;
$$;

-- PostgREST exposes public functions as RPC by default; XP awards must only
-- ever come from triggers, so strip client execute rights.
revoke execute on function public.award_xp_once(uuid, text, text, integer)
  from public, anon, authenticated;

-- ────────────────────────────────────────────────────────────
-- 4. TRIGGERS
-- ────────────────────────────────────────────────────────────

-- Achievements: priced from achievement_definitions; retroactive claims
-- award 80% (mirror of XpRules.achievementXp). Unknown ids award nothing.
create or replace function public.award_achievement_xp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_base   integer;
  v_amount integer;
begin
  select xp_reward into v_base
  from public.achievement_definitions
  where id = new.achievement_id and is_active;

  if v_base is null then
    return new;
  end if;

  v_amount := case when coalesce(new.is_retroactive, false)
                   then round(v_base * 0.8)::integer
                   else v_base end;

  perform public.award_xp_once(
    new.user_id, 'achievement', new.achievement_id, v_amount);
  return new;
end;
$$;

create trigger user_achievements_award_xp
  after insert on public.user_achievements
  for each row execute function public.award_achievement_xp();

-- Quests: diminishing returns per repeat (100/75/50/25%, mirror of
-- XpRules.questXp), awarded once per completion number and capped at the
-- definition's max_completions so inflated counts can't farm XP.
create or replace function public.award_quest_xp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_def    record;
  v_old    integer := 0;
  v_new    integer;
  v_n      integer;
  v_amount integer;
begin
  select xp_reward, max_completions into v_def
  from public.quest_definitions
  where id = new.quest_id;

  if not found then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    v_old := coalesce(old.completion_count, 0);
  end if;
  v_new := least(coalesce(new.completion_count, 0),
                 greatest(v_def.max_completions, 1));

  for v_n in (v_old + 1) .. v_new loop
    v_amount := case
      when v_n <= 1 then v_def.xp_reward
      when v_n = 2  then round(v_def.xp_reward * 0.75)::integer
      when v_n = 3  then round(v_def.xp_reward * 0.50)::integer
      else               round(v_def.xp_reward * 0.25)::integer
    end;
    perform public.award_xp_once(
      new.user_id, 'quest', new.quest_id || ':' || v_n, v_amount);
  end loop;
  return new;
end;
$$;

create trigger user_quest_completions_award_xp
  after insert or update on public.user_quest_completions
  for each row execute function public.award_quest_xp();

-- Collections: completion bonus from collection_definitions
-- (default 50, mirror of XpRules.defaultCollectionBonus).
create or replace function public.award_collection_xp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bonus integer;
begin
  select bonus_xp into v_bonus
  from public.collection_definitions
  where id = new.collection_id;

  perform public.award_xp_once(
    new.user_id, 'collection', new.collection_id, coalesce(v_bonus, 50));
  return new;
end;
$$;

create trigger user_completed_collections_award_xp
  after insert on public.user_completed_collections
  for each row execute function public.award_collection_xp();

-- Master achievements: priced from master_achievement_definitions.
create or replace function public.award_master_xp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_xp integer;
begin
  select xp_reward into v_xp
  from public.master_achievement_definitions
  where id = new.master_achievement_id;

  if v_xp is null then
    return new;
  end if;

  perform public.award_xp_once(
    new.user_id, 'master', new.master_achievement_id, v_xp);
  return new;
end;
$$;

create trigger user_master_achievements_award_xp
  after insert on public.user_master_achievements
  for each row execute function public.award_master_xp();

-- ────────────────────────────────────────────────────────────
-- 5. LOCK DOWN profiles COLUMNS
-- Clients keep updating their own cosmetic fields and streak, but
-- total_xp / level / is_premium become server-only. (RLS row policies
-- from the initial schema still apply on top of these grants.)
-- ────────────────────────────────────────────────────────────
revoke insert, update on public.profiles from anon, authenticated;

-- `id` is included because PostgREST upserts list every payload column in
-- the ON CONFLICT DO UPDATE SET clause (the RLS policy still pins the row
-- to auth.uid(), so "updating" id to itself is the only possibility).
grant update (id, display_name, username, bio, avatar_url, is_public,
              current_streak, last_completion_date)
  on public.profiles to authenticated;

-- Profile rows are normally created by the handle_new_user trigger;
-- this matches the existing "for safety" insert policy.
grant insert (id, display_name, username, bio, avatar_url, is_public)
  on public.profiles to authenticated;

-- ────────────────────────────────────────────────────────────
-- 6. BACKFILL  (re-derive every profile's XP from synced rows)
-- Existing client-written totals are replaced by the server-computed
-- value: the sum of ledger entries built from user_achievements,
-- quest completions, collections, and master achievements.
-- ────────────────────────────────────────────────────────────
insert into public.xp_ledger (user_id, source, source_id, amount)
select ua.user_id, 'achievement', ua.achievement_id,
       case when coalesce(ua.is_retroactive, false)
            then round(ad.xp_reward * 0.8)::integer
            else ad.xp_reward end
from public.user_achievements ua
join public.achievement_definitions ad on ad.id = ua.achievement_id
where ad.xp_reward > 0
on conflict (user_id, source, source_id) do nothing;

insert into public.xp_ledger (user_id, source, source_id, amount)
select uq.user_id, 'quest', uq.quest_id || ':' || n.n,
       case
         when n.n <= 1 then qd.xp_reward
         when n.n = 2  then round(qd.xp_reward * 0.75)::integer
         when n.n = 3  then round(qd.xp_reward * 0.50)::integer
         else               round(qd.xp_reward * 0.25)::integer
       end
from public.user_quest_completions uq
join public.quest_definitions qd on qd.id = uq.quest_id
cross join lateral generate_series(
  1, least(coalesce(uq.completion_count, 0),
           greatest(qd.max_completions, 1))) as n(n)
where qd.xp_reward > 0
on conflict (user_id, source, source_id) do nothing;

insert into public.xp_ledger (user_id, source, source_id, amount)
select uc.user_id, 'collection', uc.collection_id, coalesce(cd.bonus_xp, 50)
from public.user_completed_collections uc
left join public.collection_definitions cd on cd.id = uc.collection_id
on conflict (user_id, source, source_id) do nothing;

insert into public.xp_ledger (user_id, source, source_id, amount)
select um.user_id, 'master', um.master_achievement_id, md.xp_reward
from public.user_master_achievements um
join public.master_achievement_definitions md
  on md.id = um.master_achievement_id
where md.xp_reward > 0
on conflict (user_id, source, source_id) do nothing;

update public.profiles p
set total_xp = coalesce(
      (select sum(l.amount) from public.xp_ledger l where l.user_id = p.id),
      0)::integer,
    level = public.calculate_level(coalesce(
      (select sum(l.amount) from public.xp_ledger l where l.user_id = p.id),
      0)::integer);

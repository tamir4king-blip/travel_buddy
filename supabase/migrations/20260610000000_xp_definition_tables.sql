-- ============================================================
-- XP definition tables
--
-- Server-side price list for everything that can award profile XP.
-- These tables are owned by the repo registries (lib/shared/data/*):
-- the seed migration (20260610000001) is GENERATED from them by
-- `dart run tool/generate_xp_seed_migration.dart` — edit the Dart
-- registries and re-run the tool instead of editing seeds by hand.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. ACHIEVEMENT DEFINITIONS (codify the table production already
--    has — created originally via the dashboard and seeded by
--    tool/seed_achievement_definitions.dart). `if not exists`
--    keeps existing production data untouched.
-- ────────────────────────────────────────────────────────────
create table if not exists public.achievement_definitions (
  id            text primary key,
  title         text not null,
  description   text,
  icon_name     text,
  tier          text not null default 'bronze',
  xp_reward     integer not null default 10,
  latitude      double precision,
  longitude     double precision,
  claim_radius  double precision,
  claim_polygon jsonb,
  collection_id text,
  tags          text[] default '{}',
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────
-- 2. QUEST DEFINITIONS (side-quest activities + story chains)
-- ────────────────────────────────────────────────────────────
create table if not exists public.quest_definitions (
  id              text primary key,
  title           text,
  xp_reward       integer not null default 0,
  max_completions integer not null default 1,    -- server-side cap on awarded repeats
  source          text not null default 'activity',  -- 'activity' | 'story'
  created_at      timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────
-- 3. MASTER ACHIEVEMENT DEFINITIONS
-- ────────────────────────────────────────────────────────────
create table if not exists public.master_achievement_definitions (
  id         text primary key,
  title      text,
  xp_reward  integer not null default 0,
  created_at timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────
-- 4. COLLECTION DEFINITIONS (completion bonus XP)
-- ────────────────────────────────────────────────────────────
create table if not exists public.collection_definitions (
  id         text primary key,
  name       text,
  bonus_xp   integer not null default 50,
  created_at timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────
-- RLS: publicly readable, writable only by the service role
-- (no insert/update/delete policies — RLS blocks client writes).
-- Policies are wrapped so re-running against a production DB that
-- already has them is harmless.
-- ────────────────────────────────────────────────────────────
alter table public.achievement_definitions enable row level security;
alter table public.quest_definitions enable row level security;
alter table public.master_achievement_definitions enable row level security;
alter table public.collection_definitions enable row level security;

do $$ begin
  create policy "Achievement definitions are publicly readable"
    on public.achievement_definitions for select using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "Quest definitions are publicly readable"
    on public.quest_definitions for select using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "Master achievement definitions are publicly readable"
    on public.master_achievement_definitions for select using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "Collection definitions are publicly readable"
    on public.collection_definitions for select using (true);
exception when duplicate_object then null; end $$;

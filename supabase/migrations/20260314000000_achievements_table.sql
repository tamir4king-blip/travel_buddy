-- Achievement registry table: rich location metadata fetched on demand
-- Local app registry keeps lightweight data (id, title, lat/lng, tier, claimRadius)
-- This table stores the full detail for each achievement location

create table if not exists public.achievements (
  id              text primary key,
  title           text not null,
  description     text,
  latitude        double precision,
  longitude       double precision,
  claim_radius    integer,
  tier            text not null,
  collection_id   text,
  opening_hours   jsonb,
  cover_photo_url text,
  photo_urls      text[] default '{}',
  website         text,
  phone           text,
  city            text,
  country         text,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- Auto-update updated_at on modification
create or replace function public.update_achievements_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger achievements_updated_at
  before update on public.achievements
  for each row
  execute function public.update_achievements_updated_at();

-- RLS: achievements are publicly readable (no auth needed to browse locations)
alter table public.achievements enable row level security;

create policy "Achievements are publicly readable"
  on public.achievements for select
  using (true);

-- Only service role can insert/update/delete achievements
-- (managed via Supabase dashboard or migration scripts)

-- Storage bucket for achievement photos
insert into storage.buckets (id, name, public, file_size_limit)
values ('achievement-photos', 'achievement-photos', true, 10485760)
on conflict (id) do nothing;

-- Allow public read access to achievement photos
create policy "Achievement photos are publicly readable"
  on storage.objects for select
  using (bucket_id = 'achievement-photos');

-- Index for collection-based queries
create index if not exists idx_achievements_collection_id
  on public.achievements (collection_id);

-- Index for geographic queries
create index if not exists idx_achievements_location
  on public.achievements (latitude, longitude);

-- Add 'volcanoes' collection: extend the achievements table with a
-- polygonal claim area, migrate existing volcanoes from 'mountains',
-- and seed the nine new volcano achievements.

-- 1. Add claim_polygon column (JSONB array of [lat, lng] pairs).
--    Takes priority over claim_radius on the client when present.
alter table public.achievements
  add column if not exists claim_polygon jsonb;

-- 2. Migrate the four already-seeded volcanoes from 'mountains' to
--    'volcanoes'. These rows may not exist in older deployments
--    (mountains were registry-only), so the update is a no-op then.
update public.achievements
  set collection_id = 'volcanoes'
  where id in ('mtn-etna', 'mtn-fuji', 'mtn-st-helens', 'mtn-cotopaxi');

-- 3. Seed the nine new volcano achievements with polygons.
insert into public.achievements
  (id, title, description, latitude, longitude, claim_radius,
   claim_polygon, tier, collection_id, city, country)
values
  ('volcano-vesuvius', 'Mount Vesuvius',
   'Stand on the rim of the volcano that buried Pompeii',
   40.8210, 14.4260, 8000,
   '[[40.78, 14.38], [40.86, 14.38], [40.86, 14.47], [40.78, 14.47]]'::jsonb,
   'platinum', 'volcanoes', 'Naples', 'Italy'),

  ('volcano-kilauea', 'Kīlauea',
   'Witness Hawaii''s most active volcano and its glowing lava lake',
   19.4069, -155.2834, 12000,
   '[[19.34, -155.34], [19.46, -155.34], [19.46, -155.22], [19.34, -155.22]]'::jsonb,
   'gold', 'volcanoes', 'Hawaii County', 'United States'),

  ('volcano-krakatoa', 'Krakatoa / Anak Krakatau',
   'Sail to the child of the volcano whose 1883 eruption shook the world',
   -6.1024, 105.4231, 12000,
   '[[-6.18, 105.34], [-6.02, 105.34], [-6.02, 105.50], [-6.18, 105.50]]'::jsonb,
   'platinum', 'volcanoes', 'Sunda Strait', 'Indonesia'),

  ('volcano-stromboli', 'Stromboli',
   'Watch the Lighthouse of the Mediterranean erupt every few minutes',
   38.7891, 15.2130, 6000,
   '[[38.76, 15.18], [38.82, 15.18], [38.82, 15.24], [38.76, 15.24]]'::jsonb,
   'gold', 'volcanoes', 'Aeolian Islands', 'Italy'),

  ('volcano-eyjafjallajokull', 'Eyjafjallajökull',
   'Trek across the Icelandic glacier-volcano that grounded Europe in 2010',
   63.6314, -19.6083, 12000,
   '[[63.56, -19.72], [63.70, -19.72], [63.70, -19.50], [63.56, -19.50]]'::jsonb,
   'gold', 'volcanoes', 'South Region', 'Iceland'),

  ('volcano-mayon', 'Mount Mayon',
   'Marvel at the world''s most perfect volcanic cone in the Philippines',
   13.2572, 123.6856, 12000,
   '[[13.19, 123.62], [13.32, 123.62], [13.32, 123.75], [13.19, 123.75]]'::jsonb,
   'gold', 'volcanoes', 'Albay', 'Philippines'),

  ('volcano-pinatubo', 'Mount Pinatubo',
   'Hike to the crater lake of the volcano whose 1991 eruption cooled the planet',
   15.1429, 120.3496, 12000,
   '[[15.08, 120.28], [15.21, 120.28], [15.21, 120.42], [15.08, 120.42]]'::jsonb,
   'platinum', 'volcanoes', 'Zambales', 'Philippines'),

  ('volcano-erta-ale', 'Erta Ale',
   'Stand at the edge of the Smoking Mountain''s permanent lava lake in the Danakil',
   13.6017, 40.6700, 10000,
   '[[13.54, 40.60], [13.66, 40.60], [13.66, 40.74], [13.54, 40.74]]'::jsonb,
   'platinum', 'volcanoes', 'Afar Region', 'Ethiopia'),

  ('volcano-villarrica', 'Villarrica',
   'Climb one of South America''s most active volcanoes above the Chilean lakes',
   -39.4194, -71.9389, 12000,
   '[[-39.49, -72.01], [-39.35, -72.01], [-39.35, -71.86], [-39.49, -71.86]]'::jsonb,
   'gold', 'volcanoes', 'Araucanía', 'Chile')

on conflict (id) do update set
  title         = excluded.title,
  description   = excluded.description,
  latitude      = excluded.latitude,
  longitude     = excluded.longitude,
  claim_radius  = excluded.claim_radius,
  claim_polygon = excluded.claim_polygon,
  tier          = excluded.tier,
  collection_id = excluded.collection_id,
  city          = excluded.city,
  country       = excluded.country;

-- 4. Backfill polygons for the four migrated volcanoes (idempotent).
update public.achievements set
  claim_polygon = '[[37.67, 14.91], [37.83, 14.91], [37.83, 15.08], [37.67, 15.08]]'::jsonb
  where id = 'mtn-etna';

update public.achievements set
  claim_polygon = '[[35.30, 138.67], [35.42, 138.67], [35.42, 138.79], [35.30, 138.79]]'::jsonb
  where id = 'mtn-fuji';

update public.achievements set
  claim_polygon = '[[46.13, -122.27], [46.26, -122.27], [46.26, -122.13], [46.13, -122.13]]'::jsonb
  where id = 'mtn-st-helens';

update public.achievements set
  claim_polygon = '[[-0.75, -78.51], [-0.60, -78.51], [-0.60, -78.37], [-0.75, -78.37]]'::jsonb
  where id = 'mtn-cotopaxi';

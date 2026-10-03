-- Add 'deserts' collection: seed eleven iconic deserts of the world.
-- Polygons mirror the registry definitions in
-- lib/shared/data/deserts_achievement_registry.dart and are coarse
-- hand-authored approximations (5-11 vertices each).

insert into public.achievements
  (id, title, description, latitude, longitude, claim_radius,
   claim_polygon, tier, collection_id, city, country)
values
  ('desert-sahara', 'Sahara',
   'Cross the world''s largest hot desert — a 9-million km² sea of dunes spanning eleven countries from the Atlantic to the Red Sea.',
   24.0, 12.0, 200000,
   '[[33.0, -10.0], [33.0, 10.0], [32.0, 22.0], [30.0, 32.0], [22.0, 36.0], [16.0, 30.0], [15.0, 18.0], [16.0, 5.0], [18.0, -5.0], [21.0, -13.0], [27.0, -13.0]]'::jsonb,
   'platinum', 'deserts', 'Sahara', 'Multiple'),

  ('desert-namib', 'Namib (Sossusvlei)',
   'Walk the world''s oldest desert and climb the towering red dunes of Sossusvlei on the Namibian coast.',
   -24.7, 15.3, 60000,
   '[[-18.0, 12.0], [-19.0, 14.5], [-22.5, 15.5], [-26.0, 16.0], [-29.0, 17.0], [-29.0, 14.5], [-25.0, 13.5], [-21.0, 13.0]]'::jsonb,
   'platinum', 'deserts', 'Sossusvlei', 'Namibia'),

  ('desert-kalahari', 'Kalahari',
   'Track wildlife across the red sands of the Kalahari spanning Botswana, Namibia and South Africa.',
   -23.0, 22.0, 200000,
   '[[-19.0, 19.0], [-19.5, 22.0], [-20.0, 26.0], [-23.0, 26.5], [-27.0, 25.0], [-29.0, 23.0], [-28.5, 20.5], [-25.0, 19.0]]'::jsonb,
   'platinum', 'deserts', 'Kalahari', 'Botswana'),

  ('desert-gobi', 'Gobi',
   'Trek the high-altitude rain-shadow desert of Mongolia and northern China — home of dinosaur fossils and snow leopards.',
   42.5, 105.0, 200000,
   '[[47.0, 95.0], [46.5, 105.0], [45.5, 113.0], [42.0, 115.0], [38.5, 110.0], [38.0, 100.0], [40.0, 95.0]]'::jsonb,
   'platinum', 'deserts', 'Gobi', 'Mongolia'),

  ('desert-taklamakan', 'Taklamakan',
   'Cross the "Sea of Death" — a vast sand sea ringed by the Tian Shan, Kunlun and Pamir mountains in Xinjiang.',
   39.0, 83.0, 150000,
   '[[40.5, 76.5], [41.0, 82.0], [40.5, 87.0], [39.0, 89.0], [37.0, 86.0], [37.0, 79.0], [39.0, 76.0]]'::jsonb,
   'platinum', 'deserts', 'Xinjiang', 'China'),

  ('desert-wadi-rum', 'Wadi Rum',
   'Camp under the stars among the towering sandstone monoliths of the Valley of the Moon in southern Jordan.',
   29.5765, 35.4206, 25000,
   '[[29.75, 35.30], [29.75, 35.60], [29.40, 35.65], [29.30, 35.55], [29.30, 35.30], [29.50, 35.25]]'::jsonb,
   'gold', 'deserts', 'Aqaba Governorate', 'Jordan'),

  ('desert-negev', 'Negev',
   'Hike the makhtesh craters and ancient Nabatean spice route across Israel''s southern desert.',
   30.6, 34.85, 60000,
   '[[31.40, 34.40], [31.40, 35.40], [30.50, 35.40], [29.50, 35.00], [29.50, 34.55], [30.80, 34.30]]'::jsonb,
   'gold', 'deserts', 'Negev', 'Israel'),

  ('desert-death-valley', 'Death Valley',
   'Stand at Badwater Basin — the lowest, hottest, driest place in North America in California''s Mojave.',
   36.5054, -117.0794, 60000,
   '[[37.20, -117.55], [37.20, -116.55], [36.20, -116.30], [35.70, -116.55], [35.70, -117.55], [36.50, -117.65]]'::jsonb,
   'platinum', 'deserts', 'Inyo County', 'United States'),

  ('desert-white-sands', 'White Sands',
   'Walk the world''s largest gypsum dune field — 700 km² of brilliant white sand in New Mexico.',
   32.7872, -106.3257, 30000,
   '[[33.10, -106.55], [33.10, -106.10], [32.55, -106.05], [32.45, -106.30], [32.55, -106.55]]'::jsonb,
   'gold', 'deserts', 'Otero County', 'United States'),

  ('desert-atacama', 'Atacama',
   'Stand on the driest non-polar desert on Earth — a Mars-like high plateau between the Andes and the Pacific.',
   -24.5, -69.5, 150000,
   '[[-18.0, -70.4], [-19.5, -68.5], [-22.5, -67.5], [-26.0, -68.0], [-30.0, -69.5], [-30.0, -71.2], [-26.0, -71.0], [-20.0, -71.0]]'::jsonb,
   'platinum', 'deserts', 'Antofagasta', 'Chile'),

  ('desert-uyuni', 'Uyuni Salt Flats',
   'Stand on the world''s largest salt flat — 10,500 km² of mirror-perfect crust in Bolivia''s southern Altiplano.',
   -20.13, -67.5, 80000,
   '[[-19.50, -68.30], [-19.60, -67.05], [-20.30, -66.80], [-20.85, -67.10], [-20.80, -67.95], [-20.30, -68.30]]'::jsonb,
   'platinum', 'deserts', 'Potosí', 'Bolivia')

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

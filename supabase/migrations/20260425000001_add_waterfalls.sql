-- Add 'waterfalls' collection: 13 iconic waterfalls across six continents
-- with claim polygons matching the Flutter registry.

insert into public.achievements
  (id, title, description, latitude, longitude, claim_radius,
   claim_polygon, tier, collection_id, city, country)
values
  ('wf-niagara', 'Niagara Falls',
   'Feel the thunder of North America''s most powerful falls on the US-Canada border',
   43.0962, -79.0377, 5000,
   '[[43.07, -79.08], [43.12, -79.08], [43.12, -79.00], [43.07, -79.00]]'::jsonb,
   'platinum', 'waterfalls', 'Niagara Falls', 'United States'),

  ('wf-iguazu', 'Iguazú Falls',
   'Stand before the Devil''s Throat where 275 cascades thunder across the Argentina-Brazil border',
   -25.6953, -54.4367, 8000,
   '[[-25.74, -54.50], [-25.65, -54.50], [-25.65, -54.39], [-25.74, -54.39]]'::jsonb,
   'platinum', 'waterfalls', 'Puerto Iguazú', 'Argentina'),

  ('wf-victoria', 'Victoria Falls',
   'Witness the Smoke that Thunders on the Zambezi River between Zambia and Zimbabwe',
   -17.9243, 25.8572, 8000,
   '[[-17.97, 25.81], [-17.88, 25.81], [-17.88, 25.91], [-17.97, 25.91]]'::jsonb,
   'platinum', 'waterfalls', 'Livingstone', 'Zambia'),

  ('wf-angel', 'Angel Falls',
   'Gaze up at the world''s tallest uninterrupted waterfall in Venezuela''s Canaima jungle',
   5.9676, -62.5358, 10000,
   '[[5.90, -62.61], [6.04, -62.61], [6.04, -62.46], [5.90, -62.46]]'::jsonb,
   'platinum', 'waterfalls', 'Canaima', 'Venezuela'),

  ('wf-plitvice', 'Veliki Slap (Plitvice)',
   'Walk the boardwalks beneath Croatia''s tallest waterfall in Plitvice Lakes',
   44.9019, 15.6094, 5000,
   '[[44.87, 15.57], [44.93, 15.57], [44.93, 15.65], [44.87, 15.65]]'::jsonb,
   'gold', 'waterfalls', 'Plitvička Jezera', 'Croatia'),

  ('wf-gullfoss', 'Gullfoss',
   'Watch the Golden Falls plunge into a canyon on Iceland''s Golden Circle',
   64.3275, -20.1242, 5000,
   '[[64.30, -20.18], [64.36, -20.18], [64.36, -20.07], [64.30, -20.07]]'::jsonb,
   'gold', 'waterfalls', 'Bláskógabyggð', 'Iceland'),

  ('wf-yosemite', 'Yosemite Falls',
   'Hike to the base of North America''s tallest waterfall in Yosemite Valley',
   37.7566, -119.5969, 5000,
   '[[37.73, -119.63], [37.79, -119.63], [37.79, -119.56], [37.73, -119.56]]'::jsonb,
   'gold', 'waterfalls', 'Yosemite Valley', 'United States'),

  ('wf-kaieteur', 'Kaieteur Falls',
   'Stand on the cliff edge of one of the world''s most powerful single-drop waterfalls in Guyana',
   5.1722, -59.4836, 8000,
   '[[5.13, -59.53], [5.21, -59.53], [5.21, -59.44], [5.13, -59.44]]'::jsonb,
   'gold', 'waterfalls', 'Potaro-Siparuni', 'Guyana'),

  ('wf-sutherland', 'Sutherland Falls',
   'Trek the Milford Track to one of the tallest waterfalls in New Zealand',
   -44.7833, 167.7333, 5000,
   '[[-44.82, 167.69], [-44.74, 167.69], [-44.74, 167.78], [-44.82, 167.78]]'::jsonb,
   'gold', 'waterfalls', 'Fiordland', 'New Zealand'),

  ('wf-detian', 'Detian Falls',
   'Visit the largest transnational waterfall in Asia, straddling China and Vietnam',
   22.8581, 106.7081, 5000,
   '[[22.83, 106.67], [22.89, 106.67], [22.89, 106.75], [22.83, 106.75]]'::jsonb,
   'gold', 'waterfalls', 'Daxin', 'China'),

  ('wf-jog', 'Jog Falls',
   'Behold the Sharavathi River''s spectacular plunge in Karnataka, India',
   14.2294, 74.7128, 5000,
   '[[14.20, 74.68], [14.26, 74.68], [14.26, 74.75], [14.20, 74.75]]'::jsonb,
   'gold', 'waterfalls', 'Shimoga', 'India'),

  ('wf-skogafoss', 'Skógafoss',
   'Walk to the base of the rainbow-arched 60m falls on Iceland''s south coast',
   63.5320, -19.5113, 4000,
   '[[63.51, -19.55], [63.55, -19.55], [63.55, -19.47], [63.51, -19.47]]'::jsonb,
   'gold', 'waterfalls', 'Skógar', 'Iceland'),

  ('wf-seljalandsfoss', 'Seljalandsfoss',
   'Walk behind the curtain of water at one of Iceland''s most photographed falls',
   63.6156, -19.9886, 4000,
   '[[63.59, -20.03], [63.64, -20.03], [63.64, -19.95], [63.59, -19.95]]'::jsonb,
   'gold', 'waterfalls', 'Rangárþing eystra', 'Iceland')

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

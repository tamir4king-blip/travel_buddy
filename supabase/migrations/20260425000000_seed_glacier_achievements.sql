-- Seed glacier & ice achievements into the public.achievements table.
-- Mirrors the local registry in lib/shared/data/glaciers_achievement_registry.dart.
-- Polygons live only in the local registry; this table stores radial geofence
-- + rich metadata (city, country, photos, hours) fetched on demand.

insert into public.achievements (id, title, description, latitude, longitude, claim_radius, tier, collection_id, city, country) values
('glacier-perito-moreno',     'Perito Moreno Glacier',                'Stand before the calving wall of one of the few glaciers on Earth still advancing — a 5 km face of blue ice in Argentine Patagonia.',                          -50.4814,  -73.0420,    15000, 'gold',     'glaciers', 'El Calafate',           'Argentina'),
('glacier-vatnajokull',       'Vatnajökull',                          'Cross Europe''s largest ice cap — a 7,900 km² frozen plateau covering 8% of Iceland, riddled with sub-glacial volcanoes.',                                  64.4163, -16.7956,    60000, 'gold',     'glaciers', 'Höfn',                  'Iceland'),
('glacier-aletsch',           'Aletsch Glacier',                      'Walk above the longest glacier in the Alps — a 23 km river of ice winding down from the Jungfrau region of Switzerland.',                                   46.5060,   8.0395,    12000, 'gold',     'glaciers', 'Fieschertal',           'Switzerland'),
('glacier-jostedalsbreen',    'Jostedalsbreen',                       'Trek beneath the largest glacier in continental Europe — a 474 km² ice cap spanning the fjordlands of western Norway.',                                   61.6500,   7.0500,    25000, 'gold',     'glaciers', 'Stryn',                 'Norway'),
('glacier-athabasca',         'Athabasca Glacier & Columbia Icefield','Ride a snowcoach onto a tongue of the Columbia Icefield — the largest icefield in the Canadian Rockies, straddling the Continental Divide.',              52.1880, -117.2370,    18000, 'gold',     'glaciers', 'Jasper',                'Canada'),
('glacier-mendenhall',        'Mendenhall Glacier',                   'Hike to the face of a glowing blue glacier just outside Juneau — a 21 km tongue flowing from the Juneau Icefield in Alaska.',                              58.4359, -134.5446,    10000, 'silver',   'glaciers', 'Juneau',                'United States'),
('glacier-franz-josef',       'Franz Josef Glacier',                  'Walk the moraine of a temperate-rainforest glacier — a 12 km river of ice flowing nearly to sea level on New Zealand''s West Coast.',                    -43.4654,  170.1830,     8000, 'silver',   'glaciers', 'Franz Josef',           'New Zealand'),
('glacier-fox',               'Fox Glacier',                          'Trek the bouldery valley of Fox Glacier — sister ice river to Franz Josef, descending the western slopes of the Southern Alps.',                         -43.5360,  170.0210,     8000, 'silver',   'glaciers', 'Fox Glacier',           'New Zealand'),
('glacier-antarctic-shelves', 'Antarctic Ice Shelves',                'Set foot on the white continent — vast floating ice shelves like Ross, Ronne, and Filchner cover an area larger than Greenland.',                         -82.0000,  -55.0000,  2000000, 'platinum', 'glaciers',   null, 'Antarctica'),
('continent-antarctica',      'Visit Antarctica!',                    'Reach the white continent at the bottom of the world',                                                                                                       -82.0000,    0.0000,  3000000, 'platinum', 'continents', null, 'Antarctica')

on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  claim_radius = excluded.claim_radius,
  tier = excluded.tier,
  collection_id = excluded.collection_id,
  city = excluded.city,
  country = excluded.country;

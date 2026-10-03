-- Seed achievements table with existing registry data
-- Rich fields (opening_hours, cover_photo_url, photo_urls, website, phone) are NULL
-- and will be populated incrementally via Supabase dashboard or admin tools.

insert into public.achievements (id, title, description, latitude, longitude, claim_radius, tier, collection_id, city, country) values
-- ══════════════════════════════════════════════════
-- NETANYA LOCAL — Landmarks
-- ══════════════════════════════════════════════════
('tayelet-netanya', 'The Netanya Promenade', 'Walk along the famous clifftop promenade overlooking the Mediterranean', 32.3282, 34.8485, 300, 'bronze', 'landmarks', 'Netanya', 'Israel'),
('kikar-haatzmaut', 'Independence Square', 'Visit the vibrant heart of Netanya at Independence Square', 32.3290, 34.8555, 200, 'bronze', 'landmarks', 'Netanya', 'Israel'),
('glass-elevator', 'The Glass Elevator', 'Ride the panoramic glass elevator connecting the cliff to the beach', 32.3275, 34.8487, 150, 'silver', 'landmarks', 'Netanya', 'Israel'),
('wingate-institute', 'Wingate Institute', 'Visit Israel''s national center for physical education and sport', 32.2780, 34.8530, 400, 'platinum', 'landmarks', 'Netanya', 'Israel'),
('umm-khalid-fortress', 'Umm Khalid Fortress', 'Explore the ancient Crusader fortress ruins overlooking the northern coastline', 32.3520, 34.8490, 250, 'gold', 'landmarks', 'Netanya', 'Israel'),
('north-promenade-lookout', 'North Cliff Lookout', 'Take in the panoramic sea view from the northern promenade lookout point', 32.3430, 34.8475, 200, 'silver', 'landmarks', 'Netanya', 'Israel'),
('netanya-stadium', 'Netanya Stadium', 'Visit the home of Maccabi Netanya FC and its surrounding sports complex', 32.3100, 34.8620, 300, 'silver', 'landmarks', 'Netanya', 'Israel'),
('seasons-lookout', 'Seasons Cliff Lookout', 'Take in the breathtaking view from the lookout near the Seasons Hotel', 32.3268, 34.8478, 150, 'silver', 'landmarks', 'Netanya', 'Israel'),
('founders-monument', 'Founders Monument', 'Visit the monument commemorating the founders of Netanya', 32.3285, 34.8540, 150, 'bronze', 'landmarks', 'Netanya', 'Israel'),
('old-train-station', 'Old Netanya Train Station', 'Discover the historic train station and its surrounding area', 32.3260, 34.8590, 200, 'silver', 'landmarks', 'Netanya', 'Israel'),

-- ══════════════════════════════════════════════════
-- NETANYA LOCAL — Beaches
-- ══════════════════════════════════════════════════
('sironit-beach', 'Sironit Beach', 'Enjoy the popular Sironit Beach with its golden sands', 32.3340, 34.8470, 300, 'bronze', 'beaches', 'Netanya', 'Israel'),
('herzl-beach', 'Herzl Beach', 'Relax at Herzl Beach, one of Netanya''s most beloved shores', 32.3245, 34.8475, 300, 'bronze', 'beaches', 'Netanya', 'Israel'),
('poleg-beach', 'Poleg Beach', 'Discover the scenic Poleg Beach at the southern edge of Netanya', 32.2950, 34.8420, 400, 'silver', 'beaches', 'Netanya', 'Israel'),
('blue-bay', 'Blue Bay Beach', 'Visit the beautiful Blue Bay Beach and its turquoise waters', 32.3140, 34.8430, 300, 'silver', 'beaches', 'Netanya', 'Israel'),
('argaman-beach', 'Argaman Beach', 'Discover the quiet Argaman Beach in northern Netanya, perfect for sunset walks', 32.3460, 34.8460, 300, 'silver', 'beaches', 'Netanya', 'Israel'),
('tzofit-beach', 'Tzofit Beach', 'Visit the scenic Tzofit Beach nestled beneath the northern cliffs', 32.3390, 34.8465, 300, 'bronze', 'beaches', 'Netanya', 'Israel'),
('kontiki-beach', 'Kontiki Beach', 'Relax at the charming Kontiki Beach with its laid-back atmosphere', 32.3210, 34.8460, 300, 'bronze', 'beaches', 'Netanya', 'Israel'),
('haonot-beach', 'HaOnot Beach', 'Visit HaOnot Beach tucked between the dramatic cliff inlets', 32.3350, 34.8468, 250, 'bronze', 'beaches', 'Netanya', 'Israel'),
('beit-yanai', 'Beit Yanai Beach', 'Discover the scenic Beit Yanai Beach at the Alexander Stream estuary', 32.3890, 34.8580, 400, 'gold', 'beaches', 'Netanya', 'Israel'),
('mikhmoret-beach', 'Mikhmoret Beach', 'Explore the unspoiled Mikhmoret Beach north of Netanya', 32.3950, 34.8520, 400, 'silver', 'beaches', 'Netanya', 'Israel'),

-- ══════════════════════════════════════════════════
-- NETANYA LOCAL — Parks
-- ══════════════════════════════════════════════════
('nahal-alexander', 'Alexander Stream Nature Reserve', 'Explore the Alexander Stream where sea turtles nest', 32.3740, 34.8640, 500, 'gold', 'parks', 'Netanya', 'Israel'),
('gan-hamelech', 'King''s Garden & Amphitheatre', 'Stroll through the King''s Garden and its open-air amphitheatre', 32.3290, 34.8500, 200, 'silver', 'parks', 'Netanya', 'Israel'),
('utman-park', 'Utman Garden Park', 'Relax in the peaceful Utman Garden Park', 32.3200, 34.8600, 250, 'bronze', 'parks', 'Netanya', 'Israel'),
('ir-yamim', 'Ir Yamim Park', 'Explore the expansive Ir Yamim Park in south Netanya', 32.2870, 34.8480, 350, 'gold', 'parks', 'Netanya', 'Israel'),
('park-raanana-junction', 'Arison Park North', 'Stroll through the green Arison Park on the northern edge of Netanya', 32.3500, 34.8580, 300, 'bronze', 'parks', 'Netanya', 'Israel'),
('poleg-reserve', 'Poleg Stream Nature Reserve', 'Hike through the lush Poleg Stream nature reserve and its wetlands', 32.2900, 34.8450, 400, 'gold', 'parks', 'Netanya', 'Israel'),
('ramat-poleg-park', 'Ramat Poleg Park', 'Enjoy the open green spaces and playgrounds of Ramat Poleg', 32.2920, 34.8520, 300, 'bronze', 'parks', 'Netanya', 'Israel'),
('iris-reserve', 'Iris Nature Reserve', 'Visit the rare coastal iris reserve, home to endangered Iris atropurpurea', 32.3050, 34.8650, 350, 'platinum', 'parks', 'Netanya', 'Israel'),

-- ══════════════════════════════════════════════════
-- NETANYA LOCAL — Culture
-- ══════════════════════════════════════════════════
('well-museum', 'The Well House Museum', 'Visit the historic Well House Museum documenting the founding of Netanya', 32.3380, 34.8560, 200, 'gold', 'culture', 'Netanya', 'Israel'),
('netanya-market', 'The Netanya Market', 'Browse the bustling Netanya Market for fresh produce and local flavors', 32.3310, 34.8570, 200, 'gold', 'culture', 'Netanya', 'Israel'),
('beit-haedut', 'Beit HaEdut Museum', 'Discover the history of immigration at the Beit HaEdut Museum', 32.3290, 34.8545, 150, 'gold', 'culture', 'Netanya', 'Israel'),
('hasharon-mall', 'HaSharon Mall', 'Visit the HaSharon Mall, a major shopping and entertainment hub', 32.3170, 34.8640, 300, 'silver', 'culture', 'Netanya', 'Israel'),
('netanya-gallery', 'Netanya Municipal Gallery', 'Browse contemporary art exhibitions at the municipal gallery', 32.3295, 34.8548, 150, 'silver', 'culture', 'Netanya', 'Israel'),
('cliff-sculptures', 'Cliff-top Sculpture Garden', 'Walk among the open-air sculptures along the cliff promenade', 32.3260, 34.8490, 250, 'silver', 'culture', 'Netanya', 'Israel'),
('diamond-center', 'Diamond Industry Center', 'Learn about Netanya''s historic diamond polishing industry', 32.3180, 34.8580, 250, 'gold', 'culture', 'Netanya', 'Israel'),
('havatzelet', 'Havatzelet HaSharon', 'Explore the historic Havatzelet HaSharon village, one of the oldest settlements in the Sharon plain', 32.3600, 34.8530, 300, 'silver', 'culture', 'Netanya', 'Israel'),
('bialik-street', 'Bialik Cultural Street', 'Stroll down Bialik Street with its cafes, shops, and cultural vibe', 32.3300, 34.8555, 200, 'bronze', 'culture', 'Netanya', 'Israel'),
('uranus-bar', 'Uranus Bar', 'Grab a drink at the legendary Uranus Pub on Independence Square, a Netanya icon since the 1980s', 32.3303, 34.8514, 100, 'silver', 'culture', 'Netanya', 'Israel'),
('hansel-and-gretel', 'Hansel & Gretel', 'Enjoy craft beers at the Hansel & Gretel beer garden in south Netanya', 32.2787, 34.8639, 100, 'silver', 'culture', 'Netanya', 'Israel'),
('beer-shop', 'Beer Shop', 'Browse over 900 beers at the legendary Beer Shop on Ha-Bonim Street', 32.2808, 34.8618, 100, 'silver', 'culture', 'Netanya', 'Israel'),

-- ══════════════════════════════════════════════════
-- EUROPEAN COUNTRIES
-- ══════════════════════════════════════════════════
('europe-france', 'France', 'Visit the City of Light and explore the heart of France', 48.8566, 2.3522, 50000, 'silver', 'europe', 'Paris', 'France'),
('europe-italy', 'Italy', 'Discover the Eternal City and the wonders of Italy', 41.9028, 12.4964, 50000, 'silver', 'europe', 'Rome', 'Italy'),
('europe-spain', 'Spain', 'Experience the vibrant culture of Madrid and Spain', 40.4168, -3.7038, 50000, 'silver', 'europe', 'Madrid', 'Spain'),
('europe-germany', 'Germany', 'Explore Berlin and the rich history of Germany', 52.5200, 13.4050, 50000, 'silver', 'europe', 'Berlin', 'Germany'),
('europe-uk', 'United Kingdom', 'Visit London and discover the charm of the UK', 51.5074, -0.1278, 50000, 'silver', 'europe', 'London', 'United Kingdom'),
('europe-netherlands', 'Netherlands', 'Cycle through Amsterdam and explore the Netherlands', 52.3676, 4.9041, 50000, 'silver', 'europe', 'Amsterdam', 'Netherlands'),
('europe-greece', 'Greece', 'Walk among the ancient ruins of Athens and Greece', 37.9838, 23.7275, 50000, 'silver', 'europe', 'Athens', 'Greece'),
('europe-switzerland', 'Switzerland', 'Marvel at the Alps from Bern and across Switzerland', 46.9480, 7.4474, 50000, 'silver', 'europe', 'Bern', 'Switzerland'),
('europe-portugal', 'Portugal', 'Enjoy the coastal beauty of Lisbon and Portugal', 38.7223, -9.1393, 50000, 'silver', 'europe', 'Lisbon', 'Portugal'),
('europe-czech', 'Czech Republic', 'Explore the fairy-tale city of Prague and Czechia', 50.0755, 14.4378, 50000, 'silver', 'europe', 'Prague', 'Czech Republic'),
('europe-austria', 'Austria', 'Waltz through Vienna and the elegance of Austria', 48.2082, 16.3738, 50000, 'silver', 'europe', 'Vienna', 'Austria'),
('europe-sweden', 'Sweden', 'Explore Stockholm and the beauty of Scandinavia', 59.3293, 18.0686, 50000, 'silver', 'europe', 'Stockholm', 'Sweden'),
('europe-norway', 'Norway', 'Discover the fjords and northern lights of Norway', 59.9139, 10.7522, 50000, 'silver', 'europe', 'Oslo', 'Norway'),
('europe-denmark', 'Denmark', 'Experience the hygge lifestyle in Copenhagen and Denmark', 55.6761, 12.5683, 50000, 'silver', 'europe', 'Copenhagen', 'Denmark'),
('europe-poland', 'Poland', 'Explore the rich history and culture of Warsaw and Poland', 52.2297, 21.0122, 50000, 'silver', 'europe', 'Warsaw', 'Poland'),
('europe-ireland', 'Ireland', 'Discover the green landscapes and vibrant pubs of Ireland', 53.3498, -6.2603, 50000, 'silver', 'europe', 'Dublin', 'Ireland'),
('europe-croatia', 'Croatia', 'Sail the Adriatic coast and explore ancient Dubrovnik', 45.8150, 15.9819, 50000, 'silver', 'europe', 'Zagreb', 'Croatia'),
('europe-hungary', 'Hungary', 'Soak in the thermal baths of Budapest and Hungary', 47.4979, 19.0402, 50000, 'silver', 'europe', 'Budapest', 'Hungary'),
('europe-belgium', 'Belgium', 'Indulge in chocolate and waffles in Brussels and Belgium', 50.8503, 4.3517, 50000, 'silver', 'europe', 'Brussels', 'Belgium'),
('europe-turkey', 'Turkey', 'Where East meets West in the grand city of Istanbul', 41.0082, 28.9784, 50000, 'silver', 'europe', 'Istanbul', 'Turkey'),
('europe-finland', 'Finland', 'Visit Helsinki and the land of saunas and northern lights', 60.1699, 24.9384, 50000, 'silver', 'europe', 'Helsinki', 'Finland'),
('europe-romania', 'Romania', 'Discover Bucharest and the legends of Transylvania', 44.4268, 26.1025, 50000, 'silver', 'europe', 'Bucharest', 'Romania'),
('europe-iceland', 'Iceland', 'Explore Reykjavik and the land of fire and ice', 64.1466, -21.9426, 50000, 'silver', 'europe', 'Reykjavik', 'Iceland'),
('europe-slovenia', 'Slovenia', 'Discover Ljubljana and the emerald beauty of Slovenia', 46.0569, 14.5058, 50000, 'silver', 'europe', 'Ljubljana', 'Slovenia'),
('europe-slovakia', 'Slovakia', 'Explore Bratislava and the castles of Slovakia', 48.1486, 17.1077, 50000, 'silver', 'europe', 'Bratislava', 'Slovakia'),
('europe-serbia', 'Serbia', 'Experience Belgrade and the vibrant spirit of Serbia', 44.7866, 20.4489, 50000, 'silver', 'europe', 'Belgrade', 'Serbia'),
('europe-bulgaria', 'Bulgaria', 'Visit Sofia and the ancient treasures of Bulgaria', 42.6977, 23.3219, 50000, 'silver', 'europe', 'Sofia', 'Bulgaria'),
('europe-cyprus', 'Cyprus', 'Relax on the Mediterranean island of Aphrodite', 35.1856, 33.3823, 50000, 'silver', 'europe', 'Nicosia', 'Cyprus'),
('europe-malta', 'Malta', 'Explore the ancient fortified island of Malta', 35.8989, 14.5146, 50000, 'silver', 'europe', 'Valletta', 'Malta'),
('europe-luxembourg', 'Luxembourg', 'Visit the charming Grand Duchy in the heart of Europe', 49.6116, 6.1319, 50000, 'silver', 'europe', 'Luxembourg City', 'Luxembourg'),

-- ══════════════════════════════════════════════════
-- AMERICAN DESTINATIONS
-- ══════════════════════════════════════════════════
('americas-nyc', 'New York City', 'Experience the energy of the Big Apple', 40.7128, -74.0060, 30000, 'gold', 'americas', 'New York', 'United States'),
('americas-california', 'California', 'Soak up the sun on the golden coast of California', 34.0522, -118.2437, 50000, 'gold', 'americas', 'Los Angeles', 'United States'),
('americas-florida', 'Florida', 'Enjoy the tropical vibes of the Sunshine State', 25.7617, -80.1918, 50000, 'gold', 'americas', 'Miami', 'United States'),
('americas-hawaii', 'Hawaii', 'Discover the paradise islands of Hawaii', 21.3069, -157.8583, 50000, 'gold', 'americas', 'Honolulu', 'United States'),
('americas-grand-canyon', 'Grand Canyon', 'Stand at the rim of the awe-inspiring Grand Canyon', 36.1069, -112.1129, 30000, 'gold', 'americas', 'Grand Canyon', 'United States'),

-- ══════════════════════════════════════════════════
-- NATIONAL PARKS
-- ══════════════════════════════════════════════════
('np-yellowstone', 'Yellowstone', 'Witness geysers and wildlife in Yellowstone National Park', 44.4280, -110.5885, 10000, 'gold', 'national-parks', 'Yellowstone', 'United States'),
('np-yosemite', 'Yosemite', 'Hike beneath towering granite cliffs in Yosemite', 37.8651, -119.5383, 10000, 'gold', 'national-parks', 'Yosemite', 'United States'),
('np-grand-canyon', 'Grand Canyon NP', 'Explore the vast Grand Canyon National Park', 36.0544, -112.1401, 10000, 'gold', 'national-parks', 'Grand Canyon', 'United States'),
('np-zion', 'Zion', 'Trek through the stunning red canyons of Zion', 37.2982, -113.0263, 10000, 'gold', 'national-parks', 'Springdale', 'United States'),
('np-glacier', 'Glacier', 'Drive the Going-to-the-Sun Road in Glacier National Park', 48.7596, -113.7870, 10000, 'gold', 'national-parks', 'West Glacier', 'United States'),
('np-banff', 'Banff', 'Experience the turquoise lakes of Banff National Park', 51.4968, -115.9281, 10000, 'gold', 'national-parks', 'Banff', 'Canada'),
('np-torres-del-paine', 'Torres del Paine', 'Hike to the iconic granite towers of Patagonia', -50.9423, -73.4068, 10000, 'gold', 'national-parks', 'Torres del Paine', 'Chile'),
('np-kruger', 'Kruger', 'Spot the Big Five on safari in Kruger National Park', -23.9884, 31.5547, 10000, 'gold', 'national-parks', 'Kruger', 'South Africa'),
('np-swiss', 'Swiss National Park', 'Wander through the pristine Swiss National Park', 46.6600, 10.1775, 8000, 'gold', 'national-parks', 'Zernez', 'Switzerland'),
('np-plitvice', 'Plitvice Lakes', 'Walk the boardwalks above the cascading Plitvice Lakes', 44.8654, 15.5820, 8000, 'gold', 'national-parks', 'Plitvice', 'Croatia'),

-- ══════════════════════════════════════════════════
-- SKI RESORTS
-- ══════════════════════════════════════════════════
('ski-chamonix', 'Chamonix', 'Ski beneath Mont Blanc in legendary Chamonix', 45.9237, 6.8694, 5000, 'silver', 'ski-resorts', 'Chamonix', 'France'),
('ski-zermatt', 'Zermatt', 'Carve turns with a view of the Matterhorn in Zermatt', 46.0207, 7.7491, 5000, 'silver', 'ski-resorts', 'Zermatt', 'Switzerland'),
('ski-st-moritz', 'St. Moritz', 'Experience the glamour and powder of St. Moritz', 46.4908, 9.8355, 5000, 'silver', 'ski-resorts', 'St. Moritz', 'Switzerland'),
('ski-whistler', 'Whistler', 'Ride the massive terrain of Whistler Blackcomb', 50.1163, -122.9574, 5000, 'silver', 'ski-resorts', 'Whistler', 'Canada'),
('ski-aspen', 'Aspen', 'Hit the slopes of the iconic Aspen resort', 39.1911, -106.8175, 5000, 'silver', 'ski-resorts', 'Aspen', 'United States'),
('ski-niseko', 'Niseko', 'Enjoy world-class powder snow in Niseko, Japan', 42.8621, 140.6874, 5000, 'silver', 'ski-resorts', 'Niseko', 'Japan'),
('ski-val-disere', 'Val d''Isere', 'Ski the legendary slopes of Val d''Isere in the French Alps', 45.4486, 6.9806, 5000, 'silver', 'ski-resorts', 'Val d''Isere', 'France'),
('ski-verbier', 'Verbier', 'Challenge yourself on the freeride terrain of Verbier', 46.0964, 7.2283, 5000, 'silver', 'ski-resorts', 'Verbier', 'Switzerland'),
('ski-courchevel', 'Courchevel', 'Explore the vast Three Valleys from Courchevel', 45.4154, 6.6345, 5000, 'silver', 'ski-resorts', 'Courchevel', 'France'),
('ski-kitzbuhel', 'Kitzbuhel', 'Tackle the famous Hahnenkamm run in Kitzbuhel', 47.4492, 12.3922, 5000, 'silver', 'ski-resorts', 'Kitzbuhel', 'Austria'),

-- ══════════════════════════════════════════════════
-- WORLD CAPITALS
-- ══════════════════════════════════════════════════
('capital-tokyo', 'Tokyo', 'Experience the electric energy of Japan''s capital', 35.6762, 139.6503, 30000, 'gold', 'capitals', 'Tokyo', 'Japan'),
('capital-washington', 'Washington D.C.', 'Visit the capital of the United States and its iconic monuments', 38.9072, -77.0369, 30000, 'gold', 'capitals', 'Washington D.C.', 'United States'),
('capital-cairo', 'Cairo', 'Discover the ancient capital of Egypt by the Nile', 30.0444, 31.2357, 30000, 'gold', 'capitals', 'Cairo', 'Egypt'),
('capital-canberra', 'Canberra', 'Explore Australia''s planned capital city', -35.2809, 149.1300, 30000, 'gold', 'capitals', 'Canberra', 'Australia'),
('capital-brasilia', 'Brasilia', 'Marvel at the modernist architecture of Brazil''s capital', -15.7975, -47.8919, 30000, 'gold', 'capitals', 'Brasilia', 'Brazil'),
('capital-ottawa', 'Ottawa', 'Visit the charming capital of Canada on the Ottawa River', 45.4215, -75.6972, 30000, 'gold', 'capitals', 'Ottawa', 'Canada'),
('capital-new-delhi', 'New Delhi', 'Experience the vibrant capital of India', 28.6139, 77.2090, 30000, 'gold', 'capitals', 'New Delhi', 'India'),
('capital-bangkok', 'Bangkok', 'Immerse yourself in the dazzling capital of Thailand', 13.7563, 100.5018, 30000, 'gold', 'capitals', 'Bangkok', 'Thailand'),
('capital-moscow', 'Moscow', 'Walk through Red Square in Russia''s grand capital', 55.7558, 37.6173, 30000, 'gold', 'capitals', 'Moscow', 'Russia'),
('capital-buenos-aires', 'Buenos Aires', 'Dance the tango in Argentina''s passionate capital', -34.6037, -58.3816, 30000, 'gold', 'capitals', 'Buenos Aires', 'Argentina'),

-- ══════════════════════════════════════════════════
-- ANCIENT RELIGIOUS SITES
-- ══════════════════════════════════════════════════
('site-western-wall', 'Western Wall', 'Stand before the holiest site in Judaism in Jerusalem', 31.7767, 35.2345, 10000, 'platinum', 'ancient-sites', 'Jerusalem', 'Israel'),
('site-vatican', 'Vatican City', 'Visit the spiritual heart of the Catholic Church', 41.9029, 12.4534, 5000, 'platinum', 'ancient-sites', 'Vatican City', 'Vatican City'),
('site-mecca', 'Mecca', 'Visit the holiest city in Islam and home of the Kaaba', 21.4225, 39.8262, 10000, 'platinum', 'ancient-sites', 'Mecca', 'Saudi Arabia'),
('site-angkor-wat', 'Angkor Wat', 'Explore the largest religious monument in the world', 13.4125, 103.8670, 10000, 'platinum', 'ancient-sites', 'Siem Reap', 'Cambodia'),
('site-bodh-gaya', 'Bodh Gaya', 'Visit where the Buddha attained enlightenment under the Bodhi Tree', 24.6961, 84.9911, 10000, 'platinum', 'ancient-sites', 'Bodh Gaya', 'India'),
('site-hagia-sophia', 'Hagia Sophia', 'Marvel at the ancient cathedral-turned-mosque in Istanbul', 41.0086, 28.9802, 5000, 'platinum', 'ancient-sites', 'Istanbul', 'Turkey'),
('site-golden-temple', 'Golden Temple', 'Visit the holiest Gurdwara of Sikhism in Amritsar', 31.6200, 74.8765, 10000, 'platinum', 'ancient-sites', 'Amritsar', 'India'),
('site-mount-sinai', 'Mount Sinai', 'Climb the mountain where Moses received the Ten Commandments', 28.5393, 33.9750, 10000, 'platinum', 'ancient-sites', 'Saint Catherine', 'Egypt'),
('site-shinto-ise', 'Ise Grand Shrine', 'Visit the most sacred Shinto shrine in Japan', 34.4551, 136.7256, 10000, 'platinum', 'ancient-sites', 'Ise', 'Japan'),
('site-chichen-itza', 'Chichen Itza', 'Stand before the ancient Mayan pyramid of Kukulcan', 20.6843, -88.5678, 10000, 'platinum', 'ancient-sites', 'Tinum', 'Mexico'),

-- ══════════════════════════════════════════════════
-- TOURIST DESTINATIONS
-- ══════════════════════════════════════════════════
('tourist-paris', 'Paris', 'Visit the world''s most visited city and see the Eiffel Tower', 48.8566, 2.3522, 20000, 'gold', 'tourist-destinations', 'Paris', 'France'),
('tourist-dubai', 'Dubai', 'Experience the futuristic skyline and luxury of Dubai', 25.2048, 55.2708, 20000, 'gold', 'tourist-destinations', 'Dubai', 'United Arab Emirates'),
('tourist-bangkok', 'Bangkok', 'Explore the vibrant street life and temples of Bangkok', 13.7563, 100.5018, 20000, 'gold', 'tourist-destinations', 'Bangkok', 'Thailand'),
('tourist-istanbul', 'Istanbul', 'Where East meets West across the Bosphorus', 41.0082, 28.9784, 20000, 'gold', 'tourist-destinations', 'Istanbul', 'Turkey'),
('tourist-rome', 'Rome', 'Walk through millennia of history in the Eternal City', 41.9028, 12.4964, 20000, 'gold', 'tourist-destinations', 'Rome', 'Italy'),
('tourist-london', 'London', 'Visit Big Ben, Buckingham Palace, and the Tower of London', 51.5074, -0.1278, 20000, 'gold', 'tourist-destinations', 'London', 'United Kingdom'),
('tourist-singapore', 'Singapore', 'Discover the garden city and its iconic Marina Bay Sands', 1.3521, 103.8198, 20000, 'gold', 'tourist-destinations', 'Singapore', 'Singapore'),
('tourist-barcelona', 'Barcelona', 'Marvel at Gaudi''s masterpieces and the Mediterranean coast', 41.3874, 2.1686, 20000, 'gold', 'tourist-destinations', 'Barcelona', 'Spain'),
('tourist-bali', 'Bali', 'Find paradise among the temples and rice terraces of Bali', -8.3405, 115.0920, 20000, 'gold', 'tourist-destinations', 'Bali', 'Indonesia'),
('tourist-machu-picchu', 'Machu Picchu', 'Trek to the ancient Incan citadel high in the Andes', -13.1631, -72.5450, 20000, 'gold', 'tourist-destinations', 'Aguas Calientes', 'Peru'),

-- ══════════════════════════════════════════════════
-- AFRICAN COUNTRIES
-- ══════════════════════════════════════════════════
('africa-south-africa', 'South Africa', 'Explore Cape Town and the rainbow nation of South Africa', -33.9249, 18.4241, 50000, 'silver', 'africa', 'Cape Town', 'South Africa'),
('africa-morocco', 'Morocco', 'Wander through the vibrant souks and riads of Marrakech', 34.0209, -6.8416, 50000, 'silver', 'africa', 'Rabat', 'Morocco'),
('africa-egypt', 'Egypt', 'Stand before the Great Pyramids and cruise the Nile', 30.0444, 31.2357, 50000, 'silver', 'africa', 'Cairo', 'Egypt'),
('africa-kenya', 'Kenya', 'Witness the Great Migration and explore Nairobi', -1.2921, 36.8219, 50000, 'silver', 'africa', 'Nairobi', 'Kenya'),
('africa-tanzania', 'Tanzania', 'Climb Kilimanjaro and safari through the Serengeti', -6.7924, 39.2083, 50000, 'silver', 'africa', 'Dar es Salaam', 'Tanzania'),
('africa-nigeria', 'Nigeria', 'Experience the bustling energy of Lagos and Abuja', 9.0579, 7.4951, 50000, 'silver', 'africa', 'Abuja', 'Nigeria'),
('africa-ethiopia', 'Ethiopia', 'Discover ancient churches carved from rock in Lalibela', 9.0250, 38.7469, 50000, 'silver', 'africa', 'Addis Ababa', 'Ethiopia'),
('africa-ghana', 'Ghana', 'Explore Accra and the vibrant culture of West Africa', 5.6037, -0.1870, 50000, 'silver', 'africa', 'Accra', 'Ghana'),
('africa-tunisia', 'Tunisia', 'Walk through ancient Carthage and the medina of Tunis', 36.8065, 10.1815, 50000, 'silver', 'africa', 'Tunis', 'Tunisia'),
('africa-madagascar', 'Madagascar', 'Discover the unique wildlife of the island of Madagascar', -18.8792, 47.5079, 50000, 'silver', 'africa', 'Antananarivo', 'Madagascar'),

-- ══════════════════════════════════════════════════
-- ASIAN COUNTRIES
-- ══════════════════════════════════════════════════
('asia-japan', 'Japan', 'Experience ancient temples and modern marvels in Tokyo', 35.6762, 139.6503, 50000, 'silver', 'asia', 'Tokyo', 'Japan'),
('asia-china', 'China', 'Walk the Great Wall and explore the Forbidden City in Beijing', 39.9042, 116.4074, 50000, 'silver', 'asia', 'Beijing', 'China'),
('asia-south-korea', 'South Korea', 'Discover K-culture and ancient palaces in Seoul', 37.5665, 126.9780, 50000, 'silver', 'asia', 'Seoul', 'South Korea'),
('asia-thailand', 'Thailand', 'Explore golden temples and tropical islands from Bangkok', 13.7563, 100.5018, 50000, 'silver', 'asia', 'Bangkok', 'Thailand'),
('asia-vietnam', 'Vietnam', 'Cruise Ha Long Bay and taste pho in Hanoi', 21.0285, 105.8542, 50000, 'silver', 'asia', 'Hanoi', 'Vietnam'),
('asia-india', 'India', 'Visit the Taj Mahal and experience the colors of New Delhi', 28.6139, 77.2090, 50000, 'silver', 'asia', 'New Delhi', 'India'),
('asia-indonesia', 'Indonesia', 'Explore thousands of islands from the capital Jakarta', -6.2088, 106.8456, 50000, 'silver', 'asia', 'Jakarta', 'Indonesia'),
('asia-philippines', 'Philippines', 'Island-hop through crystal-clear waters from Manila', 14.5995, 120.9842, 50000, 'silver', 'asia', 'Manila', 'Philippines'),
('asia-malaysia', 'Malaysia', 'Marvel at the Petronas Towers and explore Kuala Lumpur', 3.1390, 101.6869, 50000, 'silver', 'asia', 'Kuala Lumpur', 'Malaysia'),
('asia-singapore', 'Singapore', 'Discover the garden city-state and Marina Bay Sands', 1.3521, 103.8198, 50000, 'silver', 'asia', 'Singapore', 'Singapore'),
('asia-cambodia', 'Cambodia', 'Explore the ancient temples of Angkor from Phnom Penh', 11.5564, 104.9282, 50000, 'silver', 'asia', 'Phnom Penh', 'Cambodia'),
('asia-sri-lanka', 'Sri Lanka', 'Ride scenic trains through tea plantations from Colombo', 6.9271, 79.8612, 50000, 'silver', 'asia', 'Colombo', 'Sri Lanka'),
('asia-nepal', 'Nepal', 'Trek to Everest Base Camp from the vibrant city of Kathmandu', 27.7172, 85.3240, 50000, 'silver', 'asia', 'Kathmandu', 'Nepal'),
('asia-jordan', 'Jordan', 'Walk through the ancient city of Petra and float in the Dead Sea', 31.9454, 35.9284, 50000, 'silver', 'asia', 'Amman', 'Jordan'),
('asia-uae', 'United Arab Emirates', 'Experience the futuristic skyline and luxury of Abu Dhabi', 24.4539, 54.3773, 50000, 'silver', 'asia', 'Abu Dhabi', 'United Arab Emirates'),

-- ══════════════════════════════════════════════════
-- SOUTH AMERICAN COUNTRIES
-- ══════════════════════════════════════════════════
('south-america-brazil', 'Brazil', 'Dance samba in Rio and explore the Amazon rainforest', -15.7975, -47.8919, 50000, 'silver', 'south-america', 'Brasilia', 'Brazil'),
('south-america-argentina', 'Argentina', 'Tango in Buenos Aires and gaze at glaciers in Patagonia', -34.6037, -58.3816, 50000, 'silver', 'south-america', 'Buenos Aires', 'Argentina'),
('south-america-colombia', 'Colombia', 'Explore the colorful streets of Bogota and Cartagena', 4.7110, -74.0721, 50000, 'silver', 'south-america', 'Bogota', 'Colombia'),
('south-america-peru', 'Peru', 'Trek to Machu Picchu and explore Lima''s culinary scene', -12.0464, -77.0428, 50000, 'silver', 'south-america', 'Lima', 'Peru'),
('south-america-chile', 'Chile', 'From the Atacama Desert to Patagonia, explore Chile''s extremes', -33.4489, -70.6693, 50000, 'silver', 'south-america', 'Santiago', 'Chile'),
('south-america-ecuador', 'Ecuador', 'Straddle the equator in Quito and visit the Galapagos Islands', -0.1807, -78.4678, 50000, 'silver', 'south-america', 'Quito', 'Ecuador'),
('south-america-uruguay', 'Uruguay', 'Relax on the beaches of Montevideo and Punta del Este', -34.9011, -56.1645, 50000, 'silver', 'south-america', 'Montevideo', 'Uruguay'),
('south-america-bolivia', 'Bolivia', 'Walk across the mirror-like Salar de Uyuni salt flats', -16.4897, -68.1193, 50000, 'silver', 'south-america', 'La Paz', 'Bolivia'),

-- ══════════════════════════════════════════════════
-- OCEANIA
-- ══════════════════════════════════════════════════
('oceania-australia', 'Australia', 'Explore the Sydney Opera House and the Great Barrier Reef', -33.8688, 151.2093, 50000, 'silver', 'oceania', 'Sydney', 'Australia'),
('oceania-new-zealand', 'New Zealand', 'Discover Middle-earth landscapes from Auckland to Queenstown', -41.2865, 174.7762, 50000, 'silver', 'oceania', 'Wellington', 'New Zealand'),
('oceania-fiji', 'Fiji', 'Relax in paradise on the pristine islands of Fiji', -18.1416, 178.4419, 50000, 'silver', 'oceania', 'Suva', 'Fiji'),
('oceania-tahiti', 'French Polynesia', 'Swim in the turquoise lagoons of Tahiti and Bora Bora', -17.5516, -149.5585, 50000, 'silver', 'oceania', 'Papeete', 'French Polynesia'),
('oceania-papua-new-guinea', 'Papua New Guinea', 'Explore one of the most culturally diverse places on Earth', -6.3149, 143.9556, 50000, 'silver', 'oceania', 'Port Moresby', 'Papua New Guinea')

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

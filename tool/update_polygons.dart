/// One-off script: updates claim_polygon + pin (centroid) for specific
/// achievement IDs. Used for hand-drawn continent polygons that aren't
/// derived from the Natural Earth country import.
library;

import 'dart:convert';
import 'dart:io';

List<double> _centroid(List<List<double>> ring) {
  var sumLat = 0.0, sumLng = 0.0;
  for (final p in ring) {
    sumLat += p[0];
    sumLng += p[1];
  }
  return [sumLat / ring.length, sumLng / ring.length];
}

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (url == null || key == null) {
    stderr.writeln('Error: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
    exit(1);
  }

  final polygons = <String, List<List<double>>>{
    'continent-africa': [
      [35.9, -5.6], [37.3, 9.9], [32.1, 22.5],
      [31.3, 32.3], [29.5, 34.9], [12.6, 43.5],
      [11.8, 51.3], [-1.0, 41.9], [-6.8, 39.3],
      [-15.0, 40.5], [-24.0, 35.5], [-28.5, 32.6],
      [-34.3, 22.0], [-34.0, 18.4], [-22.5, 14.5],
      [-15.8, 11.8], [-8.8, 13.2], [0.4, 9.4],
      [6.1, 1.2], [4.7, -2.8], [5.3, -9.0],
      [8.5, -13.2], [14.7, -17.5], [21.0, -16.0],
      [27.7, -12.9], [30.4, -9.8], [35.8, -5.9],
    ],
    'continent-asia': [
      [29.5, 34.9], [36.3, 36.2], [40.0, 27.0],
      [45.0, 30.0], [48.0, 40.0], [58.0, 58.0],
      [68.0, 66.0], [73.0, 80.0], [77.0, 105.0],
      [73.0, 140.0], [68.0, 170.0], [65.0, 178.0],
      [60.0, 170.0], [55.0, 162.0], [44.0, 145.0],
      [34.0, 135.0], [34.0, 127.0], [25.0, 122.0],
      [10.0, 109.0], [1.3, 104.0], [-8.5, 118.0],
      [5.5, 95.0], [21.0, 92.0], [6.0, 80.0],
      [8.3, 72.8], [23.5, 68.0], [25.0, 60.0],
      [16.8, 54.0], [13.0, 52.0], [12.6, 43.5],
      [28.0, 35.0],
    ],
    'continent-europe': [
      [36.0, -5.6], [38.7, -9.5], [43.1, -9.3],
      [48.3, -4.5], [51.5, -5.5], [51.5, -10.3],
      [58.0, -8.0], [62.0, 5.0], [69.0, 16.0],
      [71.2, 25.8], [69.8, 32.0], [66.0, 40.0],
      [66.0, 54.0], [67.0, 66.0], [55.0, 60.0],
      [50.0, 55.0], [46.0, 48.0], [43.0, 40.0],
      [41.0, 28.0], [35.5, 23.0], [37.0, 14.5],
      [38.9, 8.8], [36.0, -0.5],
    ],
    'zone-netanya': [
      [32.365, 34.830], [32.365, 34.850], [32.345, 34.868],
      [32.330, 34.880], [32.315, 34.885], [32.295, 34.880],
      [32.285, 34.865], [32.285, 34.845], [32.295, 34.838],
      [32.315, 34.835], [32.335, 34.830], [32.355, 34.828],
    ],
    // Sri Lanka - island outline, clockwise from Point Pedro (north tip)
    'asia-sri-lanka': [
      [9.85, 80.22],  // Point Pedro (north)
      [9.40, 80.55],
      [8.85, 81.10],  // Trincomalee
      [8.00, 81.55],
      [7.20, 81.85],  // East coast / Arugam Bay
      [6.40, 81.70],  // SE / Yala
      [5.90, 81.00],  // South coast
      [5.85, 80.40],  // Dondra / Matara
      [6.05, 80.05],  // Galle
      [6.80, 79.75],  // Colombo / West
      [7.50, 79.70],  // Negombo
      [8.20, 79.65],  // Puttalam
      [8.80, 79.75],  // Kalpitiya
      [9.10, 79.90],  // Mannar
      [9.70, 79.90],  // Jaffna NW
    ],
    // Continent: Americas (North + Central America), clockwise from N Alaska
    'continent-americas': [
      [71.0, -156.0],   // Utqiagvik / NW Alaska
      [73.0, -100.0],   // Arctic Canada N
      [66.0, -80.0],    // Hudson Bay N
      [60.0, -64.0],    // Labrador
      [47.0, -52.0],    // Newfoundland
      [45.0, -67.0],    // Maine
      [40.0, -74.0],    // NYC
      [32.0, -80.0],    // Charleston / Carolinas
      [25.5, -80.0],    // Florida tip
      [18.5, -88.0],    // Yucatan
      [9.0, -78.0],     // Panama / Darien
      [16.0, -95.0],    // Mexico Pacific
      [20.0, -106.0],   // Puerto Vallarta
      [23.0, -110.0],   // Baja S
      [32.0, -117.0],   // Tijuana / San Diego
      [40.0, -124.0],   // N California coast
      [48.0, -125.0],   // Olympic Peninsula
      [55.0, -133.0],   // Alaska SE panhandle
      [60.0, -145.0],   // Alaska Gulf
      [63.0, -166.0],   // Alaska west
      [66.0, -168.0],   // Bering Strait
    ],
    // Continent: South America, clockwise from Colombia N coast
    'continent-south-america': [
      [12.5, -72.0],    // Colombia N / Venezuela border
      [11.0, -62.0],    // Venezuela coast
      [5.5, -52.0],     // French Guiana
      [-1.0, -44.0],    // Brazil N (Belem)
      [-6.0, -35.0],    // Brazil NE tip (Recife)
      [-13.0, -38.5],   // Salvador
      [-23.0, -42.0],   // Rio
      [-30.5, -50.0],   // Porto Alegre
      [-34.5, -54.0],   // Uruguay coast
      [-42.0, -64.0],   // Argentina E
      [-52.0, -68.0],   // Tierra del Fuego E
      [-55.0, -66.5],   // Cape Horn
      [-54.0, -73.0],   // Chile S
      [-46.0, -75.5],   // Chile patagonia
      [-37.0, -73.5],   // Concepción
      [-27.0, -71.0],   // Antofagasta
      [-18.0, -71.0],   // Arica
      [-5.0, -81.5],    // Peru N coast
      [1.0, -79.0],     // Ecuador / Colombia border
      [8.0, -77.0],     // Panama border
    ],
    // Continent: Oceania (Australia + NZ + PNG + Fiji), clockwise from NW Aus
    'continent-oceania': [
      [-8.0, 132.0],    // Arafura / Timor
      [-3.5, 140.0],    // PNG N
      [-5.0, 153.0],    // New Britain / Bismarck
      [-10.0, 166.0],   // Solomon Is.
      [-17.5, 179.0],   // Fiji
      [-22.5, 167.0],   // New Caledonia
      [-30.0, 175.0],   // Tasman Sea
      [-37.0, 179.0],   // NZ North Island E
      [-47.5, 170.0],   // NZ South Island S
      [-44.0, 146.0],   // Tasmania S
      [-38.0, 140.0],   // Australia SE
      [-35.0, 118.0],   // Australia SW (Albany)
      [-22.0, 113.0],   // Australia W (Exmouth)
      [-14.0, 123.0],   // Kimberley
      [-11.0, 130.0],   // Darwin
    ],
  };

  final client = HttpClient();
  for (final entry in polygons.entries) {
    final id = entry.key;
    final polygon = entry.value;
    final center = _centroid(polygon);
    final uri = Uri.parse('$url/rest/v1/achievement_definitions?id=eq.$id');
    final request = await client.patchUrl(uri);
    request.headers.set('apikey', key);
    request.headers.set('Authorization', 'Bearer $key');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Prefer', 'return=minimal');
    request.write(jsonEncode({
      'claim_polygon': polygon,
      'latitude': center[0],
      'longitude': center[1],
    }));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('OK  $id (${polygon.length} verts, pin @ '
          '${center[0].toStringAsFixed(2)}, ${center[1].toStringAsFixed(2)})');
    } else {
      stderr.writeln('FAIL $id (${response.statusCode}): $body');
    }
  }
  client.close();
  exit(0);
}

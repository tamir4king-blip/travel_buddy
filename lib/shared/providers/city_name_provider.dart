import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';

class CityNameNotifier extends StateNotifier<String?> {
  final Ref ref;
  double? _lastLat;
  double? _lastLng;

  CityNameNotifier(this.ref) : super(null) {
    ref.listen<GeolocationState>(geolocationProvider, (_, geo) {
      _onLocationChanged(geo);
    });
    // Check current location immediately
    final geo = ref.read(geolocationProvider);
    _onLocationChanged(geo);
  }

  Future<void> _onLocationChanged(GeolocationState geo) async {
    if (!geo.hasLocation) return;

    final lat = geo.latitude!;
    final lng = geo.longitude!;

    // Only re-fetch if user moved > 5 km from last geocoded position
    if (_lastLat != null && _lastLng != null) {
      final distance = Geolocator.distanceBetween(_lastLat!, _lastLng!, lat, lng);
      if (distance < 5000) return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
        if (city != null && city.isNotEmpty) {
          _lastLat = lat;
          _lastLng = lng;
          state = city;
        }
      }
    } catch (e, st) {
      // Geocoding failed — keep existing city name or null
      logError(e, st, context: 'cityName.geocode');
    }
  }
}

final cityNameProvider = StateNotifierProvider<CityNameNotifier, String?>(
  (ref) => CityNameNotifier(ref),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';

class ZoneState {
  final String? country;
  final String? city;
  final String? isoCountryCode;

  const ZoneState({this.country, this.city, this.isoCountryCode});

  bool get hasZone => country != null || city != null;

  String get displayLabel {
    if (city != null && country != null) return '$city, $country';
    return city ?? country ?? '';
  }
}

class ZoneNotifier extends StateNotifier<ZoneState> {
  final Ref ref;
  double? _lastLat;
  double? _lastLng;

  ZoneNotifier(this.ref) : super(const ZoneState()) {
    ref.listen<GeolocationState>(geolocationProvider, (_, geo) {
      _onLocationChanged(geo);
    });
    final geo = ref.read(geolocationProvider);
    _onLocationChanged(geo);
  }

  /// Force re-fetch zone data, bypassing the 5km cache.
  Future<void> forceRefresh() async {
    _lastLat = null;
    _lastLng = null;
    final geo = ref.read(geolocationProvider);
    await _onLocationChanged(geo);
  }

  Future<void> _onLocationChanged(GeolocationState geo) async {
    if (!geo.hasLocation) return;

    final lat = geo.latitude!;
    final lng = geo.longitude!;

    // Only re-fetch if user moved > 5 km
    if (_lastLat != null && _lastLng != null) {
      final distance =
          Geolocator.distanceBetween(_lastLat!, _lastLng!, lat, lng);
      if (distance < 5000) return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea;
        _lastLat = lat;
        _lastLng = lng;
        state = ZoneState(
          country: place.country,
          city: city,
          isoCountryCode: place.isoCountryCode,
        );
      }
    } catch (e, st) {
      // Geocoding failed — keep existing state
      logError(e, st, context: 'zone.geocode');
    }
  }
}

final zoneProvider = StateNotifierProvider<ZoneNotifier, ZoneState>(
  (ref) => ZoneNotifier(ref),
);

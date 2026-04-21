import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeoPointData {
  final double latitude;
  final double longitude;
  final String? address;

  const GeoPointData({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class LocationService {
  Future<void> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permission de localisation refusee');
    }
  }

  Future<GeoPointData> getCurrentLocationWithAddress() async {
    await ensurePermission();
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String? address;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address = [
          place.street,
          place.subLocality,
          place.locality,
          place.country,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).join(', ');
      }
    } catch (_) {
      address = null;
    }

    return GeoPointData(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  Future<GeoPointData?> geocodeAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return null;
      final first = locations.first;
      return GeoPointData(
        latitude: first.latitude,
        longitude: first.longitude,
        address: query,
      );
    } catch (_) {
      return null;
    }
  }

  String buildDirectionsUrl({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return 'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=$fromLat%2C$fromLng%3B$toLat%2C$toLng';
  }

  String buildPointUrl({
    required double lat,
    required double lng,
    int zoom = 16,
  }) {
    return 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=$zoom/$lat/$lng';
  }
}

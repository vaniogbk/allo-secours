import 'package:url_launcher/url_launcher.dart';
import 'location_service.dart';

class MapLauncherService {
  static final _locationService = LocationService();

  static Future<void> openPoint({
    required double latitude,
    required double longitude,
  }) async {
    final url = _locationService.buildPointUrl(
      lat: latitude,
      lng: longitude,
    );
    await _launch(url);
  }

  static Future<void> openDirections({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final url = _locationService.buildDirectionsUrl(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    await _launch(url);
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Impossible d\'ouvrir la carte');
    }
  }
}

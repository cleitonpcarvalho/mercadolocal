import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  static Future<bool> requestPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final bool granted = await requestPermission();
    if (!granted) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Stream<Position> startLocationStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }
}

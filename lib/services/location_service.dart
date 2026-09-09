import 'package:geolocator/geolocator.dart';

/// GPS Location Metadata Bundle
class GpsLocationResult {
  final bool isAvailable;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String timestampUtc;
  final String provider;
  final String? notice;

  const GpsLocationResult({
    required this.isAvailable,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestampUtc,
    this.provider = 'FUSED_GPS_HARDWARE',
    this.notice,
  });

  Map<String, dynamic> toMap() {
    return {
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      'timestampUtc': timestampUtc,
      'provider': provider,
      'notice': notice,
    };
  }
}

/// NEXORA Automatic GPS & Geofencing Location Service
/// Hardened against manual officer tampering. Captures high-accuracy hardware coordinates.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  bool _mockGpsUnavailable = false;

  void setMockGpsUnavailable(bool value) {
    _mockGpsUnavailable = value;
  }

  /// Automatically captures device GPS hardware coordinates and UTC timestamp
  Future<GpsLocationResult> getCurrentLocation({
    double defaultLat = 13.0827,
    double defaultLng = 80.2707,
  }) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    if (_mockGpsUnavailable) {
      return GpsLocationResult(
        isAvailable: false,
        latitude: 0.0,
        longitude: 0.0,
        accuracyMeters: 999.9,
        timestampUtc: nowUtc,
        provider: 'GPS_HARDWARE_UNAVAILABLE',
        notice: 'GPS unavailable — recorded under emergency field policy with zeroed coordinates.',
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _unavailable(nowUtc, 'Device location services are turned off.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _unavailable(nowUtc, 'Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      return GpsLocationResult(
        isAvailable: true,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        timestampUtc: position.timestamp.toUtc().toIso8601String(),
        provider: 'NATIVE_FUSED_LOCATION_PROVIDER',
      );
    } catch (error) {
      return _unavailable(nowUtc, 'GPS could not be read: $error');
    }
  }

  GpsLocationResult _unavailable(String timestampUtc, String notice) {
    return GpsLocationResult(
      isAvailable: false,
      latitude: 0.0,
      longitude: 0.0,
      accuracyMeters: 999.9,
      timestampUtc: timestampUtc,
      provider: 'GPS_HARDWARE_UNAVAILABLE',
      notice: notice,
    );
  }
}

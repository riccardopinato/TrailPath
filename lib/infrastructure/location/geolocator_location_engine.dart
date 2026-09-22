import 'package:geolocator/geolocator.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class GeolocatorLocationEngine implements LocationEngine {
  const GeolocatorLocationEngine();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<PositionSample?> current() async {
    if (!await isServiceEnabled() || !await hasPermission()) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return _toSample(position);
  }

  @override
  Stream<PositionSample> watch({
    BatteryMode mode = BatteryMode.balanced,
  }) {
    final policy = batteryModePolicy(mode);
    final settings = LocationSettings(
      accuracy: _accuracy(policy.accuracy),
      distanceFilter: policy.distanceFilterMeters,
    );
    return Geolocator.getPositionStream(locationSettings: settings)
        .map(_toSample);
  }

  LocationAccuracy _accuracy(GpsAccuracyPreset preset) {
    return switch (preset) {
      GpsAccuracyPreset.navigation => LocationAccuracy.bestForNavigation,
      GpsAccuracyPreset.high => LocationAccuracy.high,
      GpsAccuracyPreset.medium => LocationAccuracy.medium,
    };
  }

  PositionSample _toSample(Position position) {
    return PositionSample(
      point: GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        elevationMeters: position.altitude,
        timestamp: position.timestamp,
      ),
      accuracyMeters: position.accuracy,
      speedMetersPerSecond: position.speed.isFinite && position.speed >= 0
          ? position.speed
          : null,
      headingDegrees: position.heading.isFinite && position.heading >= 0
          ? position.heading
          : null,
    );
  }
}

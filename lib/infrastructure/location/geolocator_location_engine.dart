import 'package:geolocator/geolocator.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class GeolocatorLocationEngine implements LocationEngine {
  const GeolocatorLocationEngine();

  static const LocationSettings _currentSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 12),
  );

  static const LocationSettings _streamSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 3,
  );

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionState> permissionStatus() async {
    return _mapPermission(await Geolocator.checkPermission());
  }

  @override
  Future<LocationPermissionState> requestPermission() async {
    return _mapPermission(await Geolocator.requestPermission());
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Stream<bool> serviceStatus() {
    return Geolocator.getServiceStatusStream()
        .map((status) => status == ServiceStatus.enabled)
        .distinct();
  }

  @override
  Future<PositionSample?> current() async {
    if (!await isServiceEnabled()) {
      return null;
    }

    final permission = await permissionStatus();
    if (!permission.isGranted) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: _currentSettings,
    );
    return _toSample(position);
  }

  @override
  Stream<PositionSample> watch() {
    return Geolocator.getPositionStream(
      locationSettings: _streamSettings,
    ).map(_toSample);
  }

  static PositionSample _toSample(Position position) {
    final heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : null;
    final speed = position.speed.isFinite && position.speed >= 0
        ? position.speed
        : null;

    return PositionSample(
      point: GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        elevationMeters: position.altitude.isFinite ? position.altitude : null,
        timestamp: position.timestamp,
      ),
      accuracyMeters: position.accuracy.isFinite ? position.accuracy : 0,
      speedMetersPerSecond: speed,
      headingDegrees: heading,
    );
  }

  static LocationPermissionState _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always => LocationPermissionState.always,
      LocationPermission.whileInUse => LocationPermissionState.whileInUse,
      LocationPermission.deniedForever => LocationPermissionState.deniedForever,
      LocationPermission.denied => LocationPermissionState.denied,
      LocationPermission.unableToDetermine =>
        LocationPermissionState.unavailable,
    };
  }
}

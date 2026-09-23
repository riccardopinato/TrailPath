import 'package:flutter/foundation.dart';
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
    bool keepAliveInBackground = false,
  }) {
    final policy = batteryModePolicy(mode);
    return Geolocator.getPositionStream(
      locationSettings: _watchSettings(
        policy,
        keepAliveInBackground: keepAliveInBackground,
      ),
    ).map(_toSample);
  }

  LocationSettings _watchSettings(
    BatteryModePolicy policy, {
    required bool keepAliveInBackground,
  }) {
    final accuracy = _accuracy(policy.accuracy);

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: policy.distanceFilterMeters,
        intervalDuration: policy.interval,
        foregroundNotificationConfig: keepAliveInBackground
            ? ForegroundNotificationConfig(
                notificationTitle: 'TrailPath · navigazione attiva',
                notificationText:
                    'La navigazione GPS continua anche con TrailPath in background.',
                enableWakeLock: policy.keepCpuAwake,
                setOngoing: true,
              )
            : null,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: policy.distanceFilterMeters,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: !keepAliveInBackground,
        showBackgroundLocationIndicator: keepAliveInBackground,
        allowBackgroundLocationUpdates: keepAliveInBackground,
      );
    }

    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: policy.distanceFilterMeters,
    );
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

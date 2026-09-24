enum BatteryMode { performance, balanced, saver }

enum GpsAccuracyPreset { navigation, high, medium }

class BatteryModePolicy {
  const BatteryModePolicy({
    required this.mode,
    required this.accuracy,
    required this.distanceFilterMeters,
    required this.interval,
    required this.maxAcceptedAccuracyMeters,
    required this.minimumSegmentMeters,
    required this.keepCpuAwake,
  });

  final BatteryMode mode;
  final GpsAccuracyPreset accuracy;
  final int distanceFilterMeters;
  final Duration interval;
  final double maxAcceptedAccuracyMeters;
  final double minimumSegmentMeters;
  final bool keepCpuAwake;
}

BatteryModePolicy batteryModePolicy(BatteryMode mode) {
  return switch (mode) {
    BatteryMode.performance => const BatteryModePolicy(
      mode: BatteryMode.performance,
      accuracy: GpsAccuracyPreset.navigation,
      distanceFilterMeters: 3,
      interval: Duration(seconds: 3),
      maxAcceptedAccuracyMeters: 40,
      minimumSegmentMeters: 2,
      keepCpuAwake: true,
    ),
    BatteryMode.balanced => const BatteryModePolicy(
      mode: BatteryMode.balanced,
      accuracy: GpsAccuracyPreset.high,
      distanceFilterMeters: 7,
      interval: Duration(seconds: 6),
      maxAcceptedAccuracyMeters: 55,
      minimumSegmentMeters: 4,
      keepCpuAwake: true,
    ),
    BatteryMode.saver => const BatteryModePolicy(
      mode: BatteryMode.saver,
      accuracy: GpsAccuracyPreset.medium,
      distanceFilterMeters: 15,
      interval: Duration(seconds: 12),
      maxAcceptedAccuracyMeters: 80,
      minimumSegmentMeters: 8,
      keepCpuAwake: false,
    ),
  };
}

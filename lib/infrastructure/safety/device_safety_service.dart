import 'package:battery_plus/battery_plus.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class DeviceSafetyService implements SafetyService {
  DeviceSafetyService({
    required this.locationEngine,
    required this.offlineMapManager,
    Battery? battery,
  }) : _battery = battery ?? Battery();

  final LocationEngine locationEngine;
  final OfflineMapManager offlineMapManager;
  final Battery _battery;

  @override
  Future<SafetySnapshot> inspect() async {
    final batteryLevel = await _safeBatteryLevel();
    final powerSaveMode = await _safePowerSaveMode();
    final serviceEnabled = await _safeLocationServiceEnabled();
    final hasPermission = await _safeLocationPermission();
    final offlineAvailable = await _safeOfflineMapAvailability();

    return SafetySnapshot(
      batteryPercent: batteryLevel,
      hasLocationPermission: hasPermission,
      locationServiceEnabled: serviceEnabled,
      isOfflineMapAvailable: offlineAvailable,
      isPowerSaveMode: powerSaveMode,
    );
  }

  Future<bool> _safeLocationServiceEnabled() async {
    try {
      return await locationEngine.isServiceEnabled();
    } on Object {
      return false;
    }
  }

  Future<bool> _safeLocationPermission() async {
    try {
      return await locationEngine.hasPermission();
    } on Object {
      return false;
    }
  }

  Future<bool> _safeOfflineMapAvailability() async {
    try {
      final regions = await offlineMapManager.listRegions();
      return regions.any((region) => region.isComplete);
    } on Object {
      return false;
    }
  }

  Future<int> _safeBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } on Object {
      return -1;
    }
  }

  Future<bool> _safePowerSaveMode() async {
    try {
      return await _battery.isInBatterySaveMode;
    } on Object {
      return false;
    }
  }
}

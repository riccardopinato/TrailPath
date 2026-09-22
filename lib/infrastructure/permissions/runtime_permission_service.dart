import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class RuntimePermissionService {
  const RuntimePermissionService();

  Future<void> prepareRecording() async {
    if (!Platform.isAndroid) {
      return;
    }

    final notification = await Permission.notification.status;
    if (notification.isDenied) {
      await Permission.notification.request();
    }

    var foregroundLocation = await Permission.locationWhenInUse.status;
    if (!foregroundLocation.isGranted) {
      foregroundLocation = await Permission.locationWhenInUse.request();
    }
    if (!foregroundLocation.isGranted) {
      throw const RecordingPermissionException(
        'Location permission is required to record an activity.',
      );
    }

    // Android 10+ can restrict location once the app leaves the foreground.
    // Ask for background access after foreground access has been granted, but
    // do not block recording when the user prefers foreground-only tracking.
    var backgroundLocation = await Permission.locationAlways.status;
    if (backgroundLocation.isDenied) {
      backgroundLocation = await Permission.locationAlways.request();
    }
  }

  Future<bool> openSettings() => openAppSettings();
}

class RecordingPermissionException implements Exception {
  const RecordingPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

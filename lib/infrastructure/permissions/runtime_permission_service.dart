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

    var location = await Permission.locationWhenInUse.status;
    if (location.isDenied) {
      location = await Permission.locationWhenInUse.request();
    }

    if (!location.isGranted) {
      if (location.isPermanentlyDenied) {
        throw const RecordingPermissionException(
          'Location permission is permanently denied. Open Android app settings and enable location for TrailPath.',
        );
      }
      throw const RecordingPermissionException(
        'Location permission is required to record a trail.',
      );
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

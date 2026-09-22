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

    final location = await Permission.locationWhenInUse.status;
    if (!location.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  Future<bool> openSettings() => openAppSettings();
}

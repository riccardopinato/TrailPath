import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android permission contract is explicit and request-driven', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final permissions = File(
      'lib/infrastructure/permissions/runtime_permission_service.dart',
    ).readAsStringSync();

    expect(pubspec, contains('permission_handler: ^13.0.2'));
    expect(gradle, contains('compileSdk = 37'));
    expect(gradle, contains('targetSdk = flutter.targetSdkVersion'));

    expect(manifest, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(manifest, contains('android.permission.ACCESS_COARSE_LOCATION'));
    expect(
      manifest,
      contains('android.permission.FOREGROUND_SERVICE_LOCATION'),
    );
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));

    expect(
      permissions,
      contains('location = await Permission.locationWhenInUse.request()'),
    );
    expect(permissions, contains('location.isPermanentlyDenied'));
    expect(permissions, contains('Permission.notification.request()'));
  });
}

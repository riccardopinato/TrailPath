import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/config/production_services_config.dart';

void main() {
  test('release readiness requires all four external production services', () {
    const ready = ProductionServicesSnapshot(
      googleSignIn: true,
      premiumMaps: true,
      cloudSync: true,
      purchaseVerification: true,
    );
    expect(ready.isReleaseReady, isTrue);
    expect(ready.missingServices, isEmpty);

    const partial = ProductionServicesSnapshot(
      googleSignIn: false,
      premiumMaps: true,
      cloudSync: false,
      purchaseVerification: false,
    );
    expect(partial.isReleaseReady, isFalse);
    expect(
      partial.missingServices,
      containsAll([
        'Google Sign-In',
        'Supabase Cloud Sync',
        'Play purchase server verification',
      ]),
    );
  });
}

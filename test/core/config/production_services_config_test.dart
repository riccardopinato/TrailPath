import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/config/production_services_config.dart';

void main() {
  test('release readiness requires all five external production services', () {
    const ready = ProductionServicesSnapshot(
      googleSignIn: true,
      premiumMaps: true,
      routingProvider: true,
      cloudSync: true,
      purchaseVerification: true,
    );
    expect(ready.isReleaseReady, isTrue);
    expect(ready.missingServices, isEmpty);

    const partial = ProductionServicesSnapshot(
      googleSignIn: false,
      premiumMaps: true,
      routingProvider: false,
      cloudSync: false,
      purchaseVerification: false,
    );
    expect(partial.isReleaseReady, isFalse);
    expect(
      partial.missingServices,
      containsAll([
        'Google Sign-In',
        'Dedicated Valhalla routing',
        'Supabase Cloud Sync',
        'Play purchase server verification',
      ]),
    );
  });
}

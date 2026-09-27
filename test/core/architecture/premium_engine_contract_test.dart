import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.2 Premium Engine is wired into paid map layers', () {
    final planner = File(
      'lib/features/planner/presentation/planner_screen.dart',
    ).readAsStringSync();
    final billing = File(
      'lib/infrastructure/premium/play_billing_premium_engine.dart',
    ).readAsStringSync();

    expect(planner, contains('premiumControllerProvider'));
    expect(planner, contains('showTrailPathProPaywall'));
    expect(planner, contains('style.isPremium && !premium.isPro'));
    expect(billing, contains('trailpath_pro_monthly'));
    expect(billing, contains('trailpath_pro_yearly'));
    expect(billing, contains('completePurchase'));
    expect(billing, contains('restorePurchases'));
  });
}

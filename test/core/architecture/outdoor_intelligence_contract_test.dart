import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.5 outdoor intelligence contract is fully wired', () {
    final planner = File(
      'lib/features/planner/presentation/planner_screen.dart',
    ).readAsStringSync();
    final navigation = File(
      'lib/features/navigation/application/active_navigation_controller.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/profile/presentation/profile_screen.dart',
    ).readAsStringSync();
    final outdoor = File(
      'lib/infrastructure/outdoor/openstreetmap_outdoor_context_service.dart',
    ).readAsStringSync();
    final routeLab = File(
      'lib/features/routes/presentation/route_intelligence_screen.dart',
    ).readAsStringSync();

    expect(planner, contains('_toggleSlopeLayer'));
    expect(planner, contains('_toggleTerrain3d'));
    expect(planner, contains('RasterDemSourceProperties'));
    expect(planner, contains("'kind': 'slope'"));
    expect(navigation, contains('_maybeAutoReroute'));
    expect(navigation, contains('preferences.autoReroute'));
    expect(profile, contains('RouteIntelligenceScreen'));
    expect(profile, contains('RouteCollectionsScreen'));
    expect(profile, contains('PersonalStatsScreen'));
    expect(routeLab, contains('generateCircularRoutes'));
    expect(routeLab, contains('generateAlternatives'));
    expect(routeLab, contains('AlternativeRoutePreference.moreTrail'));
    expect(routeLab, contains('AlternativeRoutePreference.moreRoad'));
    expect(outdoor, contains('poisAlongRoute'));
    expect(outdoor, contains('weatherAlongRoute'));
    expect(outdoor, contains('surfaceSummary'));
  });
}

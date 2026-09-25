import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web Preview is wired to the shared planner core', () {
    final webPreview = File('lib/web_preview.dart').readAsStringSync();
    final plannerController = File(
      'lib/features/planner/application/route_planner_controller.dart',
    ).readAsStringSync();
    final plannerProviders = File(
      'lib/core/services/planner_service_providers.dart',
    ).readAsStringSync();

    expect(
      webPreview,
      contains(
        "package:trail_path/features/planner/application/"
        "route_planner_controller.dart",
      ),
    );
    expect(webPreview, contains('ref.watch(routePlannerProvider)'));
    expect(webPreview, contains('routePlannerProvider.notifier'));
    expect(webPreview, contains('placeSearchServiceProvider'));
    expect(webPreview, contains('insertPointNearRoute'));
    expect(webPreview, contains('movePoint(index, pointValue)'));
    expect(webPreview, contains('insertPointAt(insertedIndex, pointValue)'));
    expect(webPreview, contains('addTrace'));
    expect(webPreview, contains('sampleEvenly'));

    expect(
      webPreview,
      isNot(contains('OpenStreetMapRoutingEngine')),
      reason: 'Web must not own a parallel routing implementation.',
    );
    expect(
      webPreview,
      isNot(contains('List<GeoPoint> _points')),
      reason: 'Web planner state must come from RoutePlannerController.',
    );

    expect(
      plannerController,
      contains(
        "package:trail_path/core/services/planner_service_providers.dart",
      ),
    );
    expect(
      plannerController,
      isNot(
        contains("package:trail_path/core/services/service_providers.dart"),
      ),
      reason: 'Planner core must not depend on platform-only provider graph.',
    );

    expect(plannerProviders, contains('routingEngineProvider'));
    expect(plannerProviders, contains('elevationEngineProvider'));
    expect(plannerProviders, contains('placeSearchServiceProvider'));
    expect(
      plannerProviders,
      isNot(contains('dart:io')),
      reason: 'Shared planner providers must remain Web-safe.',
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Smart Trace and map layer v1.1 contract is wired', () {
    final planner = File(
      'lib/features/planner/presentation/planner_screen.dart',
    ).readAsStringSync();
    final providers = File('lib/core/services/planner_service_providers.dart')
        .readAsStringSync();

    expect(planner, contains('MapMatchMode _traceMatchMode'));
    expect(planner, contains('mapMatchingEngineProvider'));
    expect(planner, contains('applyMatchedTrace(match)'));
    expect(planner, contains('View.of(context).devicePixelRatio'));
    expect(providers, contains('QualityRoutingEngine'));
    expect(planner, contains('_mapViewportKey'));
    expect(planner, contains('globalToLocal(event.position)'));
    expect(planner, contains('controller.setStyle(url)'));
    expect(planner, contains('_PlannerMapStyle.satellite'));
    expect(planner, contains('_PlannerMapStyle.hybrid'));
    expect(planner, contains('Platform.isAndroid || Platform.isIOS'));
    expect(planner, contains('await controller.setTerrain(null)'));
    expect(providers, contains('ValhallaMapMatchingEngine'));
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/planner/application/route_planner_controller.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';

void main() {
  ProviderContainer containerWith(RoutingEngine engine) {
    return ProviderContainer(
      overrides: [
        routingEngineProvider.overrideWithValue(engine),
      ],
    );
  }

  test('route planner calculates distance and supports undo/redo', () async {
    final container = containerWith(const StraightLineRoutingEngine());
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);

    controller.addPoint(
      const GeoPoint(latitude: 45.0, longitude: 11.0),
    );
    controller.addPoint(
      const GeoPoint(latitude: 45.0, longitude: 11.01),
    );
    await Future<void>.delayed(Duration.zero);

    var state = container.read(routePlannerProvider);
    expect(state.points, hasLength(2));
    expect(state.geometry, hasLength(2));
    expect(state.distanceMeters, greaterThan(700));
    expect(state.distanceMeters, lessThan(900));
    expect(state.canUndo, isTrue);
    expect(state.canRedo, isFalse);
    expect(state.estimatedDuration, isNot(Duration.zero));
    expect(state.isRouting, isFalse);
    expect(state.isSnapped, isFalse);

    controller.undo();
    await Future<void>.delayed(Duration.zero);
    state = container.read(routePlannerProvider);
    expect(state.points, hasLength(1));
    expect(state.canRedo, isTrue);

    controller.redo();
    await Future<void>.delayed(Duration.zero);
    state = container.read(routePlannerProvider);
    expect(state.points, hasLength(2));
  });

  test('changing route profile recalculates estimated duration', () async {
    final container = containerWith(const StraightLineRoutingEngine());
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.0, longitude: 11.0))
      ..addPoint(const GeoPoint(latitude: 45.0, longitude: 11.05));
    await Future<void>.delayed(Duration.zero);

    final hikingDuration =
        container.read(routePlannerProvider).estimatedDuration;

    controller.setProfile(RouteProfile.cycling);
    await Future<void>.delayed(Duration.zero);
    final cyclingDuration =
        container.read(routePlannerProvider).estimatedDuration;

    expect(cyclingDuration, lessThan(hikingDuration));
  });

  test('planner replaces direct line with snapped geometry', () async {
    final container = containerWith(const _SnappedRoutingEngine());
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.0, longitude: 11.0))
      ..addPoint(const GeoPoint(latitude: 45.01, longitude: 11.01));

    await Future<void>.delayed(Duration.zero);

    final state = container.read(routePlannerProvider);
    expect(state.isSnapped, isTrue);
    expect(state.geometry, hasLength(3));
    expect(state.distanceMeters, 1500);
    expect(state.routingSource, 'test-snap');
  });

  test('distance helper returns zero for fewer than two points', () {
    expect(calculateDistanceMeters(const []), 0);
    expect(
      calculateDistanceMeters(
        const [GeoPoint(latitude: 45.0, longitude: 11.0)],
      ),
      0,
    );
  });
}

class _SnappedRoutingEngine implements RoutingEngine {
  const _SnappedRoutingEngine();

  @override
  String get engineId => 'test-snap';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    return RoutePlan(
      geometry: const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.005, longitude: 11.003),
        GeoPoint(latitude: 45.01, longitude: 11.01),
      ],
      distanceMeters: 1500,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: const Duration(minutes: 20),
      profile: request.profile,
      isSnapped: true,
      routingSource: engineId,
    );
  }
}

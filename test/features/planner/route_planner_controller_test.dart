import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/elevation_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/planner/application/route_planner_controller.dart';
import 'package:trail_path/infrastructure/elevation/open_meteo_elevation_engine.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';

void main() {
  ProviderContainer containerWith(
    RoutingEngine engine, {
    ElevationEngine elevationEngine = const UnavailableElevationEngine(),
  }) {
    return ProviderContainer(
      overrides: [
        routingEngineProvider.overrideWithValue(engine),
        elevationEngineProvider.overrideWithValue(elevationEngine),
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
    final container = containerWith(
      const _SnappedRoutingEngine(),
      elevationEngine: const _FakeElevationEngine(),
    );
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
    expect(state.hasElevation, isTrue);
    expect(state.ascentMeters, 25);
    expect(state.descentMeters, 5);
  });

  test('routing failure is explicit and cannot be saved', () async {
    final container = containerWith(const _FailingRoutingEngine());
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.0, longitude: 11.0))
      ..addPoint(const GeoPoint(latitude: 45.01, longitude: 11.01));

    await Future<void>.delayed(Duration.zero);

    final state = container.read(routePlannerProvider);
    expect(state.isRouting, isFalse);
    expect(state.isSnapped, isFalse);
    expect(state.routingSource, 'routing-error');
    expect(state.routingError, isNotNull);
    expect(state.canSave, isFalse);
  });

  test('imports GPX geometry without rerouting and preserves elevation', () {
    final container = containerWith(const StraightLineRoutingEngine());
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller.importGpx(
      const GpxDocument(
        name: 'Imported trail',
        points: [
          GeoPoint(
            latitude: 45.0,
            longitude: 11.0,
            elevationMeters: 100,
          ),
          GeoPoint(
            latitude: 45.01,
            longitude: 11.01,
            elevationMeters: 130,
          ),
          GeoPoint(
            latitude: 45.02,
            longitude: 11.02,
            elevationMeters: 120,
          ),
        ],
      ),
    );

    final state = container.read(routePlannerProvider);
    expect(state.importedName, 'Imported trail');
    expect(state.geometry, hasLength(3));
    expect(state.points, hasLength(2));
    expect(state.routingSource, 'gpx');
    expect(state.hasElevation, isTrue);
    expect(state.ascentMeters, 30);
    expect(state.descentMeters, 10);

    final exported = controller.exportGpx('Exported trail');
    expect(exported.name, 'Exported trail');
    expect(exported.points, hasLength(3));
    expect(exported.points[1].elevationMeters, 130);
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


class _FakeElevationEngine implements ElevationEngine {
  const _FakeElevationEngine();

  @override
  String get engineId => 'test-elevation';

  @override
  Future<ElevationProfile> resolve(List<GeoPoint> points) async {
    final elevated = [
      points.first.copyWith(elevationMeters: 100),
      points[1].copyWith(elevationMeters: 125),
      points.last.copyWith(elevationMeters: 120),
    ];
    return buildElevationProfile(
      elevated,
      source: engineId,
      noiseThresholdMeters: 0,
    );
  }
}

class _FailingRoutingEngine implements RoutingEngine {
  const _FailingRoutingEngine();

  @override
  String get engineId => 'failing';

  @override
  Future<RoutePlan> calculate(RouteRequest request) {
    throw const RoutingException('routing unavailable');
  }
}

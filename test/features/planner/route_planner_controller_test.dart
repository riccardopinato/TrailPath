import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/elevation_math.dart';
import 'package:trail_path/core/domain/geo_math.dart';
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
    expect(state.editHandles, hasLength(1));
    expect(state.points.first.latitude, closeTo(45.0002, 0.000001));
    expect(state.points.last.longitude, closeTo(11.0098, 0.000001));
    expect(state.hasElevation, isTrue);
    expect(state.ascentMeters, 25);
    expect(state.descentMeters, 5);
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

  test('routing failure never leaves a fake straight-line route', () async {
    final container = containerWith(const _FailingRoutingEngine());
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.0, longitude: 11.0))
      ..addPoint(const GeoPoint(latitude: 45.01, longitude: 11.01));

    await Future<void>.delayed(Duration.zero);

    final state = container.read(routePlannerProvider);
    expect(state.hasRoutingError, isTrue);
    expect(state.geometry, isEmpty);
    expect(state.distanceMeters, 0);
    expect(state.estimatedDuration, Duration.zero);
    expect(state.isSnapped, isFalse);
    expect(state.canSave, isFalse);
    expect(state.routingSource, 'unavailable');
  });

  test('moving a waypoint reroutes only its neighboring span', () async {
    final engine = _RecordingSnappedRoutingEngine();
    final container = containerWith(engine);
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.00, longitude: 11.00))
      ..addPoint(const GeoPoint(latitude: 45.01, longitude: 11.01))
      ..addPoint(const GeoPoint(latitude: 45.02, longitude: 11.02))
      ..addPoint(const GeoPoint(latitude: 45.03, longitude: 11.03));
    await _flushAsync();

    expect(container.read(routePlannerProvider).isSnapped, isTrue);
    engine.requests.clear();

    controller.movePoint(
      1,
      const GeoPoint(latitude: 45.012, longitude: 11.008),
    );
    await _flushAsync();

    expect(engine.requests, hasLength(1));
    expect(engine.requests.single.points, hasLength(3));
    expect(container.read(routePlannerProvider).points, hasLength(4));
    expect(container.read(routePlannerProvider).editHandles, hasLength(3));
    expect(container.read(routePlannerProvider).canSave, isTrue);
  });

  test('inserting a point near the route reroutes only one old leg', () async {
    final engine = _RecordingSnappedRoutingEngine();
    final container = containerWith(engine);
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.00, longitude: 11.00))
      ..addPoint(const GeoPoint(latitude: 45.01, longitude: 11.01))
      ..addPoint(const GeoPoint(latitude: 45.02, longitude: 11.02));
    await _flushAsync();
    engine.requests.clear();

    controller.insertPointNearRoute(
      const GeoPoint(latitude: 45.005, longitude: 11.006),
    );
    await _flushAsync();

    expect(engine.requests, hasLength(1));
    expect(engine.requests.single.points, hasLength(3));
    expect(container.read(routePlannerProvider).points, hasLength(4));
    expect(container.read(routePlannerProvider).editHandles, hasLength(3));
    expect(container.read(routePlannerProvider).isSnapped, isTrue);
  });

  test('removing an endpoint reuses unaffected cached route legs', () async {
    final engine = _RecordingSnappedRoutingEngine();
    final container = containerWith(engine);
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.00, longitude: 11.00))
      ..addPoint(const GeoPoint(latitude: 45.01, longitude: 11.01))
      ..addPoint(const GeoPoint(latitude: 45.02, longitude: 11.02));
    await _flushAsync();
    engine.requests.clear();

    controller.removePoint(0);
    await _flushAsync();

    expect(engine.requests, isEmpty);
    expect(container.read(routePlannerProvider).points, hasLength(2));
    expect(container.read(routePlannerProvider).geometry.length, greaterThan(1));
    expect(container.read(routePlannerProvider).canUndo, isTrue);
  });

  test('trace becomes one undoable snapped planner operation', () async {
    final engine = _RecordingSnappedRoutingEngine();
    final container = containerWith(engine);
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    final accepted = controller.addTrace([
      for (var index = 0; index <= 30; index++)
        GeoPoint(
          latitude: 45.0 + index * 0.00002,
          longitude: 11.0 + index * 0.00008,
        ),
    ]);
    await _flushAsync();

    final routed = container.read(routePlannerProvider);
    expect(accepted, isTrue);
    expect(routed.isSnapped, isTrue);
    expect(routed.points.length, greaterThanOrEqualTo(2));
    expect(routed.points.length, lessThan(31));
    expect(routed.canUndo, isTrue);
    expect(engine.requests, hasLength(1));

    controller.undo();
    await _flushAsync();

    expect(container.read(routePlannerProvider).points, isEmpty);
  });

  test('trace extension reroutes only the appended span', () async {
    final engine = _RecordingSnappedRoutingEngine();
    final container = containerWith(engine);
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.0, longitude: 11.0))
      ..addPoint(const GeoPoint(latitude: 45.01, longitude: 11.01));
    await _flushAsync();
    final previous = container.read(routePlannerProvider).points;
    engine.requests.clear();

    final accepted = controller.addTrace([
      previous.last,
      const GeoPoint(latitude: 45.015, longitude: 11.016),
      const GeoPoint(latitude: 45.02, longitude: 11.022),
    ]);
    await _flushAsync();

    expect(accepted, isTrue);
    expect(engine.requests, hasLength(1));
    expect(engine.requests.single.points.first, previous.last);
    expect(container.read(routePlannerProvider).points.length, greaterThan(2));
    expect(container.read(routePlannerProvider).isSnapped, isTrue);
  });

  test('trace with fewer than two samples is rejected without history', () {
    final engine = _RecordingSnappedRoutingEngine();
    final container = containerWith(engine);
    addTearDown(container.dispose);

    final accepted = container.read(routePlannerProvider.notifier).addTrace(
      const [GeoPoint(latitude: 45.0, longitude: 11.0)],
    );

    expect(accepted, isFalse);
    expect(container.read(routePlannerProvider).points, isEmpty);
    expect(container.read(routePlannerProvider).canUndo, isFalse);
    expect(engine.requests, isEmpty);
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
      snappedWaypoints: const [
        GeoPoint(latitude: 45.0002, longitude: 11.0002),
        GeoPoint(latitude: 45.0098, longitude: 11.0098),
      ],
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
  String get engineId => 'test-failure';

  @override
  Future<RoutePlan> calculate(RouteRequest request) {
    throw const RoutingException('network unavailable');
  }
}


Future<void> _flushAsync() async {
  for (var index = 0; index < 5; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _RecordingSnappedRoutingEngine implements RoutingEngine {
  final List<RouteRequest> requests = [];

  @override
  String get engineId => 'recording-snap';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    requests.add(request);
    final geometry = <GeoPoint>[];
    for (var index = 0; index < request.points.length; index++) {
      final current = request.points[index];
      if (index == 0) {
        geometry.add(current);
        continue;
      }
      final previous = request.points[index - 1];
      geometry
        ..add(
          GeoPoint(
            latitude: (previous.latitude + current.latitude) / 2,
            longitude: (previous.longitude + current.longitude) / 2,
          ),
        )
        ..add(current);
    }

    final distance = calculateRouteDistanceMeters(geometry);
    return RoutePlan(
      geometry: List<GeoPoint>.unmodifiable(geometry),
      distanceMeters: distance,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: Duration(seconds: distance.round()),
      profile: request.profile,
      isSnapped: true,
      routingSource: engineId,
      snappedWaypoints: List<GeoPoint>.unmodifiable(request.points),
    );
  }
}

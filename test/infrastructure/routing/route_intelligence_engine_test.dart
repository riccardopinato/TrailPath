import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/route_intelligence.dart';
import 'package:trail_path/core/services/route_intelligence_service.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/routing/default_route_intelligence_engine.dart';

class _FakeRoutingEngine implements RoutingEngine {
  @override
  String get engineId => 'fake-routing';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    final geometry = List<GeoPoint>.unmodifiable(request.points);
    final distance = (geometry.length - 1) * 2500.0;
    return RoutePlan(
      geometry: geometry,
      distanceMeters: distance,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: Duration(seconds: (distance / 1.3).round()),
      profile: request.profile,
      isSnapped: true,
      routingSource: engineId,
      snappedWaypoints: geometry,
    );
  }
}

class _FakeElevationEngine implements ElevationEngine {
  @override
  String get engineId => 'fake-elevation';

  @override
  Future<ElevationProfile> resolve(List<GeoPoint> points) async {
    final enriched = <GeoPoint>[
      for (var i = 0; i < points.length; i++)
        points[i].copyWith(elevationMeters: 100 + i * 10),
    ];
    return ElevationProfile(
      points: enriched,
      samples: [
        for (var i = 0; i < enriched.length; i++)
          ElevationSample(
            point: enriched[i],
            distanceMeters: i * 1000,
            gradePercent: i == 0 ? 0 : 4,
          ),
      ],
      ascentMeters: enriched.length <= 1 ? 0 : (enriched.length - 1) * 10,
      descentMeters: 0,
      minElevationMeters: 100,
      maxElevationMeters: 100 + (enriched.length - 1) * 10,
      source: engineId,
    );
  }
}

class _FakeOutdoorContext implements OutdoorContextService {
  @override
  Future<List<OutdoorPoi>> poisAlongRoute(
    List<GeoPoint> geometry, {
    double corridorMeters = 800,
  }) async => const [];

  @override
  Future<List<RouteWeatherSample>> weatherAlongRoute(
    List<GeoPoint> geometry, {
    int samples = 5,
  }) async => const [];

  @override
  Future<RouteSurfaceSummary> surfaceSummary(List<GeoPoint> geometry) async {
    final isNorthern = geometry.any((point) => point.latitude > 45.01);
    return RouteSurfaceSummary(
      sampleCount: 10,
      counts: isNorthern
          ? const {RouteSurfaceType.trail: 8, RouteSurfaceType.unknown: 2}
          : const {RouteSurfaceType.paved: 8, RouteSurfaceType.unknown: 2},
    );
  }
}

void main() {
  final engine = DefaultRouteIntelligenceEngine(
    routing: _FakeRoutingEngine(),
    elevation: _FakeElevationEngine(),
    context: _FakeOutdoorContext(),
  );

  test('circular generator returns bounded snapped candidates', () async {
    final result = await engine.generateCircularRoutes(
      const CircularRouteRequest(
        start: GeoPoint(latitude: 45.0, longitude: 11.0),
        targetDistanceMeters: 10000,
        profile: RouteProfile.hiking,
        maxCandidates: 3,
      ),
    );

    expect(result, isNotEmpty);
    expect(result.length, lessThanOrEqualTo(3));
    for (final candidate in result) {
      expect(candidate.plan.isSnapped, isTrue);
      expect(candidate.plan.geometry.length, greaterThanOrEqualTo(2));
      expect(candidate.plan.ascentMeters, greaterThan(0));
    }
  });

  test('alternatives support shortest and least-climb strategies', () async {
    const base = RoutePlan(
      geometry: [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.02, longitude: 11.02),
      ],
      distanceMeters: 3000,
      ascentMeters: 100,
      descentMeters: 80,
      estimatedDuration: Duration(minutes: 40),
      profile: RouteProfile.hiking,
      isSnapped: true,
    );

    final shortest = await engine.alternatives(
      base,
      preference: AlternativeRoutePreference.shortest,
    );
    final leastClimb = await engine.alternatives(
      base,
      preference: AlternativeRoutePreference.leastClimb,
    );

    expect(shortest, isNotEmpty);
    expect(leastClimb, isNotEmpty);
    expect(
      engine.supportedAlternativePreferences,
      containsAll(AlternativeRoutePreference.values),
    );
  });

  test('surface-aware preferences produce viable alternatives', () async {
    const base = RoutePlan(
      geometry: [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.02, longitude: 11.02),
      ],
      distanceMeters: 3000,
      ascentMeters: 100,
      descentMeters: 80,
      estimatedDuration: Duration(minutes: 40),
      profile: RouteProfile.hiking,
      isSnapped: true,
    );

    final trail = await engine.alternatives(
      base,
      preference: AlternativeRoutePreference.moreTrail,
    );
    final road = await engine.alternatives(
      base,
      preference: AlternativeRoutePreference.moreRoad,
    );

    expect(trail, isNotEmpty);
    expect(road, isNotEmpty);
    expect(trail.first.score, isNonNegative);
    expect(road.first.score, isNonNegative);
  });
}

import 'dart:math' as math;

import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/route_intelligence.dart';
import 'package:trail_path/core/services/route_intelligence_service.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class DefaultRouteIntelligenceEngine implements RouteIntelligenceEngine {
  const DefaultRouteIntelligenceEngine({
    required RoutingEngine routing,
    required ElevationEngine elevation,
    OutdoorContextService? context,
  }) : _routing = routing,
       _elevation = elevation,
       _context = context;

  final RoutingEngine _routing;
  final ElevationEngine _elevation;
  final OutdoorContextService? _context;

  @override
  Set<AlternativeRoutePreference> get supportedAlternativePreferences =>
      {
        AlternativeRoutePreference.shortest,
        AlternativeRoutePreference.leastClimb,
        if (_context != null) AlternativeRoutePreference.moreTrail,
        if (_context != null) AlternativeRoutePreference.moreRoad,
      };

  @override
  Future<List<RouteCandidate>> generateCircularRoutes(
    CircularRouteRequest request,
  ) async {
    if (request.targetDistanceMeters < 1000) {
      throw ArgumentError.value(
        request.targetDistanceMeters,
        'targetDistanceMeters',
        'Circular routes require at least 1 km.',
      );
    }

    final radius = (request.targetDistanceMeters / (2 * math.pi))
        .clamp(250.0, 18000.0);
    final candidates = <RouteCandidate>[];

    for (final heading in const [25.0, 115.0, 205.0, 295.0]) {
      try {
        final p1 = _destination(request.start, radius, heading);
        final p2 = _destination(
          request.start,
          radius * 1.08,
          heading + 105,
        );
        final p3 = _destination(
          request.start,
          radius * 0.92,
          heading + 220,
        );

        final raw = await _routing.calculate(
          RouteRequest(
            points: [request.start, p1, p2, p3, request.start],
            profile: request.profile,
          ),
        );
        if (!raw.isSnapped || raw.geometry.length < 2) {
          continue;
        }
        final plan = await _withElevation(raw);
        final distanceError =
            (plan.distanceMeters - request.targetDistanceMeters).abs() /
            request.targetDistanceMeters;
        final closure = haversineMeters(
          plan.geometry.first,
          plan.geometry.last,
        );
        final score = distanceError + closure / 1000;

        candidates.add(
          RouteCandidate(
            plan: plan,
            label: 'loop-' + heading.round().toString(),
            score: score,
          ),
        );
      } on Object {
        // A single impossible heading must not discard other candidates.
      }
    }

    candidates.sort((a, b) => a.score.compareTo(b.score));
    return List<RouteCandidate>.unmodifiable(
      candidates.take(request.maxCandidates),
    );
  }

  @override
  Future<List<RouteCandidate>> alternatives(
    RoutePlan route, {
    required AlternativeRoutePreference preference,
  }) async {
    if (!supportedAlternativePreferences.contains(preference) ||
        route.geometry.length < 2) {
      return const [];
    }

    final start = route.geometry.first;
    final end = route.geometry.last;
    final midpoint = pointAlongPolyline(route.geometry);
    final directDistance = haversineMeters(start, end);
    final offsetMeters = math.max(350.0, directDistance * 0.18);
    final baseBearing = bearingDegrees(start, end);

    final pointSets = <List<GeoPoint>>[
      [start, end],
      [start, _destination(midpoint, offsetMeters, baseBearing + 90), end],
      [start, _destination(midpoint, offsetMeters, baseBearing - 90), end],
    ];

    final candidates = <RouteCandidate>[];
    for (var index = 0; index < pointSets.length; index++) {
      try {
        final raw = await _routing.calculate(
          RouteRequest(points: pointSets[index], profile: route.profile),
        );
        if (!raw.isSnapped || raw.geometry.length < 2) {
          continue;
        }
        final plan = await _withElevation(raw);
        final score = await _scoreAlternative(plan, preference);
        candidates.add(
          RouteCandidate(
            plan: plan,
            label: 'alternative-' + index.toString(),
            score: score,
          ),
        );
      } on Object {
        // Keep the viable alternatives when one candidate cannot be routed.
      }
    }

    candidates.sort((a, b) => a.score.compareTo(b.score));
    return List<RouteCandidate>.unmodifiable(candidates);
  }

  Future<double> _scoreAlternative(
    RoutePlan plan,
    AlternativeRoutePreference preference,
  ) async {
    switch (preference) {
      case AlternativeRoutePreference.shortest:
        return plan.distanceMeters;
      case AlternativeRoutePreference.leastClimb:
        return plan.ascentMeters * 1000 + plan.distanceMeters * 0.08;
      case AlternativeRoutePreference.moreTrail:
      case AlternativeRoutePreference.moreRoad:
        final context = _context;
        if (context == null) {
          return double.infinity;
        }
        try {
          final surface = await context.surfaceSummary(plan.geometry);
          final known = 1 - surface.fraction(RouteSurfaceType.unknown);
          if (known <= 0) {
            return 2 + plan.distanceMeters / 100000;
          }
          final preferred = preference == AlternativeRoutePreference.moreTrail
              ? surface.fraction(RouteSurfaceType.trail) +
                    surface.fraction(RouteSurfaceType.dirt) +
                    surface.fraction(RouteSurfaceType.gravel)
              : surface.fraction(RouteSurfaceType.paved);
          return (1 - preferred) + (1 - known) * 0.35 +
              plan.distanceMeters / 1000000;
        } on Object {
          return 2 + plan.distanceMeters / 100000;
        }
    }
  }

  Future<RoutePlan> _withElevation(RoutePlan route) async {
    try {
      final profile = await _elevation.resolve(route.geometry);
      if (!profile.isAvailable) {
        return route;
      }
      return RoutePlan(
        geometry: profile.points.isEmpty ? route.geometry : profile.points,
        distanceMeters: route.distanceMeters,
        ascentMeters: profile.ascentMeters,
        descentMeters: profile.descentMeters,
        estimatedDuration: route.estimatedDuration,
        profile: route.profile,
        isSnapped: route.isSnapped,
        routingSource: route.routingSource,
        snappedWaypoints: route.snappedWaypoints,
      );
    } on Object {
      return route;
    }
  }
}

GeoPoint _destination(
  GeoPoint start,
  double distanceMeters,
  double bearingDegreesValue,
) {
  const earthRadiusMeters = 6371008.8;
  final angularDistance = distanceMeters / earthRadiusMeters;
  final bearing = bearingDegreesValue * math.pi / 180;
  final lat1 = start.latitude * math.pi / 180;
  final lon1 = start.longitude * math.pi / 180;

  final lat2 = math.asin(
    math.sin(lat1) * math.cos(angularDistance) +
        math.cos(lat1) *
            math.sin(angularDistance) *
            math.cos(bearing),
  );
  final lon2 =
      lon1 +
      math.atan2(
        math.sin(bearing) *
            math.sin(angularDistance) *
            math.cos(lat1),
        math.cos(angularDistance) -
            math.sin(lat1) * math.sin(lat2),
      );

  return GeoPoint(
    latitude: lat2 * 180 / math.pi,
    longitude: ((lon2 * 180 / math.pi + 540) % 360) - 180,
  );
}

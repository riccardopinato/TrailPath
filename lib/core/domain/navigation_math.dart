import 'dart:math' as math;

import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';

class RouteProjection {
  const RouteProjection({
    required this.nearestPoint,
    required this.distanceToRouteMeters,
    required this.progressMeters,
    required this.routeDistanceMeters,
  });

  final GeoPoint nearestPoint;
  final double distanceToRouteMeters;
  final double progressMeters;
  final double routeDistanceMeters;

  double get remainingMeters =>
      math.max(0, routeDistanceMeters - progressMeters);
}

RouteProjection projectPointOnRoute(
  GeoPoint current,
  List<GeoPoint> geometry,
) {
  if (geometry.length < 2) {
    throw ArgumentError('Route geometry requires at least two points.');
  }

  final cumulative = <double>[0];
  for (var i = 1; i < geometry.length; i++) {
    cumulative.add(
      cumulative.last + haversineMeters(geometry[i - 1], geometry[i]),
    );
  }

  final routeDistance = cumulative.last;
  var bestDistance = double.infinity;
  var bestProgress = 0.0;
  var bestPoint = geometry.first;

  for (var i = 1; i < geometry.length; i++) {
    final a = geometry[i - 1];
    final b = geometry[i];
    final projection = _projectOnSegment(current, a, b);
    if (projection.distanceMeters < bestDistance) {
      bestDistance = projection.distanceMeters;
      bestProgress =
          cumulative[i - 1] + projection.segmentLengthMeters * projection.t;
      bestPoint = GeoPoint(
        latitude: a.latitude + (b.latitude - a.latitude) * projection.t,
        longitude: a.longitude + (b.longitude - a.longitude) * projection.t,
        elevationMeters: _interpolateNullable(
          a.elevationMeters,
          b.elevationMeters,
          projection.t,
        ),
      );
    }
  }

  return RouteProjection(
    nearestPoint: bestPoint,
    distanceToRouteMeters: bestDistance,
    progressMeters: bestProgress.clamp(0.0, routeDistance),
    routeDistanceMeters: routeDistance,
  );
}

double? _interpolateNullable(double? a, double? b, double t) {
  if (a == null || b == null) {
    return null;
  }
  return a + (b - a) * t;
}

class _SegmentProjection {
  const _SegmentProjection({
    required this.t,
    required this.distanceMeters,
    required this.segmentLengthMeters,
  });

  final double t;
  final double distanceMeters;
  final double segmentLengthMeters;
}

_SegmentProjection _projectOnSegment(
  GeoPoint current,
  GeoPoint a,
  GeoPoint b,
) {
  const metersPerLatDegree = 111320.0;
  final referenceLat =
      (current.latitude + a.latitude + b.latitude) / 3 * math.pi / 180;
  final metersPerLonDegree = metersPerLatDegree * math.cos(referenceLat);

  double x(double longitude) =>
      (longitude - current.longitude) * metersPerLonDegree;
  double y(double latitude) =>
      (latitude - current.latitude) * metersPerLatDegree;

  final ax = x(a.longitude);
  final ay = y(a.latitude);
  final bx = x(b.longitude);
  final by = y(b.latitude);

  final dx = bx - ax;
  final dy = by - ay;
  final lengthSquared = dx * dx + dy * dy;
  final length = math.sqrt(lengthSquared);

  if (lengthSquared <= 0.0001) {
    return _SegmentProjection(
      t: 0,
      distanceMeters: math.sqrt(ax * ax + ay * ay),
      segmentLengthMeters: 0,
    );
  }

  final rawT = -(ax * dx + ay * dy) / lengthSquared;
  final t = rawT.clamp(0.0, 1.0);
  final px = ax + dx * t;
  final py = ay + dy * t;

  return _SegmentProjection(
    t: t,
    distanceMeters: math.sqrt(px * px + py * py),
    segmentLengthMeters: length,
  );
}

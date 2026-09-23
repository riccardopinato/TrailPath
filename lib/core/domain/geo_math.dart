import 'dart:math' as math;

import 'package:trail_path/core/domain/models.dart';

double calculateRouteDistanceMeters(List<GeoPoint> points) {
  if (points.length < 2) {
    return 0;
  }

  var total = 0.0;
  for (var index = 1; index < points.length; index++) {
    total += haversineMeters(points[index - 1], points[index]);
  }
  return total;
}

double haversineMeters(GeoPoint a, GeoPoint b) {
  const earthRadiusMeters = 6371008.8;
  final lat1 = _degreesToRadians(a.latitude);
  final lat2 = _degreesToRadians(b.latitude);
  final deltaLat = _degreesToRadians(b.latitude - a.latitude);
  final deltaLon = _degreesToRadians(b.longitude - a.longitude);

  final sinLat = math.sin(deltaLat / 2);
  final sinLon = math.sin(deltaLon / 2);
  final h = sinLat * sinLat +
      math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
  final arc = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusMeters * arc;
}

double bearingDegrees(GeoPoint from, GeoPoint to) {
  final lat1 = _degreesToRadians(from.latitude);
  final lat2 = _degreesToRadians(to.latitude);
  final deltaLon = _degreesToRadians(to.longitude - from.longitude);

  final y = math.sin(deltaLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);
  final bearing = math.atan2(y, x) * 180 / math.pi;
  return normalizeDegrees(bearing);
}

double normalizeDegrees(double degrees) {
  final normalized = degrees % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

GeoPoint pointAlongPolyline(
  List<GeoPoint> points, {
  double fraction = 0.5,
}) {
  if (points.isEmpty) {
    throw ArgumentError.value(points, 'points', 'Polyline cannot be empty.');
  }
  if (points.length == 1) {
    return points.first;
  }

  final targetFraction = fraction.clamp(0.0, 1.0);
  final total = calculateRouteDistanceMeters(points);
  if (total <= 0) {
    return points.first;
  }

  final target = total * targetFraction;
  var travelled = 0.0;
  for (var index = 1; index < points.length; index++) {
    final from = points[index - 1];
    final to = points[index];
    final segment = haversineMeters(from, to);
    if (segment <= 0) {
      continue;
    }

    if (travelled + segment >= target) {
      final local = ((target - travelled) / segment).clamp(0.0, 1.0);
      final elevation = from.elevationMeters != null && to.elevationMeters != null
          ? from.elevationMeters! +
              (to.elevationMeters! - from.elevationMeters!) * local
          : null;
      return GeoPoint(
        latitude: from.latitude + (to.latitude - from.latitude) * local,
        longitude: from.longitude + (to.longitude - from.longitude) * local,
        elevationMeters: elevation,
      );
    }
    travelled += segment;
  }

  return points.last;
}

double distanceToPolylineMeters(
  GeoPoint point,
  List<GeoPoint> polyline,
) {
  if (polyline.isEmpty) {
    return double.infinity;
  }
  if (polyline.length == 1) {
    return haversineMeters(point, polyline.first);
  }

  const earthRadiusMeters = 6371008.8;
  final latitudeScale = earthRadiusMeters * math.pi / 180;
  final longitudeScale =
      latitudeScale * math.cos(_degreesToRadians(point.latitude));
  var best = double.infinity;

  for (var index = 1; index < polyline.length; index++) {
    final a = polyline[index - 1];
    final b = polyline[index];
    final ax = (a.longitude - point.longitude) * longitudeScale;
    final ay = (a.latitude - point.latitude) * latitudeScale;
    final bx = (b.longitude - point.longitude) * longitudeScale;
    final by = (b.latitude - point.latitude) * latitudeScale;
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;

    final t = lengthSquared <= 0
        ? 0.0
        : (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0);
    final nearestX = ax + dx * t;
    final nearestY = ay + dy * t;
    final distance = math.sqrt(nearestX * nearestX + nearestY * nearestY);
    if (distance < best) {
      best = distance;
    }
  }

  return best;
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

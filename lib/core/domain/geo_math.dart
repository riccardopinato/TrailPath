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

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

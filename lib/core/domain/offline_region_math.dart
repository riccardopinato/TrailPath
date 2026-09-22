import 'dart:math' as math;

import 'package:trail_path/core/domain/models.dart';

OfflineRegionRequest offlineRegionRequestForRoute({
  required String id,
  required String name,
  required List<GeoPoint> points,
  double minZoom = 8,
  double paddingFraction = 0.18,
  double minimumPaddingDegrees = 0.01,
}) {
  if (points.length < 2) {
    throw ArgumentError(
      'Offline route preparation requires at least two points.',
    );
  }

  var south = points.first.latitude;
  var north = points.first.latitude;
  var west = points.first.longitude;
  var east = points.first.longitude;

  for (final point in points.skip(1)) {
    south = math.min(south, point.latitude);
    north = math.max(north, point.latitude);
    west = math.min(west, point.longitude);
    east = math.max(east, point.longitude);
  }

  final latitudeSpan = north - south;
  final longitudeSpan = east - west;
  final latitudePadding = math.max(
    minimumPaddingDegrees,
    latitudeSpan * paddingFraction,
  );
  final longitudePadding = math.max(
    minimumPaddingDegrees,
    longitudeSpan * paddingFraction,
  );
  final largestSpan = math.max(latitudeSpan, longitudeSpan);

  final maxZoom = switch (largestSpan) {
    <= 0.08 => 16.0,
    <= 0.25 => 15.0,
    <= 0.70 => 14.0,
    _ => 13.0,
  };

  return OfflineRegionRequest(
    id: id,
    name: name,
    north: (north + latitudePadding).clamp(-85.0, 85.0).toDouble(),
    south: (south - latitudePadding).clamp(-85.0, 85.0).toDouble(),
    east: (east + longitudePadding).clamp(-180.0, 180.0).toDouble(),
    west: (west - longitudePadding).clamp(-180.0, 180.0).toDouble(),
    minZoom: minZoom,
    maxZoom: maxZoom,
  );
}

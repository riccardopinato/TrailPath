import 'package:trail_path/core/domain/models.dart';

enum MapMatchMode { trails, roads, free }

class TraceMatchRequest {
  const TraceMatchRequest({
    required this.trace,
    required this.profile,
    required this.mode,
  });

  final List<GeoPoint> trace;
  final RouteProfile profile;
  final MapMatchMode mode;
}

class TraceMatchResult {
  const TraceMatchResult({
    required this.geometry,
    required this.distanceMeters,
    required this.estimatedDuration,
    required this.source,
  });

  final List<GeoPoint> geometry;
  final double distanceMeters;
  final Duration estimatedDuration;
  final String source;
}

class MapMatchingException implements Exception {
  const MapMatchingException(this.message);

  final String message;

  @override
  String toString() => 'MapMatchingException: $message';
}

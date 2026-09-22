enum RouteProfile {
  hiking,
  trailRunning,
  walking,
  mountainBike,
  cycling,
  dogWalk,
}

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.elevationMeters,
    this.timestamp,
  }) : assert(latitude >= -90 && latitude <= 90),
       assert(longitude >= -180 && longitude <= 180);

  final double latitude;
  final double longitude;
  final double? elevationMeters;
  final DateTime? timestamp;

  GeoPoint copyWith({
    double? latitude,
    double? longitude,
    double? elevationMeters,
    DateTime? timestamp,
  }) {
    return GeoPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class RouteRequest {
  const RouteRequest({
    required this.points,
    required this.profile,
    this.snapToNetwork = true,
  });

  final List<GeoPoint> points;
  final RouteProfile profile;
  final bool snapToNetwork;
}

class RoutePlan {
  const RoutePlan({
    required this.geometry,
    required this.distanceMeters,
    required this.ascentMeters,
    required this.descentMeters,
    required this.estimatedDuration,
    required this.profile,
    this.isSnapped = false,
    this.routingSource = 'local',
  });

  final List<GeoPoint> geometry;
  final double distanceMeters;
  final double ascentMeters;
  final double descentMeters;
  final Duration estimatedDuration;
  final RouteProfile profile;
  final bool isSnapped;
  final String routingSource;
}

class ElevationSample {
  const ElevationSample({
    required this.point,
    required this.distanceMeters,
    required this.gradePercent,
  });

  final GeoPoint point;
  final double distanceMeters;
  final double gradePercent;
}

class ElevationProfile {
  const ElevationProfile({
    required this.points,
    required this.samples,
    required this.ascentMeters,
    required this.descentMeters,
    required this.minElevationMeters,
    required this.maxElevationMeters,
    this.isAvailable = true,
    this.source = 'unknown',
  });

  const ElevationProfile.unavailable()
      : points = const [],
        samples = const [],
        ascentMeters = 0,
        descentMeters = 0,
        minElevationMeters = 0,
        maxElevationMeters = 0,
        isAvailable = false,
        source = 'unavailable';

  final List<GeoPoint> points;
  final List<ElevationSample> samples;
  final double ascentMeters;
  final double descentMeters;
  final double minElevationMeters;
  final double maxElevationMeters;
  final bool isAvailable;
  final String source;
}

class PositionSample {
  const PositionSample({
    required this.point,
    required this.accuracyMeters,
    this.speedMetersPerSecond,
    this.headingDegrees,
  });

  final GeoPoint point;
  final double accuracyMeters;
  final double? speedMetersPerSecond;
  final double? headingDegrees;
}

enum TrackRecorderStatus { idle, recording, paused, stopping, completed }

class TrackRecorderSnapshot {
  const TrackRecorderSnapshot({
    required this.status,
    required this.points,
    required this.distanceMeters,
    required this.elapsed,
    this.ascentMeters = 0,
    this.currentSpeedMetersPerSecond,
    this.accuracyMeters,
  });

  final TrackRecorderStatus status;
  final List<GeoPoint> points;
  final double distanceMeters;
  final Duration elapsed;
  final double ascentMeters;
  final double? currentSpeedMetersPerSecond;
  final double? accuracyMeters;
}

enum NavigationEventType {
  started,
  instruction,
  offRoute,
  backOnRoute,
  arrived,
  stopped,
}

class NavigationEvent {
  const NavigationEvent({
    required this.type,
    this.message,
    this.distanceMeters,
    this.currentPoint,
    this.nearestRoutePoint,
    this.progressMeters = 0,
    this.remainingMeters = 0,
    this.distanceToRouteMeters = 0,
    this.routeDistanceMeters = 0,
    this.isOffRoute = false,
  });

  final NavigationEventType type;
  final String? message;
  final double? distanceMeters;
  final GeoPoint? currentPoint;
  final GeoPoint? nearestRoutePoint;
  final double progressMeters;
  final double remainingMeters;
  final double distanceToRouteMeters;
  final double routeDistanceMeters;
  final bool isOffRoute;

  double get progressFraction {
    if (routeDistanceMeters <= 0) {
      return 0;
    }
    return (progressMeters / routeDistanceMeters).clamp(0.0, 1.0);
  }
}

class OfflineRegion {
  const OfflineRegion({
    required this.id,
    required this.name,
    required this.downloadedBytes,
    required this.isComplete,
  });

  final String id;
  final String name;
  final int downloadedBytes;
  final bool isComplete;
}

class OfflineRegionRequest {
  const OfflineRegionRequest({
    required this.id,
    required this.name,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.minZoom,
    required this.maxZoom,
  });

  final String id;
  final String name;
  final double north;
  final double south;
  final double east;
  final double west;
  final double minZoom;
  final double maxZoom;
}

class GpxDocument {
  const GpxDocument({required this.name, required this.points});

  final String name;
  final List<GeoPoint> points;
}

class SafetySnapshot {
  const SafetySnapshot({
    required this.batteryPercent,
    required this.hasLocationPermission,
    required this.locationServiceEnabled,
    required this.isOfflineMapAvailable,
  });

  final int batteryPercent;
  final bool hasLocationPermission;
  final bool locationServiceEnabled;
  final bool isOfflineMapAvailable;
}


class RoutingException implements Exception {
  const RoutingException(this.message);

  final String message;

  @override
  String toString() => 'RoutingException: $message';
}


class ElevationException implements Exception {
  const ElevationException(this.message);

  final String message;

  @override
  String toString() => 'ElevationException: $message';
}

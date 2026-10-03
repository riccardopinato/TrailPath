import 'package:trail_path/core/domain/models.dart';

enum AlternativeRoutePreference { shortest, leastClimb, moreTrail, moreRoad }

class RouteCandidate {
  const RouteCandidate({
    required this.plan,
    required this.label,
    required this.score,
  });

  final RoutePlan plan;
  final String label;
  final double score;
}

class CircularRouteRequest {
  const CircularRouteRequest({
    required this.start,
    required this.targetDistanceMeters,
    required this.profile,
    this.maxCandidates = 3,
  });

  final GeoPoint start;
  final double targetDistanceMeters;
  final RouteProfile profile;
  final int maxCandidates;
}

enum OutdoorPoiType {
  drinkingWater,
  shelter,
  alpineHut,
  viewpoint,
  parking,
  toilets,
}

class OutdoorPoi {
  const OutdoorPoi({
    required this.id,
    required this.type,
    required this.name,
    required this.point,
    required this.distanceFromRouteMeters,
  });

  final String id;
  final OutdoorPoiType type;
  final String name;
  final GeoPoint point;
  final double distanceFromRouteMeters;
}

class RouteWeatherSample {
  const RouteWeatherSample({
    required this.point,
    required this.temperatureCelsius,
    required this.precipitationMm,
    required this.windKmh,
    required this.observedAt,
  });

  final GeoPoint point;
  final double temperatureCelsius;
  final double precipitationMm;
  final double windKmh;
  final DateTime observedAt;
}

enum RouteSurfaceType { paved, gravel, dirt, trail, unknown }

class RouteSurfaceSummary {
  const RouteSurfaceSummary({required this.sampleCount, required this.counts});

  final int sampleCount;
  final Map<RouteSurfaceType, int> counts;

  double fraction(RouteSurfaceType type) {
    if (sampleCount <= 0) {
      return 0;
    }
    return (counts[type] ?? 0) / sampleCount;
  }

  RouteSurfaceType get dominant {
    if (counts.isEmpty) {
      return RouteSurfaceType.unknown;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class PersonalStats {
  const PersonalStats({
    required this.activityCount,
    required this.totalDistanceMeters,
    required this.totalAscentMeters,
    required this.totalMovingTime,
    required this.last7DaysDistanceMeters,
    required this.last30DaysDistanceMeters,
    required this.longestActivityMeters,
    required this.highestAscentMeters,
  });

  final int activityCount;
  final double totalDistanceMeters;
  final double totalAscentMeters;
  final Duration totalMovingTime;
  final double last7DaysDistanceMeters;
  final double last30DaysDistanceMeters;
  final double longestActivityMeters;
  final double highestAscentMeters;
}

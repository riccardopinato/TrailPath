import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/route_intelligence.dart';

abstract interface class RouteIntelligenceEngine {
  Set<AlternativeRoutePreference> get supportedAlternativePreferences;

  Future<List<RouteCandidate>> generateCircularRoutes(
    CircularRouteRequest request,
  );

  Future<List<RouteCandidate>> alternatives(
    RoutePlan route, {
    required AlternativeRoutePreference preference,
  });
}

abstract interface class OutdoorContextService {
  Future<List<OutdoorPoi>> poisAlongRoute(
    List<GeoPoint> geometry, {
    double corridorMeters = 800,
  });

  Future<List<RouteWeatherSample>> weatherAlongRoute(
    List<GeoPoint> geometry, {
    int samples = 5,
  });

  Future<RouteSurfaceSummary> surfaceSummary(List<GeoPoint> geometry);
}

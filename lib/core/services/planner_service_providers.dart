import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/services/route_intelligence_service.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/elevation/open_meteo_elevation_engine.dart';
import 'package:trail_path/infrastructure/outdoor/openstreetmap_outdoor_context_service.dart';
import 'package:trail_path/infrastructure/routing/default_route_intelligence_engine.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';
import 'package:trail_path/infrastructure/routing/valhalla_map_matching_engine.dart';
import 'package:trail_path/infrastructure/search/nominatim_place_search_service.dart';

final routingEngineProvider = Provider<RoutingEngine>((ref) {
  if (MapConfig.hasDedicatedRoutingProvider) {
    // Store builds prefer the configured production provider and do not
    // silently fall back to a community OSRM endpoint when it is unavailable.
    final production = ValhallaRoutingEngine();
    ref.onDispose(production.dispose);
    return FallbackRoutingEngine(
      primary: production,
      fallback: const StraightLineRoutingEngine(),
    );
  }

  // Development/internal builds remain usable without credentials by using
  // the public community services with bounded retries and a second provider.
  final primary = OpenStreetMapRoutingEngine();
  final secondary = ValhallaRoutingEngine();
  ref.onDispose(primary.dispose);
  ref.onDispose(secondary.dispose);
  return FallbackRoutingEngine(
    primary: primary,
    fallback: FallbackRoutingEngine(
      primary: secondary,
      fallback: const StraightLineRoutingEngine(),
    ),
  );
});

final mapMatchingEngineProvider = Provider<MapMatchingEngine>((ref) {
  final engine = ValhallaMapMatchingEngine();
  ref.onDispose(engine.dispose);
  return RoutingFallbackMapMatchingEngine(
    primary: engine,
    routing: ref.watch(routingEngineProvider),
  );
});

final elevationEngineProvider = Provider<ElevationEngine>((ref) {
  final primary = OpenMeteoElevationEngine();
  ref.onDispose(primary.dispose);
  return FallbackElevationEngine(
    primary: primary,
    fallback: const UnavailableElevationEngine(),
  );
});

final placeSearchServiceProvider = Provider<PlaceSearchService>((ref) {
  final service = NominatimPlaceSearchService();
  ref.onDispose(service.dispose);
  return service;
});

final outdoorContextServiceProvider = Provider<OutdoorContextService>((ref) {
  final service = OpenStreetMapOutdoorContextService();
  ref.onDispose(service.dispose);
  return service;
});

final routeIntelligenceEngineProvider = Provider<RouteIntelligenceEngine>((
  ref,
) {
  return DefaultRouteIntelligenceEngine(
    routing: ref.watch(routingEngineProvider),
    elevation: ref.watch(elevationEngineProvider),
    context: ref.watch(outdoorContextServiceProvider),
  );
});

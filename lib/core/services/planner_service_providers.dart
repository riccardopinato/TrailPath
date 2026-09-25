import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/elevation/open_meteo_elevation_engine.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';

final routingEngineProvider = Provider<RoutingEngine>((ref) {
  final primary = OpenStreetMapRoutingEngine();
  ref.onDispose(primary.dispose);
  return FallbackRoutingEngine(
    primary: primary,
    fallback: const StraightLineRoutingEngine(),
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

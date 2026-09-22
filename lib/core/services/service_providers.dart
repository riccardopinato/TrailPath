import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/elevation/open_meteo_elevation_engine.dart';
import 'package:trail_path/infrastructure/location/geolocator_location_engine.dart';
import 'package:trail_path/infrastructure/maps/maplibre_map_engine.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';

final mapEngineProvider = Provider<MapEngine>(
  (ref) => const MapLibreMapEngine(),
);

final locationEngineProvider = Provider<LocationEngine>(
  (ref) => const GeolocatorLocationEngine(),
);


final routingEngineProvider = Provider<RoutingEngine>(
  (ref) => const FallbackRoutingEngine(
    primary: OpenStreetMapRoutingEngine(),
    fallback: StraightLineRoutingEngine(),
  ),
);


final elevationEngineProvider = Provider<ElevationEngine>(
  (ref) => const FallbackElevationEngine(
    primary: OpenMeteoElevationEngine(),
    fallback: UnavailableElevationEngine(),
  ),
);

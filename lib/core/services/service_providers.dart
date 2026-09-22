import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/location/geolocator_location_engine.dart';
import 'package:trail_path/infrastructure/maps/maplibre_map_engine.dart';

final mapEngineProvider = Provider<MapEngine>(
  (ref) => const MapLibreMapEngine(),
);

final locationEngineProvider = Provider<LocationEngine>(
  (ref) => const GeolocatorLocationEngine(),
);

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/elevation/open_meteo_elevation_engine.dart';
import 'package:trail_path/infrastructure/gpx/xml_gpx_service.dart';
import 'package:trail_path/infrastructure/location/geolocator_location_engine.dart';
import 'package:trail_path/infrastructure/maps/maplibre_map_engine.dart';
import 'package:trail_path/infrastructure/maps/maplibre_offline_map_manager.dart';
import 'package:trail_path/infrastructure/navigation/flutter_tts_navigation_feedback.dart';
import 'package:trail_path/infrastructure/navigation/route_navigation_engine.dart';
import 'package:trail_path/infrastructure/permissions/runtime_permission_service.dart';
import 'package:trail_path/infrastructure/recording/geolocator_track_recorder.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';
import 'package:trail_path/infrastructure/safety/device_safety_service.dart';
import 'package:trail_path/infrastructure/search/nominatim_place_search_service.dart';

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


final gpxServiceProvider = Provider<GpxService>(
  (ref) => const XmlGpxService(),
);


final runtimePermissionProvider = Provider<RuntimePermissionService>(
  (ref) => const RuntimePermissionService(),
);

final trackRecorderProvider = Provider<TrackRecorder>((ref) {
  final recorder = GeolocatorTrackRecorder();
  ref.onDispose(() {
    unawaited(recorder.dispose());
  });
  return recorder;
});


final navigationEngineProvider = Provider<NavigationEngine>((ref) {
  final engine = RouteNavigationEngine(
    locationEngine: ref.watch(locationEngineProvider),
  );
  ref.onDispose(() {
    unawaited(engine.dispose());
  });
  return engine;
});

final navigationFeedbackProvider = Provider<NavigationFeedback>((ref) {
  final feedback = FlutterTtsNavigationFeedback();
  ref.onDispose(() {
    unawaited(feedback.stop());
  });
  return feedback;
});

final offlineMapManagerProvider = Provider<OfflineMapManager>(
  (ref) => const MapLibreOfflineMapManager(),
);

final placeSearchServiceProvider = Provider<PlaceSearchService>(
  (ref) => NominatimPlaceSearchService(),
);

final safetyServiceProvider = Provider<SafetyService>(
  (ref) => DeviceSafetyService(
    locationEngine: ref.watch(locationEngineProvider),
    offlineMapManager: ref.watch(offlineMapManagerProvider),
  ),
);

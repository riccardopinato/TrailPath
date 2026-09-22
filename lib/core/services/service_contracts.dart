import 'package:trail_path/core/domain/models.dart';

abstract interface class MapEngine {
  String get engineId;

  Future<void> warmUp();
}

abstract interface class RoutingEngine {
  String get engineId;

  Future<RoutePlan> calculate(RouteRequest request);
}

abstract interface class ElevationEngine {
  String get engineId;

  Future<ElevationProfile> resolve(List<GeoPoint> points);
}

abstract interface class LocationEngine {
  Future<bool> isServiceEnabled();

  Future<bool> hasPermission();

  Future<bool> requestPermission();

  Future<PositionSample?> current();

  Stream<PositionSample> watch();
}

abstract interface class TrackRecorder {
  Stream<TrackRecorderSnapshot> get snapshots;

  Future<void> start();

  Future<void> pause();

  Future<void> resume();

  Future<TrackRecorderSnapshot> stop();
}

abstract interface class NavigationEngine {
  Stream<NavigationEvent> get events;

  Future<void> start(RoutePlan route);

  Future<void> stop();
}

abstract interface class OfflineMapManager {
  Future<List<OfflineRegion>> listRegions();

  Stream<OfflineRegion> download(OfflineRegionRequest request);

  Future<void> delete(String regionId);
}

abstract interface class GpxService {
  Future<GpxDocument> parse(String xml);

  Future<String> export(GpxDocument document);
}

abstract interface class SafetyService {
  Future<SafetySnapshot> inspect();
}

import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';

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

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();

  Future<PositionSample?> current();

  Stream<PositionSample> watch({
    BatteryMode mode = BatteryMode.balanced,
    bool keepAliveInBackground = false,
  });
}

abstract interface class TrackRecorder {
  Stream<TrackRecorderSnapshot> get snapshots;

  Future<void> setBatteryMode(BatteryMode mode);

  Future<void> start();

  Future<void> restore(TrackRecorderSnapshot snapshot);

  Future<void> pause();

  Future<void> resume();

  Future<TrackRecorderSnapshot> stop();

  Future<void> dispose();
}

abstract interface class NavigationEngine {
  Stream<NavigationEvent> get events;

  Future<void> start(
    RoutePlan route, {
    BatteryMode mode = BatteryMode.balanced,
  });

  Future<void> setBatteryMode(BatteryMode mode);

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class NavigationFeedback {
  Future<void> configure(String languageCode);

  Future<void> speak(String message);

  Future<void> alert();

  Future<void> stop();
}

abstract interface class OfflineMapManager {
  Future<List<OfflineRegion>> listRegions();

  Stream<OfflineRegion> download(OfflineRegionRequest request);

  Future<void> delete(String regionId);

  Future<void> clearCache();
}

abstract interface class GpxService {
  Future<GpxDocument> parse(String xml);

  Future<String> export(GpxDocument document);
}

abstract interface class PlaceSearchService {
  Future<List<PlaceSearchResult>> search(
    String query, {
    String? languageCode,
  });
}

abstract interface class SafetyService {
  Future<SafetySnapshot> inspect();
}

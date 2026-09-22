import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class MapLibreMapEngine implements MapEngine {
  const MapLibreMapEngine();

  @override
  String get engineId => 'maplibre';

  @override
  Future<void> warmUp() => MapLibreMap.preWarm();
}

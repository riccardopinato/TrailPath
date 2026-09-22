import 'package:trail_path/core/services/service_contracts.dart';

class MapLibreMapEngine implements MapEngine {
  const MapLibreMapEngine();

  @override
  String get engineId => 'maplibre';

  @override
  Future<void> warmUp() async {
    // Native MapLibre view initialization is introduced in v0.2.
  }
}

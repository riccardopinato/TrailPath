import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/app/app.dart';
import 'package:trail_path/core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Android's default SurfaceView path can fall back to Virtual Display,
  // which is fragile when a text field/IME is shown over the map.
  // Texture-based composition keeps MapLibre in Flutter's regular
  // composition path and avoids the save-dialog/keyboard lifecycle crash.
  MapLibreMap.useHybridComposition = true;

  AppLogger.info('TrailPath bootstrap');
  runApp(const ProviderScope(child: TrailPathApp()));
}

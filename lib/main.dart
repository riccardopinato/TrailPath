import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/app/app.dart';
import 'package:trail_path/core/logging/app_logger.dart';
import 'package:trail_path/infrastructure/maps/maplibre_map_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('TrailPath bootstrap');

  try {
    await const MapLibreMapEngine().warmUp();
  } catch (error, stackTrace) {
    AppLogger.warning('MapLibre prewarm skipped: $error');
    AppLogger.error(
      'MapLibre prewarm failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  runApp(const ProviderScope(child: TrailPathApp()));
}

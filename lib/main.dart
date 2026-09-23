import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/app/app.dart';
import 'package:trail_path/core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MapLibreMap.preWarm());
  AppLogger.info('TrailPath bootstrap');
  runApp(const ProviderScope(child: TrailPathApp()));
}

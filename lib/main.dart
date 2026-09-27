import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trail_path/app/app.dart';
import 'package:trail_path/core/config/cloud_config.dart';
import 'package:trail_path/core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MapLibreMap.preWarm());
  if (CloudConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: CloudConfig.supabaseUrl,
        publishableKey: CloudConfig.supabasePublishableKey,
        debug: false,
      );
      CloudConfig.supabaseInitialized = true;
    } on Object catch (error, stackTrace) {
      CloudConfig.supabaseInitialized = false;
      AppLogger.error(
        'Optional cloud sync initialization failed; continuing local-first.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  AppLogger.info('TrailPath bootstrap');
  runApp(const ProviderScope(child: TrailPathApp()));
}

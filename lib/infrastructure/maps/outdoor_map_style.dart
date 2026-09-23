import 'package:maplibre_gl/maplibre_gl.dart';

/// Applies TrailPath's outdoor emphasis on top of the remote base style.
///
/// The base style remains authoritative and usable if its layer identifiers
/// change. We only strengthen rendered path/pedestrian/track line layers that
/// already exist in the style.
abstract final class OutdoorMapStyle {
  static Future<void> enhance(MapLibreMapController controller) async {
    try {
      final layerIds = await controller.getLayerIds();
      for (final rawId in layerIds) {
        final id = rawId.toString();
        final lower = id.toLowerCase();
        if (!_looksLikeTrailLayer(lower)) {
          continue;
        }

        try {
          await controller.setLayerProperties(
            id,
            const LineLayerProperties(
              lineColor: '#9A6A3A',
              lineWidth: 2.8,
              lineOpacity: 0.96,
              lineCap: 'round',
              lineJoin: 'round',
            ),
          );
        } on Object {
          // Matching symbol layers are intentionally left untouched.
        }
      }
    } on Object {
      // Provider/style changes must never make the map unusable.
    }
  }

  static bool _looksLikeTrailLayer(String id) {
    return id.contains('path') ||
        id.contains('pedestrian') ||
        id.contains('track') ||
        id.contains('trail') ||
        id.contains('footway');
  }
}

abstract final class MapConfig {
  static const String appVersion = '1.5.8';
  static const String projectUrl =
      'https://github.com/riccardopinato/TrailPath';

  static const String styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  static const String plannerStyleUrl =
      'https://tiles.openfreemap.org/styles/fiord';

  static const String highContrastStyleUrl =
      'https://tiles.openfreemap.org/styles/bright';

  static const String searchEndpoint =
      'https://nominatim.openstreetmap.org/search';

  static const String mapMatchingEndpoint =
      'https://valhalla1.openstreetmap.de/trace_route';

  static const String valhallaRoutingEndpoint =
      'https://valhalla1.openstreetmap.de/route';

  static const String overpassEndpoint =
      'https://overpass-api.de/api/interpreter';

  static const String weatherEndpoint =
      'https://api.open-meteo.com/v1/forecast';

  static const String mapTilerApiKey = String.fromEnvironment(
    'MAPTILER_API_KEY',
  );

  static bool get hasPremiumMapProvider => mapTilerApiKey.trim().isNotEmpty;

  static String? mapTilerStyleUrl(String mapId) {
    if (!hasPremiumMapProvider) {
      return null;
    }
    return 'https://api.maptiler.com/maps/$mapId/style.json?key=$mapTilerApiKey';
  }

  static String? get mapTilerTerrainDemUrl {
    if (!hasPremiumMapProvider) {
      return null;
    }
    return 'https://api.maptiler.com/tiles/terrain-rgb-v2/tiles.json?key=$mapTilerApiKey';
  }

  static String get userAgent => 'TrailPath/$appVersion (+$projectUrl)';
}

abstract final class MapConfig {
  static const String projectUrl =
      'https://github.com/riccardopinato/TrailPath';

  static const String styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  static const String plannerStyleUrl =
      'https://tiles.openfreemap.org/styles/fiord';

  static const String highContrastStyleUrl =
      'https://tiles.openfreemap.org/styles/bright';

  static const String searchEndpoint =
      'https://nominatim.openstreetmap.org/search';

  static const String _publicValhallaBaseUrl =
      'https://valhalla1.openstreetmap.de';

  static const String dedicatedValhallaBaseUrl = String.fromEnvironment(
    'VALHALLA_BASE_URL',
  );

  static bool get hasDedicatedRoutingProvider =>
      dedicatedValhallaBaseUrl.trim().isNotEmpty;

  static String get _valhallaBaseUrl {
    final configured = dedicatedValhallaBaseUrl.trim();
    final value = configured.isEmpty ? _publicValhallaBaseUrl : configured;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String get mapMatchingEndpoint => '$_valhallaBaseUrl/trace_route';

  static String get valhallaRoutingEndpoint => '$_valhallaBaseUrl/route';

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

  static String get userAgent => 'TrailPath (+$projectUrl)';
}

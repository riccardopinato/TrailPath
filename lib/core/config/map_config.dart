abstract final class MapConfig {
  static const String appVersion = '1.2.0';
  static const String projectUrl =
      'https://github.com/riccardopinato/TrailPath';

  static const String styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  static const String plannerStyleUrl =
      'https://tiles.openfreemap.org/styles/fiord';

  static const String searchEndpoint =
      'https://nominatim.openstreetmap.org/search';

  static const String mapMatchingEndpoint =
      'https://valhalla1.openstreetmap.de/trace_route';

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

  static String get userAgent => 'TrailPath/$appVersion (+$projectUrl)';
}

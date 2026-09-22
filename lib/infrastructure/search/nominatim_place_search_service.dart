import 'dart:convert';
import 'dart:io';

import 'package:trail_path/core/domain/models.dart';

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.name,
    required this.point,
    required this.type,
  });

  final String name;
  final GeoPoint point;
  final String type;
}

class NominatimPlaceSearchService {
  const NominatimPlaceSearchService({
    this.timeout = const Duration(seconds: 10),
  });

  final Duration timeout;

  Future<List<PlaceSearchResult>> search(String query) async {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return const [];
    }

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': normalized,
        'format': 'jsonv2',
        'limit': '8',
        'addressdetails': '0',
      },
    );

    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent =
          'TrailPath/0.9.1 (+https://github.com/riccardopinato/TrailPath)';

    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.acceptLanguageHeader,
        Platform.localeName.replaceAll('_', '-'),
      );
      final response = await request.close().timeout(timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Place search returned HTTP ${response.statusCode}.',
          uri: uri,
        );
      }

      final body = await response.transform(utf8.decoder).join();
      final payload = jsonDecode(body);
      if (payload is! List) {
        return const [];
      }

      final results = <PlaceSearchResult>[];
      for (final raw in payload) {
        if (raw is! Map) {
          continue;
        }
        final lat = double.tryParse(raw['lat']?.toString() ?? '');
        final lon = double.tryParse(raw['lon']?.toString() ?? '');
        final displayName = raw['display_name']?.toString().trim() ?? '';
        if (lat == null || lon == null || displayName.isEmpty) {
          continue;
        }
        results.add(
          PlaceSearchResult(
            name: displayName,
            point: GeoPoint(latitude: lat, longitude: lon),
            type: raw['type']?.toString() ?? '',
          ),
        );
      }
      return List<PlaceSearchResult>.unmodifiable(results);
    } finally {
      client.close(force: true);
    }
  }
}

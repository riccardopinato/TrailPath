import 'dart:convert';
import 'dart:io';

import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class NominatimPlaceSearchService implements PlaceSearchService {
  NominatimPlaceSearchService({
    this.timeout = const Duration(seconds: 10),
  });

  final Duration timeout;
  final Map<String, List<PlaceSearchResult>> _cache = {};
  DateTime? _lastRequestAt;

  @override
  Future<List<PlaceSearchResult>> search(
    String query, {
    String? languageCode,
  }) async {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return const [];
    }

    final cacheKey = '${languageCode ?? 'en'}|${normalized.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final previous = _lastRequestAt;
    if (previous != null) {
      final elapsed = DateTime.now().difference(previous);
      const minimumGap = Duration(seconds: 1);
      if (elapsed < minimumGap) {
        await Future<void>.delayed(minimumGap - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();

    final uri = Uri.parse(MapConfig.searchEndpoint).replace(
      queryParameters: {
        'format': 'jsonv2',
        'q': normalized,
        'limit': '6',
        'addressdetails': '1',
      },
    );

    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = MapConfig.userAgent;

    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (languageCode != null && languageCode.isNotEmpty) {
        request.headers.set(HttpHeaders.acceptLanguageHeader, languageCode);
      }

      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw PlaceSearchException(
          'Search service returned HTTP ${response.statusCode}.',
        );
      }

      final body = await response.transform(utf8.decoder).join().timeout(timeout);
      final results = decodeNominatimSearchResults(body);
      _cache[cacheKey] = results;

      if (_cache.length > 40) {
        _cache.remove(_cache.keys.first);
      }

      return results;
    } finally {
      client.close(force: true);
    }
  }
}

List<PlaceSearchResult> decodeNominatimSearchResults(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! List) {
    throw const PlaceSearchException('Invalid place search response.');
  }

  final results = <PlaceSearchResult>[];
  for (final item in decoded) {
    if (item is! Map<String, dynamic>) {
      continue;
    }

    final latitude = double.tryParse(item['lat']?.toString() ?? '');
    final longitude = double.tryParse(item['lon']?.toString() ?? '');
    final displayName = item['display_name']?.toString().trim() ?? '';
    final explicitName = item['name']?.toString().trim() ?? '';

    if (latitude == null ||
        longitude == null ||
        displayName.isEmpty ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      continue;
    }

    final name = explicitName.isNotEmpty
        ? explicitName
        : displayName.split(',').first.trim();

    results.add(
      PlaceSearchResult(
        name: name.isEmpty ? displayName : name,
        displayName: displayName,
        point: GeoPoint(
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
  }

  return List<PlaceSearchResult>.unmodifiable(results);
}

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);

  final String message;

  @override
  String toString() => 'PlaceSearchException: $message';
}

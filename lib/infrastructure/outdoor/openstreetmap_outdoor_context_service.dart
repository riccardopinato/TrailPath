import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/route_intelligence.dart';
import 'package:trail_path/core/services/route_intelligence_service.dart';
import 'package:trail_path/infrastructure/network/http_retry.dart';

class OpenStreetMapOutdoorContextService implements OutdoorContextService {
  OpenStreetMapOutdoorContextService({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 1,
    this.retryBaseDelay = const Duration(milliseconds: 500),
    this.maxRetryDelay = const Duration(seconds: 4),
    NetworkDelay? delay,
    NetworkClock? clock,
  }) : _client = client ?? http.Client(),
       _delay = delay ?? defaultNetworkDelay,
       _clock = clock ?? DateTime.now;

  final http.Client _client;
  final NetworkDelay _delay;
  final NetworkClock _clock;
  final Duration timeout;
  final int maxRetries;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;

  void dispose() => _client.close();

  @override
  Future<List<OutdoorPoi>> poisAlongRoute(
    List<GeoPoint> geometry, {
    double corridorMeters = 800,
  }) async {
    if (geometry.length < 2) {
      return const [];
    }
    final bounds = _boundsFor(geometry, paddingMeters: corridorMeters);
    final bbox = [
      bounds.south,
      bounds.west,
      bounds.north,
      bounds.east,
    ].join(',');
    final query =
        '[out:json][timeout:18];('
        'nwr["amenity"="drinking_water"](' + bbox + ');'
        'nwr["amenity"="toilets"](' + bbox + ');'
        'nwr["amenity"="parking"](' + bbox + ');'
        'nwr["tourism"="viewpoint"](' + bbox + ');'
        'nwr["tourism"="alpine_hut"](' + bbox + ');'
        'nwr["tourism"="wilderness_hut"](' + bbox + ');'
        'nwr["amenity"="shelter"](' + bbox + ');'
        ');out center tags;';

    final response = await _postOverpass(query);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
      return const [];
    }

    final pois = <OutdoorPoi>[];
    for (final raw in decoded['elements'] as List) {
      if (raw is! Map) {
        continue;
      }
      final element = Map<String, dynamic>.from(raw);
      final tagsRaw = element['tags'];
      final tags = tagsRaw is Map
          ? Map<String, dynamic>.from(tagsRaw)
          : const <String, dynamic>{};
      final point = _elementPoint(element);
      final type = _poiType(tags);
      if (point == null || type == null) {
        continue;
      }
      final distance = distanceToPolylineMeters(point, geometry);
      if (distance > corridorMeters) {
        continue;
      }

      final elementType = element['type']?.toString() ?? 'osm';
      final elementId = element['id']?.toString() ?? pois.length.toString();
      pois.add(
        OutdoorPoi(
          id: elementType + ':' + elementId,
          type: type,
          name: (tags['name'] as String?)?.trim().isNotEmpty == true
              ? tags['name'] as String
              : _fallbackPoiName(type),
          point: point,
          distanceFromRouteMeters: distance,
        ),
      );
    }

    pois.sort(
      (a, b) => a.distanceFromRouteMeters.compareTo(b.distanceFromRouteMeters),
    );
    return List<OutdoorPoi>.unmodifiable(pois.take(80));
  }

  @override
  Future<List<RouteWeatherSample>> weatherAlongRoute(
    List<GeoPoint> geometry, {
    int samples = 5,
  }) async {
    if (geometry.isEmpty) {
      return const [];
    }
    final count = samples.clamp(1, 7);
    final points = <GeoPoint>[
      for (var i = 0; i < count; i++)
        pointAlongPolyline(
          geometry,
          fraction: count == 1 ? 0.5 : i / (count - 1),
        ),
    ];

    final result = <RouteWeatherSample>[];
    for (final point in points) {
      final uri = Uri.parse(MapConfig.weatherEndpoint).replace(
        queryParameters: {
          'latitude': point.latitude.toStringAsFixed(6),
          'longitude': point.longitude.toStringAsFixed(6),
          'current': 'temperature_2m,precipitation,wind_speed_10m',
          'timezone': 'auto',
        },
      );
      final response = await _request(() => _client.get(uri));
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      final currentRaw = decoded['current'];
      if (currentRaw is! Map) {
        continue;
      }
      final current = Map<String, dynamic>.from(currentRaw);
      final temperature = current['temperature_2m'];
      final precipitation = current['precipitation'];
      final wind = current['wind_speed_10m'];
      final time = DateTime.tryParse(current['time'] as String? ?? '');
      if (temperature is! num ||
          precipitation is! num ||
          wind is! num ||
          time == null) {
        continue;
      }
      result.add(
        RouteWeatherSample(
          point: point,
          temperatureCelsius: temperature.toDouble(),
          precipitationMm: precipitation.toDouble(),
          windKmh: wind.toDouble(),
          observedAt: time,
        ),
      );
    }

    return List<RouteWeatherSample>.unmodifiable(result);
  }

  @override
  Future<RouteSurfaceSummary> surfaceSummary(
    List<GeoPoint> geometry,
  ) async {
    if (geometry.length < 2) {
      return const RouteSurfaceSummary(
        sampleCount: 0,
        counts: <RouteSurfaceType, int>{},
      );
    }

    final bounds = _boundsFor(geometry, paddingMeters: 120);
    final bbox = [
      bounds.south,
      bounds.west,
      bounds.north,
      bounds.east,
    ].join(',');
    final query =
        '[out:json][timeout:18];'
        'way["highway"](' + bbox + ');out geom tags;';

    final response = await _postOverpass(query);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
      return const RouteSurfaceSummary(
        sampleCount: 0,
        counts: <RouteSurfaceType, int>{},
      );
    }

    final ways = <_SurfaceWay>[];
    for (final raw in decoded['elements'] as List) {
      if (raw is! Map) {
        continue;
      }
      final element = Map<String, dynamic>.from(raw);
      final geometryRaw = element['geometry'];
      if (geometryRaw is! List) {
        continue;
      }
      final points = <GeoPoint>[];
      for (final rawPoint in geometryRaw) {
        if (rawPoint is! Map) {
          continue;
        }
        final value = Map<String, dynamic>.from(rawPoint);
        final lat = value['lat'];
        final lon = value['lon'];
        if (lat is num && lon is num) {
          points.add(
            GeoPoint(latitude: lat.toDouble(), longitude: lon.toDouble()),
          );
        }
      }
      if (points.length < 2) {
        continue;
      }
      final tagsRaw = element['tags'];
      final tags = tagsRaw is Map
          ? Map<String, dynamic>.from(tagsRaw)
          : const <String, dynamic>{};
      ways.add(
        _SurfaceWay(
          geometry: points,
          type: _surfaceType(tags),
        ),
      );
    }

    final counts = <RouteSurfaceType, int>{};
    const routeSamples = 80;
    for (var i = 0; i < routeSamples; i++) {
      final point = pointAlongPolyline(
        geometry,
        fraction: i / (routeSamples - 1),
      );
      _SurfaceWay? nearest;
      var nearestDistance = double.infinity;
      for (final way in ways) {
        final distance = distanceToPolylineMeters(point, way.geometry);
        if (distance < nearestDistance) {
          nearest = way;
          nearestDistance = distance;
        }
      }
      final type = nearest != null && nearestDistance <= 45
          ? nearest.type
          : RouteSurfaceType.unknown;
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return RouteSurfaceSummary(
      sampleCount: routeSamples,
      counts: Map<RouteSurfaceType, int>.unmodifiable(counts),
    );
  }

  Future<http.Response> _postOverpass(String query) {
    return _request(
      () => _client.post(
        Uri.parse(MapConfig.overpassEndpoint),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
          'User-Agent': MapConfig.userAgent,
        },
        body: {'data': query},
      ),
    );
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await request().timeout(timeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        if (!isTransientHttpStatus(response.statusCode) ||
            attempt == maxRetries) {
          throw StateError(
            'Outdoor context service returned HTTP ' +
                response.statusCode.toString() +
                '.',
          );
        }
        await _delay(_retryDelay(response, attempt));
      } on TimeoutException catch (error) {
        lastError = error;
        if (attempt == maxRetries) {
          rethrow;
        }
        await _delay(_retryDelay(null, attempt));
      } on http.ClientException catch (error) {
        lastError = error;
        if (attempt == maxRetries) {
          rethrow;
        }
        await _delay(_retryDelay(null, attempt));
      }
    }
    throw StateError('Outdoor context request failed: ' + lastError.toString());
  }

  Duration _retryDelay(http.Response? response, int attempt) {
    return retryAfterDelay(
          response?.headers['retry-after'],
          now: _clock(),
          maxDelay: maxRetryDelay,
        ) ??
        exponentialBackoff(
          attempt: attempt,
          baseDelay: retryBaseDelay,
          maxDelay: maxRetryDelay,
        );
  }
}

class _SurfaceWay {
  const _SurfaceWay({required this.geometry, required this.type});

  final List<GeoPoint> geometry;
  final RouteSurfaceType type;
}

class _Bounds {
  const _Bounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  final double north;
  final double south;
  final double east;
  final double west;
}

_Bounds _boundsFor(
  List<GeoPoint> points, {
  required double paddingMeters,
}) {
  var north = -90.0;
  var south = 90.0;
  var east = -180.0;
  var west = 180.0;
  for (final point in points) {
    north = math.max(north, point.latitude);
    south = math.min(south, point.latitude);
    east = math.max(east, point.longitude);
    west = math.min(west, point.longitude);
  }

  final centerLat = (north + south) / 2;
  final latPadding = paddingMeters / 111320;
  final lonScale = math.max(
    0.15,
    math.cos(centerLat * math.pi / 180).abs(),
  );
  final lonPadding = paddingMeters / (111320 * lonScale);
  return _Bounds(
    north: math.min(90, north + latPadding),
    south: math.max(-90, south - latPadding),
    east: math.min(180, east + lonPadding),
    west: math.max(-180, west - lonPadding),
  );
}

GeoPoint? _elementPoint(Map<String, dynamic> element) {
  final lat = element['lat'];
  final lon = element['lon'];
  if (lat is num && lon is num) {
    return GeoPoint(latitude: lat.toDouble(), longitude: lon.toDouble());
  }
  final centerRaw = element['center'];
  if (centerRaw is Map) {
    final center = Map<String, dynamic>.from(centerRaw);
    final centerLat = center['lat'];
    final centerLon = center['lon'];
    if (centerLat is num && centerLon is num) {
      return GeoPoint(
        latitude: centerLat.toDouble(),
        longitude: centerLon.toDouble(),
      );
    }
  }
  return null;
}

OutdoorPoiType? _poiType(Map<String, dynamic> tags) {
  return switch ((tags['amenity'], tags['tourism'])) {
    ('drinking_water', _) => OutdoorPoiType.drinkingWater,
    ('toilets', _) => OutdoorPoiType.toilets,
    ('parking', _) => OutdoorPoiType.parking,
    ('shelter', _) => OutdoorPoiType.shelter,
    (_, 'alpine_hut') => OutdoorPoiType.alpineHut,
    (_, 'wilderness_hut') => OutdoorPoiType.shelter,
    (_, 'viewpoint') => OutdoorPoiType.viewpoint,
    _ => null,
  };
}

String _fallbackPoiName(OutdoorPoiType type) {
  return switch (type) {
    OutdoorPoiType.drinkingWater => 'Drinking water',
    OutdoorPoiType.shelter => 'Shelter',
    OutdoorPoiType.alpineHut => 'Alpine hut',
    OutdoorPoiType.viewpoint => 'Viewpoint',
    OutdoorPoiType.parking => 'Parking',
    OutdoorPoiType.toilets => 'Toilets',
  };
}

RouteSurfaceType _surfaceType(Map<String, dynamic> tags) {
  final surface = (tags['surface'] as String?)?.toLowerCase();
  final highway = (tags['highway'] as String?)?.toLowerCase();

  if (const {
    'asphalt',
    'concrete',
    'concrete:plates',
    'paved',
    'paving_stones',
    'sett',
  }.contains(surface)) {
    return RouteSurfaceType.paved;
  }
  if (const {
    'gravel',
    'fine_gravel',
    'compacted',
    'pebblestone',
  }.contains(surface)) {
    return RouteSurfaceType.gravel;
  }
  if (const {
    'dirt',
    'earth',
    'ground',
    'sand',
    'mud',
  }.contains(surface)) {
    return RouteSurfaceType.dirt;
  }
  if (const {
        'unpaved',
        'grass',
        'woodchips',
      }.contains(surface) ||
      highway == 'path' ||
      highway == 'track' ||
      highway == 'bridleway') {
    return RouteSurfaceType.trail;
  }
  return RouteSurfaceType.unknown;
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/map_matching.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/network/http_retry.dart';

class ValhallaMapMatchingEngine implements MapMatchingEngine {
  ValhallaMapMatchingEngine({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 18),
    this.maxRetries = 2,
    this.retryBaseDelay = const Duration(milliseconds: 450),
    this.maxRetryDelay = const Duration(seconds: 5),
    NetworkDelay? delay,
    NetworkClock? clock,
  }) : _client = client ?? http.Client(),
       endpoint = endpoint ?? Uri.parse(MapConfig.mapMatchingEndpoint),
       _delay = delay ?? defaultNetworkDelay,
       _clock = clock ?? DateTime.now;

  final http.Client _client;
  final Uri endpoint;
  final NetworkDelay _delay;
  final NetworkClock _clock;
  final Duration timeout;
  final int maxRetries;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;

  @override
  String get engineId => 'valhalla.trace_route';

  void dispose() => _client.close();

  @override
  Future<TraceMatchResult> match(TraceMatchRequest request) async {
    if (request.mode == MapMatchMode.free) {
      throw const MapMatchingException(
        'Free trace mode does not require map matching.',
      );
    }
    if (request.trace.length < 2) {
      throw const MapMatchingException('Trace requires at least two points.');
    }

    final sampled = request.trace.length <= 95
        ? request.trace
        : <GeoPoint>[
            for (var i = 0; i < 95; i++)
              request.trace[(i * (request.trace.length - 1) / 94)
                  .round()
                  .clamp(0, request.trace.length - 1)
                  .toInt()],
          ];

    final costing = _costing(request.profile);
    final body = <String, Object?>{
      'shape': [
        for (final point in sampled)
          <String, double>{'lat': point.latitude, 'lon': point.longitude},
      ],
      'costing': costing,
      'shape_match': 'walk_or_snap',
      'shape_format': 'geojson',
      'directions_type': 'none',
      'units': 'km',
      'trace_options': <String, Object?>{
        'gps_accuracy': 10,
        'search_radius': request.mode == MapMatchMode.trails ? 32 : 26,
        'turn_penalty_factor': request.mode == MapMatchMode.trails ? 700 : 550,
        'breakage_distance': 800,
        'interpolation_distance': 5,
      },
      if (costing == 'bicycle')
        'costing_options': <String, Object?>{
          'bicycle': <String, Object?>{
            'bicycle_type': request.mode == MapMatchMode.trails
                ? 'mountain'
                : 'road',
            'use_roads': request.mode == MapMatchMode.trails ? 0.10 : 0.95,
            'avoid_bad_surfaces': request.mode == MapMatchMode.trails
                ? 0.0
                : 0.90,
          },
        },
    };

    final response = await _request(jsonEncode(body));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MapMatchingException('Invalid map-matching response.');
    }

    final trip = decoded['trip'];
    if (trip is! Map) {
      throw const MapMatchingException('Map-matching trip is missing.');
    }

    final legs = trip['legs'];
    if (legs is! List || legs.isEmpty) {
      throw const MapMatchingException('Map-matching geometry is missing.');
    }

    final geometry = <GeoPoint>[];
    for (final rawLeg in legs) {
      if (rawLeg is! Map) {
        continue;
      }
      final leg = Map<String, dynamic>.from(rawLeg);
      final legPoints = _decodeShape(leg['shape']);
      if (legPoints.isEmpty) {
        continue;
      }
      if (geometry.isEmpty) {
        geometry.addAll(legPoints);
      } else {
        final seam = haversineMeters(geometry.last, legPoints.first);
        geometry.addAll(seam <= 2 ? legPoints.skip(1) : legPoints);
      }
    }

    if (geometry.length < 2) {
      throw const MapMatchingException(
        'Map-matching returned an incomplete path.',
      );
    }

    _validateTraceFidelity(sampled, geometry, request.mode);

    final summary = trip['summary'];
    final summaryMap = summary is Map
        ? Map<String, dynamic>.from(summary)
        : const <String, dynamic>{};
    final lengthKm = (summaryMap['length'] as num?)?.toDouble();
    final durationSeconds = (summaryMap['time'] as num?)?.round();
    final distance = lengthKm != null && lengthKm > 0
        ? lengthKm * 1000
        : calculateRouteDistanceMeters(geometry);

    return TraceMatchResult(
      geometry: List<GeoPoint>.unmodifiable(geometry),
      distanceMeters: distance,
      estimatedDuration: Duration(seconds: durationSeconds ?? 0),
      source: engineId,
    );
  }

  void _validateTraceFidelity(
    List<GeoPoint> trace,
    List<GeoPoint> geometry,
    MapMatchMode mode,
  ) {
    final traceLimitMeters = mode == MapMatchMode.trails ? 60.0 : 45.0;
    final geometryLimitMeters = mode == MapMatchMode.trails ? 90.0 : 70.0;

    for (final point in _sampleGeoPoints(trace, maxItems: 48)) {
      if (distanceToPolylineMeters(point, geometry) > traceLimitMeters) {
        throw const MapMatchingException(
          'Matched route moved too far away from the drawn trace.',
        );
      }
    }

    for (final point in _sampleGeoPoints(geometry, maxItems: 64)) {
      if (distanceToPolylineMeters(point, trace) > geometryLimitMeters) {
        throw const MapMatchingException(
          'Matched route contains a detour outside the drawn corridor.',
        );
      }
    }
  }

  List<GeoPoint> _decodeShape(Object? raw) {
    if (raw is Map) {
      final shape = Map<String, dynamic>.from(raw);
      final coordinates = shape['coordinates'];
      if (coordinates is! List) {
        return const [];
      }
      return <GeoPoint>[
        for (final coordinate in coordinates)
          if (coordinate is List &&
              coordinate.length >= 2 &&
              coordinate[0] is num &&
              coordinate[1] is num)
            GeoPoint(
              latitude: (coordinate[1] as num).toDouble(),
              longitude: (coordinate[0] as num).toDouble(),
            ),
      ];
    }
    if (raw is String && raw.isNotEmpty) {
      return decodeValhallaPolyline6(raw);
    }
    return const [];
  }

  String _costing(RouteProfile profile) {
    return switch (profile) {
      RouteProfile.mountainBike || RouteProfile.cycling => 'bicycle',
      RouteProfile.hiking ||
      RouteProfile.trailRunning ||
      RouteProfile.walking ||
      RouteProfile.dogWalk => 'pedestrian',
    };
  }

  Future<http.Response> _request(String body) async {
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client
            .post(
              endpoint,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'X-Client-Id': MapConfig.userAgent,
              },
              body: body,
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return response;
        }

        if (!isTransientHttpStatus(response.statusCode) ||
            attempt == maxRetries) {
          throw MapMatchingException(
            'Map matching returned HTTP ${response.statusCode}.',
          );
        }
        await _delay(_retryDelay(response, attempt));
      } on TimeoutException {
        if (attempt == maxRetries) {
          throw const MapMatchingException('Map matching timed out.');
        }
        await _delay(_retryDelay(null, attempt));
      } on http.ClientException catch (error) {
        lastError = error;
        if (attempt == maxRetries) {
          throw MapMatchingException(
            'Map matching network request failed: ${error.message}',
          );
        }
        await _delay(_retryDelay(null, attempt));
      }
    }
    throw MapMatchingException('Map matching failed: $lastError');
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

List<GeoPoint> _sampleGeoPoints(
  List<GeoPoint> points, {
  required int maxItems,
}) {
  if (points.length <= maxItems) {
    return points;
  }
  return <GeoPoint>[
    for (var i = 0; i < maxItems; i++)
      points[(i * (points.length - 1) / (maxItems - 1))
          .round()
          .clamp(0, points.length - 1)
          .toInt()],
  ];
}

List<GeoPoint> decodeValhallaPolyline6(String encoded) {
  final points = <GeoPoint>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;

  int decodeValue() {
    var result = 0;
    var shift = 0;
    while (index < encoded.length) {
      final byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      if (byte < 0x20) {
        break;
      }
    }
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    latitude += decodeValue();
    if (index >= encoded.length) {
      break;
    }
    longitude += decodeValue();
    points.add(GeoPoint(latitude: latitude / 1e6, longitude: longitude / 1e6));
  }
  return List<GeoPoint>.unmodifiable(points);
}

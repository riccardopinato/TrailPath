import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/elevation_math.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/network/http_retry.dart';

class OpenMeteoElevationEngine implements ElevationEngine {
  OpenMeteoElevationEngine({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.maxSamples = 100,
    this.maxRetries = 2,
    this.retryBaseDelay = const Duration(milliseconds: 350),
    this.maxRetryDelay = const Duration(seconds: 4),
    NetworkDelay? delay,
    NetworkClock? clock,
  }) : assert(maxSamples >= 2),
       assert(maxRetries >= 0),
       _client = client ?? http.Client(),
       _delay = delay ?? defaultNetworkDelay,
       _clock = clock ?? DateTime.now;

  final http.Client _client;
  final NetworkDelay _delay;
  final NetworkClock _clock;
  final Duration timeout;
  final int maxSamples;
  final int maxRetries;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;

  @override
  String get engineId => 'open-meteo-elevation';

  void dispose() => _client.close();

  @override
  Future<ElevationProfile> resolve(List<GeoPoint> points) async {
    if (points.length < 2) {
      return const ElevationProfile.unavailable();
    }

    final sampled = resampleRouteByDistance(
      points,
      maxPoints: maxSamples.clamp(2, 100).toInt(),
    );

    final latitudes = sampled
        .map((point) => point.latitude.toStringAsFixed(6))
        .join(',');
    final longitudes = sampled
        .map((point) => point.longitude.toStringAsFixed(6))
        .join(',');

    final uri = Uri.https('api.open-meteo.com', '/v1/elevation', {
      'latitude': latitudes,
      'longitude': longitudes,
    });

    final response = await _request(uri);
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const ElevationException('Invalid elevation response.');
    }

    final rawElevations = payload['elevation'];
    if (rawElevations is! List || rawElevations.length != sampled.length) {
      throw const ElevationException('Elevation payload size mismatch.');
    }

    final elevated = <GeoPoint>[];
    for (var index = 0; index < sampled.length; index++) {
      final value = rawElevations[index];
      if (value is! num) {
        throw const ElevationException('Elevation value is invalid.');
      }
      elevated.add(sampled[index].copyWith(elevationMeters: value.toDouble()));
    }

    return buildElevationProfile(elevated, source: engineId);
  }

  Future<http.Response> _request(Uri uri) async {
    Object? lastNetworkError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
                if (!kIsWeb) 'User-Agent': MapConfig.userAgent,
              },
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return response;
        }

        if (!isTransientHttpStatus(response.statusCode) ||
            attempt == maxRetries) {
          throw ElevationException(
            'Elevation service returned HTTP ${response.statusCode}.',
          );
        }

        await _delay(_retryDelay(response, attempt));
      } on TimeoutException catch (error) {
        lastNetworkError = error;
        if (attempt == maxRetries) {
          throw ElevationException(
            'Elevation request timed out after ${maxRetries + 1} attempts.',
          );
        }
        await _delay(_retryDelay(null, attempt));
      } on http.ClientException catch (error) {
        lastNetworkError = error;
        if (attempt == maxRetries) {
          throw ElevationException(
            'Elevation network request failed after ${maxRetries + 1} attempts: '
            '${error.message}',
          );
        }
        await _delay(_retryDelay(null, attempt));
      }
    }

    throw ElevationException('Elevation request failed: $lastNetworkError');
  }

  Duration _retryDelay(http.Response? response, int attempt) {
    final retryAfter = retryAfterDelay(
      response?.headers['retry-after'],
      now: _clock(),
      maxDelay: maxRetryDelay,
    );
    if (retryAfter != null) {
      return retryAfter;
    }

    return exponentialBackoff(
      attempt: attempt,
      baseDelay: retryBaseDelay,
      maxDelay: maxRetryDelay,
    );
  }
}

class FallbackElevationEngine implements ElevationEngine {
  const FallbackElevationEngine({
    required this.primary,
    required this.fallback,
  });

  final ElevationEngine primary;
  final ElevationEngine fallback;

  @override
  String get engineId => '${primary.engineId}+${fallback.engineId}';

  @override
  Future<ElevationProfile> resolve(List<GeoPoint> points) async {
    try {
      return await primary.resolve(points);
    } on Object {
      return fallback.resolve(points);
    }
  }
}

class UnavailableElevationEngine implements ElevationEngine {
  const UnavailableElevationEngine();

  @override
  String get engineId => 'unavailable';

  @override
  Future<ElevationProfile> resolve(List<GeoPoint> points) async {
    return const ElevationProfile.unavailable();
  }
}

List<GeoPoint> resampleRouteByDistance(
  List<GeoPoint> points, {
  int maxPoints = 100,
}) {
  if (points.length <= 2 || points.length <= maxPoints) {
    return List<GeoPoint>.unmodifiable(points);
  }

  final cumulative = <double>[0];
  for (var index = 1; index < points.length; index++) {
    cumulative.add(
      cumulative.last + haversineMeters(points[index - 1], points[index]),
    );
  }

  final total = cumulative.last;
  if (total <= 0) {
    return [points.first, points.last];
  }

  final result = <GeoPoint>[];
  var segmentIndex = 1;

  for (var sampleIndex = 0; sampleIndex < maxPoints; sampleIndex++) {
    final targetDistance = total * sampleIndex / (maxPoints - 1);

    while (segmentIndex < cumulative.length - 1 &&
        cumulative[segmentIndex] < targetDistance) {
      segmentIndex++;
    }

    final beforeIndex = (segmentIndex - 1).clamp(0, points.length - 1).toInt();
    final afterIndex = segmentIndex.clamp(0, points.length - 1).toInt();
    final beforeDistance = cumulative[beforeIndex];
    final afterDistance = cumulative[afterIndex];
    final span = afterDistance - beforeDistance;
    final ratio = span <= 0
        ? 0.0
        : ((targetDistance - beforeDistance) / span).clamp(0.0, 1.0);

    final before = points[beforeIndex];
    final after = points[afterIndex];

    result.add(
      GeoPoint(
        latitude: before.latitude + (after.latitude - before.latitude) * ratio,
        longitude:
            before.longitude + (after.longitude - before.longitude) * ratio,
      ),
    );
  }

  return List<GeoPoint>.unmodifiable(result);
}

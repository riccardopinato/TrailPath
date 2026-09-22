import 'dart:convert';
import 'dart:io';

import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class OpenMeteoElevationEngine implements ElevationEngine {
  const OpenMeteoElevationEngine({
    this.timeout = const Duration(seconds: 12),
    this.maxSamples = 100,
  });

  final Duration timeout;
  final int maxSamples;

  @override
  String get engineId => 'open-meteo-elevation';

  @override
  Future<ElevationProfile> resolve(List<GeoPoint> points) async {
    if (points.length < 2) {
      return const ElevationProfile.unavailable();
    }

    final sampled = resampleRouteByDistance(
      points,
      maxPoints: maxSamples.clamp(2, 100),
    );

    final latitudes = sampled
        .map((point) => point.latitude.toStringAsFixed(6))
        .join(',');
    final longitudes = sampled
        .map((point) => point.longitude.toStringAsFixed(6))
        .join(',');

    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/elevation',
      {
        'latitude': latitudes,
        'longitude': longitudes,
      },
    );

    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = 'TrailPath/0.4.0';

    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw ElevationException(
          'Elevation service returned HTTP ${response.statusCode}.',
        );
      }

      final body = await response.transform(utf8.decoder).join();
      final payload = jsonDecode(body);
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
        elevated.add(
          sampled[index].copyWith(elevationMeters: value.toDouble()),
        );
      }

      return buildElevationProfile(
        elevated,
        source: engineId,
      );
    } finally {
      client.close(force: true);
    }
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

ElevationProfile buildElevationProfile(
  List<GeoPoint> elevatedPoints, {
  required String source,
  double noiseThresholdMeters = 2,
}) {
  if (elevatedPoints.length < 2 ||
      elevatedPoints.any((point) => point.elevationMeters == null)) {
    return const ElevationProfile.unavailable();
  }

  final samples = <ElevationSample>[];
  var cumulativeDistance = 0.0;
  var ascent = 0.0;
  var descent = 0.0;
  var minElevation = elevatedPoints.first.elevationMeters!;
  var maxElevation = elevatedPoints.first.elevationMeters!;

  samples.add(
    ElevationSample(
      point: elevatedPoints.first,
      distanceMeters: 0,
      gradePercent: 0,
    ),
  );

  for (var index = 1; index < elevatedPoints.length; index++) {
    final previous = elevatedPoints[index - 1];
    final current = elevatedPoints[index];
    final segmentDistance = haversineMeters(previous, current);
    cumulativeDistance += segmentDistance;

    final previousElevation = previous.elevationMeters!;
    final currentElevation = current.elevationMeters!;
    final delta = currentElevation - previousElevation;

    if (delta.abs() >= noiseThresholdMeters) {
      if (delta > 0) {
        ascent += delta;
      } else {
        descent += -delta;
      }
    }

    if (currentElevation < minElevation) {
      minElevation = currentElevation;
    }
    if (currentElevation > maxElevation) {
      maxElevation = currentElevation;
    }

    final grade = segmentDistance <= 0
        ? 0.0
        : (delta / segmentDistance * 100).clamp(-60.0, 60.0).toDouble();

    samples.add(
      ElevationSample(
        point: current,
        distanceMeters: cumulativeDistance,
        gradePercent: grade,
      ),
    );
  }

  return ElevationProfile(
    points: List<GeoPoint>.unmodifiable(elevatedPoints),
    samples: List<ElevationSample>.unmodifiable(samples),
    ascentMeters: ascent,
    descentMeters: descent,
    minElevationMeters: minElevation,
    maxElevationMeters: maxElevation,
    isAvailable: true,
    source: source,
  );
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
    return [
      points.first,
      points.last,
    ];
  }

  final result = <GeoPoint>[];
  var segmentIndex = 1;

  for (var sampleIndex = 0; sampleIndex < maxPoints; sampleIndex++) {
    final targetDistance = total * sampleIndex / (maxPoints - 1);

    while (segmentIndex < cumulative.length - 1 &&
        cumulative[segmentIndex] < targetDistance) {
      segmentIndex++;
    }

    final beforeIndex = (segmentIndex - 1).clamp(0, points.length - 1);
    final afterIndex = segmentIndex.clamp(0, points.length - 1);
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
        latitude:
            before.latitude + (after.latitude - before.latitude) * ratio,
        longitude:
            before.longitude + (after.longitude - before.longitude) * ratio,
      ),
    );
  }

  return List<GeoPoint>.unmodifiable(result);
}

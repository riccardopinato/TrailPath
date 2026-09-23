import 'dart:convert';
import 'dart:io';

import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class OpenStreetMapRoutingEngine implements RoutingEngine {
  const OpenStreetMapRoutingEngine({
    this.timeout = const Duration(seconds: 12),
  });

  final Duration timeout;

  @override
  String get engineId => 'routing.openstreetmap.de';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    if (request.points.length < 2) {
      return RoutePlan(
        geometry: request.points,
        distanceMeters: 0,
        ascentMeters: 0,
        descentMeters: 0,
        estimatedDuration: Duration.zero,
        profile: request.profile,
        isSnapped: false,
        routingSource: engineId,
      );
    }

    final service = _serviceFor(request.profile);
    final coordinates = request.points
        .map(
          (point) =>
              '${point.longitude.toStringAsFixed(6)},${point.latitude.toStringAsFixed(6)}',
        )
        .join(';');

    final uri = Uri.parse(
      'https://routing.openstreetmap.de/'
      '$service/route/v1/driving/$coordinates',
    ).replace(
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = MapConfig.userAgent;

    try {
      final requestHttp = await client.getUrl(uri).timeout(timeout);
      requestHttp.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await requestHttp.close().timeout(timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw RoutingException(
          'Routing service returned HTTP ${response.statusCode}.',
        );
      }

      final body = await response.transform(utf8.decoder).join().timeout(timeout);
      final payload = jsonDecode(body);
      if (payload is! Map<String, dynamic>) {
        throw const RoutingException('Invalid routing response.');
      }

      final code = payload['code'];
      if (code != 'Ok') {
        throw RoutingException('Routing failed: $code');
      }

      final routes = payload['routes'];
      if (routes is! List || routes.isEmpty) {
        throw const RoutingException('No route found.');
      }

      final route = routes.first;
      if (route is! Map<String, dynamic>) {
        throw const RoutingException('Invalid route payload.');
      }

      final geometry = route['geometry'];
      if (geometry is! Map<String, dynamic>) {
        throw const RoutingException('Missing route geometry.');
      }

      final coordinatesJson = geometry['coordinates'];
      if (coordinatesJson is! List || coordinatesJson.length < 2) {
        throw const RoutingException('Route geometry is empty.');
      }

      final points = <GeoPoint>[];
      for (final coordinate in coordinatesJson) {
        if (coordinate is! List || coordinate.length < 2) {
          continue;
        }
        final longitude = coordinate[0];
        final latitude = coordinate[1];
        if (longitude is num && latitude is num) {
          points.add(
            GeoPoint(
              latitude: latitude.toDouble(),
              longitude: longitude.toDouble(),
            ),
          );
        }
      }

      if (points.length < 2) {
        throw const RoutingException('Route geometry could not be decoded.');
      }

      final distance = (route['distance'] as num?)?.toDouble() ?? 0;
      final seconds = (route['duration'] as num?)?.round() ?? 0;

      return RoutePlan(
        geometry: List<GeoPoint>.unmodifiable(points),
        distanceMeters: distance,
        ascentMeters: 0,
        descentMeters: 0,
        estimatedDuration: Duration(seconds: seconds),
        profile: request.profile,
        isSnapped: true,
        routingSource: engineId,
      );
    } finally {
      client.close(force: true);
    }
  }

  String _serviceFor(RouteProfile profile) {
    return switch (profile) {
      RouteProfile.mountainBike || RouteProfile.cycling => 'routed-bike',
      RouteProfile.hiking ||
      RouteProfile.trailRunning ||
      RouteProfile.walking ||
      RouteProfile.dogWalk => 'routed-foot',
    };
  }
}

class FallbackRoutingEngine implements RoutingEngine {
  const FallbackRoutingEngine({
    required this.primary,
    required this.fallback,
  });

  final RoutingEngine primary;
  final RoutingEngine fallback;

  @override
  String get engineId => '${primary.engineId}+${fallback.engineId}';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    if (!request.snapToNetwork) {
      return fallback.calculate(request);
    }

    try {
      return await primary.calculate(request);
    } on Object {
      return fallback.calculate(request);
    }
  }
}

class StraightLineRoutingEngine implements RoutingEngine {
  const StraightLineRoutingEngine();

  @override
  String get engineId => 'straight-line';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    final distance = calculateRouteDistanceMeters(request.points);
    final speedKmh = switch (request.profile) {
      RouteProfile.hiking => 4.5,
      RouteProfile.trailRunning => 9.0,
      RouteProfile.walking => 4.8,
      RouteProfile.mountainBike => 15.0,
      RouteProfile.cycling => 18.0,
      RouteProfile.dogWalk => 4.0,
    };
    final seconds = distance <= 0
        ? 0
        : (distance / 1000 / speedKmh * 3600).round();

    return RoutePlan(
      geometry: List<GeoPoint>.unmodifiable(request.points),
      distanceMeters: distance,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: Duration(seconds: seconds),
      profile: request.profile,
      isSnapped: false,
      routingSource: engineId,
    );
  }
}

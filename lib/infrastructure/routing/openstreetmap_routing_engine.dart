import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/network/http_retry.dart';

class OpenStreetMapRoutingEngine implements RoutingEngine {
  OpenStreetMapRoutingEngine({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.maxWaypointsPerRequest = 20,
    this.maxRetries = 2,
    this.retryBaseDelay = const Duration(milliseconds: 350),
    this.maxRetryDelay = const Duration(seconds: 4),
    NetworkDelay? delay,
    NetworkClock? clock,
  }) : assert(maxWaypointsPerRequest >= 2),
       assert(maxRetries >= 0),
       _client = client ?? http.Client(),
       _delay = delay ?? defaultNetworkDelay,
       _clock = clock ?? DateTime.now;

  final http.Client _client;
  final NetworkDelay _delay;
  final NetworkClock _clock;
  final Duration timeout;
  final int maxWaypointsPerRequest;
  final int maxRetries;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;

  @override
  String get engineId => 'routing.openstreetmap.de';

  void dispose() => _client.close();

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

    final chunks = chunkRouteWaypoints(
      request.points,
      maxPointsPerChunk: maxWaypointsPerRequest,
    );
    if (chunks.length == 1) {
      return _calculateSingle(
        RouteRequest(
          points: chunks.single,
          profile: request.profile,
          snapToNetwork: request.snapToNetwork,
        ),
      );
    }

    final plans = <RoutePlan>[];
    for (final chunk in chunks) {
      plans.add(
        await _calculateSingle(
          RouteRequest(
            points: chunk,
            profile: request.profile,
            snapToNetwork: request.snapToNetwork,
          ),
        ),
      );
    }

    if (plans.any((plan) => !plan.isSnapped)) {
      throw const RoutingException(
        'A routing chunk could not be snapped to the network.',
      );
    }

    final geometry = <GeoPoint>[];
    final snappedWaypoints = <GeoPoint>[];
    var distanceMeters = 0.0;
    var durationSeconds = 0;

    for (var index = 0; index < plans.length; index++) {
      final plan = plans[index];
      distanceMeters += plan.distanceMeters;
      durationSeconds += plan.estimatedDuration.inSeconds;

      if (index == 0) {
        geometry.addAll(plan.geometry);
        snappedWaypoints.addAll(plan.snappedWaypoints);
        continue;
      }

      if (plan.geometry.isNotEmpty) {
        final seamDistance = geometry.isEmpty
            ? double.infinity
            : haversineMeters(geometry.last, plan.geometry.first);
        geometry.addAll(
          seamDistance <= 2 ? plan.geometry.skip(1) : plan.geometry,
        );
      }
      snappedWaypoints.addAll(
        plan.snappedWaypoints.isEmpty
            ? const <GeoPoint>[]
            : plan.snappedWaypoints.skip(1),
      );
    }

    if (geometry.length < 2 ||
        snappedWaypoints.length != request.points.length) {
      throw const RoutingException(
        'Chunked routing returned incomplete geometry.',
      );
    }

    return RoutePlan(
      geometry: List<GeoPoint>.unmodifiable(geometry),
      distanceMeters: distanceMeters,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: Duration(seconds: durationSeconds),
      profile: request.profile,
      isSnapped: true,
      routingSource: engineId,
      snappedWaypoints: List<GeoPoint>.unmodifiable(snappedWaypoints),
    );
  }

  Future<RoutePlan> _calculateSingle(RouteRequest request) async {
    final response = await _request(_buildUri(request));
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const RoutingException('Invalid routing response.');
    }

    final code = payload['code'];
    if (code != 'Ok') {
      throw RoutingException('Routing failed: $code');
    }

    final routes = payload['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) {
      throw const RoutingException('No route found.');
    }

    final route = Map<String, dynamic>.from(routes.first as Map);
    final geometryJson = route['geometry'];
    if (geometryJson is! Map) {
      throw const RoutingException('Missing route geometry.');
    }

    final coordinatesJson = geometryJson['coordinates'];
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

    final snappedWaypoints = <GeoPoint>[];
    final waypointsJson = payload['waypoints'];
    if (waypointsJson is List) {
      for (final waypoint in waypointsJson) {
        if (waypoint is! Map) {
          continue;
        }
        final location = waypoint['location'];
        if (location is! List || location.length < 2) {
          continue;
        }
        final longitude = location[0];
        final latitude = location[1];
        if (longitude is num && latitude is num) {
          snappedWaypoints.add(
            GeoPoint(
              latitude: latitude.toDouble(),
              longitude: longitude.toDouble(),
            ),
          );
        }
      }
    }

    if (snappedWaypoints.length != request.points.length) {
      throw const RoutingException('Waypoint snapping is incomplete.');
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
      snappedWaypoints: List<GeoPoint>.unmodifiable(snappedWaypoints),
    );
  }

  Uri _buildUri(RouteRequest request) {
    final service = _serviceFor(request.profile);
    final coordinates = request.points
        .map(
          (point) =>
              '${point.longitude.toStringAsFixed(6)},${point.latitude.toStringAsFixed(6)}',
        )
        .join(';');

    return Uri.parse(
      'https://routing.openstreetmap.de/'
      '$service/route/v1/driving/$coordinates',
    ).replace(
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );
  }

  Future<http.Response> _request(Uri uri) async {
    Object? lastNetworkError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: _requestHeaders())
            .timeout(timeout);

        if (response.statusCode == 200) {
          return response;
        }

        if (!isTransientHttpStatus(response.statusCode) ||
            attempt == maxRetries) {
          throw RoutingException(
            'Routing service returned HTTP ${response.statusCode}.',
          );
        }

        await _delay(_retryDelay(response, attempt));
      } on TimeoutException catch (error) {
        lastNetworkError = error;
        if (attempt == maxRetries) {
          throw RoutingException(
            'Routing request timed out after ${maxRetries + 1} attempts.',
          );
        }
        await _delay(_retryDelay(null, attempt));
      } on http.ClientException catch (error) {
        lastNetworkError = error;
        if (attempt == maxRetries) {
          throw RoutingException(
            'Routing network request failed after ${maxRetries + 1} attempts: '
            '${error.message}',
          );
        }
        await _delay(_retryDelay(null, attempt));
      }
    }

    throw RoutingException('Routing request failed: $lastNetworkError');
  }

  Map<String, String> _requestHeaders() {
    return {
      'Accept': 'application/json',
      if (!kIsWeb) 'User-Agent': MapConfig.userAgent,
    };
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
  const FallbackRoutingEngine({required this.primary, required this.fallback});

  final RoutingEngine primary;
  final RoutingEngine fallback;

  @override
  String get engineId => '${primary.engineId}+${fallback.engineId}';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    if (!request.snapToNetwork) {
      return fallback.calculate(request);
    }

    // A snapped outdoor route must be real or fail explicitly.
    // Never turn a provider failure into a fake straight-line route.
    return primary.calculate(request);
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

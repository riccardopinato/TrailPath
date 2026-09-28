import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/logging/app_logger.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/network/http_retry.dart';

class OpenStreetMapRoutingEngine implements RoutingEngine {
  OpenStreetMapRoutingEngine({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.maxWaypointsPerRequest = 8,
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
        kind: RoutingFailureKind.invalidResponse,
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
        kind: RoutingFailureKind.invalidResponse,
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
      throw const RoutingException(
        'Invalid routing response.',
        kind: RoutingFailureKind.invalidResponse,
      );
    }

    final code = payload['code'];
    if (code != 'Ok') {
      throw RoutingException(
        'Routing failed: $code',
        kind: code == 'NoRoute'
            ? RoutingFailureKind.noRoute
            : RoutingFailureKind.providerUnavailable,
      );
    }

    final routes = payload['routes'];
    if (routes is! List || routes.isEmpty) {
      throw const RoutingException(
        'No route found.',
        kind: RoutingFailureKind.noRoute,
      );
    }

    final routeCandidates = <Map<String, dynamic>>[
      for (final rawRoute in routes)
        if (rawRoute is Map) Map<String, dynamic>.from(rawRoute),
    ];
    if (routeCandidates.isEmpty) {
      throw const RoutingException(
        'No route found.',
        kind: RoutingFailureKind.noRoute,
      );
    }

    final route = request.points.length == 2 && routeCandidates.length > 1
        ? routeCandidates.reduce((best, candidate) {
            final bestDistance =
                (best['distance'] as num?)?.toDouble() ?? double.infinity;
            final candidateDistance =
                (candidate['distance'] as num?)?.toDouble() ?? double.infinity;
            return candidateDistance < bestDistance ? candidate : best;
          })
        : routeCandidates.first;
    final geometryJson = route['geometry'];
    if (geometryJson is! Map) {
      throw const RoutingException(
        'Missing route geometry.',
        kind: RoutingFailureKind.invalidResponse,
      );
    }

    final coordinatesJson = geometryJson['coordinates'];
    if (coordinatesJson is! List || coordinatesJson.length < 2) {
      throw const RoutingException(
        'Route geometry is empty.',
        kind: RoutingFailureKind.invalidResponse,
      );
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
      throw const RoutingException(
        'Route geometry could not be decoded.',
        kind: RoutingFailureKind.invalidResponse,
      );
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
      throw const RoutingException(
        'Waypoint snapping is incomplete.',
        kind: RoutingFailureKind.invalidResponse,
      );
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
      queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
        'continue_straight': 'false',
        'alternatives': request.points.length == 2 ? 'true' : 'false',
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
          AppLogger.warning(
            'routing provider=$engineId status=${response.statusCode} '
            'profile=${_serviceForProfileName(uri)} attempt=${attempt + 1}',
          );
          throw RoutingException(
            'Routing service returned HTTP ${response.statusCode}.',
            kind: response.statusCode == 429
                ? RoutingFailureKind.rateLimited
                : response.statusCode == 408
                ? RoutingFailureKind.timeout
                : response.statusCode >= 500
                ? RoutingFailureKind.providerUnavailable
                : RoutingFailureKind.invalidResponse,
          );
        }

        AppLogger.warning(
          'routing retry provider=$engineId status=${response.statusCode} '
          'attempt=${attempt + 1}/${maxRetries + 1}',
        );
        await _delay(_retryDelay(response, attempt));
      } on TimeoutException catch (error) {
        lastNetworkError = error;
        AppLogger.warning(
          'routing timeout provider=$engineId attempt=${attempt + 1}/${maxRetries + 1}',
        );
        if (attempt == maxRetries) {
          throw RoutingException(
            'Routing request timed out after ${maxRetries + 1} attempts.',
            kind: RoutingFailureKind.timeout,
          );
        }
        await _delay(_retryDelay(null, attempt));
      } on http.ClientException catch (error) {
        lastNetworkError = error;
        AppLogger.warning(
          'routing network-error provider=$engineId attempt=${attempt + 1}/${maxRetries + 1}',
        );
        if (attempt == maxRetries) {
          throw RoutingException(
            'Routing network request failed after ${maxRetries + 1} attempts: '
            '${error.message}',
            kind: RoutingFailureKind.network,
          );
        }
        await _delay(_retryDelay(null, attempt));
      }
    }

    throw RoutingException(
      'Routing request failed: $lastNetworkError',
      kind: RoutingFailureKind.network,
    );
  }

  String _serviceForProfileName(Uri uri) {
    if (uri.path.contains('routed-bike')) {
      return 'bike';
    }
    if (uri.path.contains('routed-foot')) {
      return 'foot';
    }
    return 'unknown';
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

    try {
      return await primary.calculate(request);
    } on Object catch (primaryError, primaryStack) {
      AppLogger.warning(
        'routing fallback primary=${primary.engineId} failed; '
        'trying=${fallback.engineId} profile=${request.profile.name} '
        'waypoints=${request.points.length}',
      );
      try {
        final fallbackPlan = await fallback.calculate(request);
        if (fallbackPlan.isSnapped) {
          AppLogger.info(
            'routing fallback selected provider=${fallbackPlan.routingSource} '
            'profile=${request.profile.name} waypoints=${request.points.length}',
          );
          return fallbackPlan;
        }
      } on Object catch (fallbackError, fallbackStack) {
        AppLogger.error(
          'routing fallback failed provider=${fallback.engineId}',
          error: fallbackError,
          stackTrace: fallbackStack,
        );
      }
      Error.throwWithStackTrace(primaryError, primaryStack);
    }
  }
}

class QualityRoutingEngine implements RoutingEngine {
  const QualityRoutingEngine({
    required this.primary,
    required this.secondary,
    required this.fallback,
    this.detourProbeRatio = 1.12,
    this.minImprovementMeters = 20,
  });

  final RoutingEngine primary;
  final RoutingEngine secondary;
  final RoutingEngine fallback;
  final double detourProbeRatio;
  final double minImprovementMeters;

  @override
  String get engineId =>
      'quality(${primary.engineId}+${secondary.engineId}+${fallback.engineId})';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    RoutePlan? primaryPlan;
    Object? primaryError;
    try {
      primaryPlan = await primary.calculate(request);
    } on Object catch (error) {
      primaryError = error;
    }
    final shouldProbeSecondary =
        request.snapToNetwork &&
        request.points.length == 2 &&
        (primaryPlan == null || _isWorthProbing(request, primaryPlan));
    if (!shouldProbeSecondary && primaryPlan != null) return primaryPlan;

    RoutePlan? secondaryPlan;
    Object? secondaryError;
    try {
      secondaryPlan = await secondary.calculate(request);
    } on Object catch (error) {
      secondaryError = error;
    }
    if (primaryPlan != null && secondaryPlan != null) {
      if (secondaryPlan.isSnapped &&
          (!primaryPlan.isSnapped ||
              secondaryPlan.distanceMeters + minImprovementMeters <
                  primaryPlan.distanceMeters)) {
        AppLogger.info(
          'routing quality selected secondary=${secondaryPlan.routingSource} '
          'primaryMeters=${primaryPlan.distanceMeters.round()} '
          'secondaryMeters=${secondaryPlan.distanceMeters.round()}',
        );
        return secondaryPlan;
      }
      return primaryPlan;
    }
    if (primaryPlan != null) return primaryPlan;
    if (secondaryPlan != null) return secondaryPlan;
    try {
      final fallbackPlan = await fallback.calculate(request);
      if (fallbackPlan.isSnapped || !request.snapToNetwork) return fallbackPlan;
    } on Object {
      // Fail closed below.
    }
    final error = _preferredFailure(primaryError, secondaryError);
    if (error is RoutingException) throw error;
    throw RoutingException(
      'All routing providers failed: $error',
      kind: RoutingFailureKind.providerUnavailable,
    );
  }

  bool _isWorthProbing(RouteRequest request, RoutePlan plan) {
    if (!plan.isSnapped || plan.distanceMeters <= 0) return true;
    final direct = haversineMeters(request.points.first, request.points.last);
    if (direct < 100) return false;
    return plan.distanceMeters / direct >= detourProbeRatio;
  }

  Object? _preferredFailure(Object? primaryError, Object? secondaryError) {
    for (final error in [primaryError, secondaryError]) {
      if (error is RoutingException &&
          (error.kind == RoutingFailureKind.network ||
              error.kind == RoutingFailureKind.timeout ||
              error.kind == RoutingFailureKind.rateLimited)) {
        return error;
      }
    }
    return secondaryError ?? primaryError;
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

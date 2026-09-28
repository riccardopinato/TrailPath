import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/map_matching.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/routing/valhalla_map_matching_engine.dart';

void main() {
  test('Valhalla matcher decodes GeoJSON trace_route response', () async {
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['shape_match'], 'walk_or_snap');
      expect(payload['shape_format'], 'geojson');
      expect(payload['costing'], 'pedestrian');
      final traceOptions = payload['trace_options'] as Map<String, dynamic>;
      expect(traceOptions['gps_accuracy'], 10);
      expect(traceOptions['search_radius'], 32);

      return http.Response(
        jsonEncode({
          'trip': {
            'summary': {'length': 1.25, 'time': 900},
            'legs': [
              {
                'shape': {
                  'type': 'LineString',
                  'coordinates': [
                    [11.0, 45.0],
                    [11.005, 45.005],
                    [11.01, 45.01],
                  ],
                },
              },
            ],
          },
        }),
        200,
      );
    });

    final engine = ValhallaMapMatchingEngine(
      client: client,
      endpoint: Uri.parse('https://example.test/trace_route'),
    );

    final result = await engine.match(
      const TraceMatchRequest(
        trace: [
          GeoPoint(latitude: 45.0, longitude: 11.0),
          GeoPoint(latitude: 45.01, longitude: 11.01),
        ],
        profile: RouteProfile.hiking,
        mode: MapMatchMode.trails,
      ),
    );

    expect(result.geometry, hasLength(3));
    expect(result.geometry.first.latitude, 45.0);
    expect(result.geometry.last.longitude, 11.01);
    expect(result.distanceMeters, 1250);
    expect(result.estimatedDuration, const Duration(seconds: 900));
    expect(result.source, 'valhalla.trace_route');
  });

  test('rejects a matched path that leaves the drawn corridor', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'trip': {
            'summary': {'length': 4.0, 'time': 1200},
            'legs': [
              {
                'shape': {
                  'type': 'LineString',
                  'coordinates': [
                    [11.0, 45.0],
                    [11.03, 45.03],
                    [11.01, 45.01],
                  ],
                },
              },
            ],
          },
        }),
        200,
      );
    });

    final engine = ValhallaMapMatchingEngine(
      client: client,
      endpoint: Uri.parse('https://example.test/trace_route'),
    );

    await expectLater(
      engine.match(
        const TraceMatchRequest(
          trace: [
            GeoPoint(latitude: 45.0, longitude: 11.0),
            GeoPoint(latitude: 45.005, longitude: 11.005),
            GeoPoint(latitude: 45.01, longitude: 11.01),
          ],
          profile: RouteProfile.hiking,
          mode: MapMatchMode.trails,
        ),
      ),
      throwsA(isA<MapMatchingException>()),
    );
  });

  test('falls back to routing when trace matching is unavailable', () async {
    const engine = RoutingFallbackMapMatchingEngine(
      primary: _AlwaysFailMapMatchingEngine(),
      routing: _TraceRoutingEngine(),
    );

    final result = await engine.match(
      const TraceMatchRequest(
        trace: [
          GeoPoint(latitude: 45.0, longitude: 11.0),
          GeoPoint(latitude: 45.002, longitude: 11.002),
          GeoPoint(latitude: 45.004, longitude: 11.004),
        ],
        profile: RouteProfile.hiking,
        mode: MapMatchMode.roads,
      ),
    );

    expect(result.geometry, isNotEmpty);
    expect(result.distanceMeters, greaterThan(0));
    expect(result.source, contains('trace-fallback'));
  });

  test('road cycling trace asks for road-biased bicycle matching', () async {
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['costing'], 'bicycle');
      final costing = payload['costing_options'] as Map<String, dynamic>;
      final options = costing['bicycle'] as Map<String, dynamic>;
      expect(options['bicycle_type'], 'road');
      expect(options['use_roads'], 0.95);

      return http.Response(
        jsonEncode({
          'trip': {
            'summary': {'length': 0.5, 'time': 120},
            'legs': [
              {
                'shape': {
                  'type': 'LineString',
                  'coordinates': [
                    [11.0, 45.0],
                    [11.01, 45.01],
                  ],
                },
              },
            ],
          },
        }),
        200,
      );
    });

    final engine = ValhallaMapMatchingEngine(
      client: client,
      endpoint: Uri.parse('https://example.test/trace_route'),
    );

    await engine.match(
      const TraceMatchRequest(
        trace: [
          GeoPoint(latitude: 45.0, longitude: 11.0),
          GeoPoint(latitude: 45.01, longitude: 11.01),
        ],
        profile: RouteProfile.cycling,
        mode: MapMatchMode.roads,
      ),
    );
  });
}

class _AlwaysFailMapMatchingEngine implements MapMatchingEngine {
  const _AlwaysFailMapMatchingEngine();

  @override
  String get engineId => 'failed-map-match';

  @override
  Future<TraceMatchResult> match(TraceMatchRequest request) {
    throw const MapMatchingException('offline');
  }
}

class _TraceRoutingEngine implements RoutingEngine {
  const _TraceRoutingEngine();

  @override
  String get engineId => 'trace-routing';

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    return RoutePlan(
      geometry: List<GeoPoint>.unmodifiable(request.points),
      distanceMeters: calculateRouteDistanceMeters(request.points),
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: const Duration(minutes: 12),
      profile: request.profile,
      isSnapped: true,
      routingSource: engineId,
      snappedWaypoints: List<GeoPoint>.unmodifiable(request.points),
    );
  }
}

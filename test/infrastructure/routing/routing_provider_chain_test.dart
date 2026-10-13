import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';

void main() {
  const request = RouteRequest(
    points: [
      GeoPoint(latitude: 45.0, longitude: 11.0),
      GeoPoint(latitude: 45.01, longitude: 11.01),
    ],
    profile: RouteProfile.hiking,
  );

  test(
    'returns the first snapped provider without probing the next one',
    () async {
      final primary = _RecordingRoutingEngine(
        'primary',
        plan: _snappedPlan('primary'),
      );
      final secondary = _RecordingRoutingEngine(
        'secondary',
        plan: _snappedPlan('secondary'),
      );
      final engine = RoutingProviderChain(
        snappedProviders: [primary, secondary],
        unsnappedFallback: const StraightLineRoutingEngine(),
      );

      final plan = await engine.calculate(request);

      expect(plan.routingSource, 'primary');
      expect(primary.calls, 1);
      expect(secondary.calls, 0);
    },
  );

  test(
    'fails over to the next snapped provider after primary failure',
    () async {
      final primary = _RecordingRoutingEngine(
        'primary',
        error: const RoutingException('primary unavailable'),
      );
      final secondary = _RecordingRoutingEngine(
        'secondary',
        plan: _snappedPlan('secondary'),
      );
      final engine = RoutingProviderChain(
        snappedProviders: [primary, secondary],
        unsnappedFallback: const StraightLineRoutingEngine(),
      );

      final plan = await engine.calculate(request);

      expect(plan.routingSource, 'secondary');
      expect(plan.isSnapped, isTrue);
      expect(primary.calls, 1);
      expect(secondary.calls, 1);
    },
  );

  test(
    'preserves the final provider failure when every provider fails',
    () async {
      final primary = _RecordingRoutingEngine(
        'primary',
        error: const RoutingException('primary unavailable'),
      );
      final secondary = _RecordingRoutingEngine(
        'secondary',
        error: const RoutingException('secondary no route'),
      );
      final engine = RoutingProviderChain(
        snappedProviders: [primary, secondary],
        unsnappedFallback: const StraightLineRoutingEngine(),
      );

      await expectLater(
        engine.calculate(request),
        throwsA(
          isA<RoutingException>().having(
            (error) => error.message,
            'message',
            'secondary no route',
          ),
        ),
      );
      expect(primary.calls, 1);
      expect(secondary.calls, 1);
    },
  );

  test(
    'rejects an unsnapped provider result and tries the next provider',
    () async {
      final primary = _RecordingRoutingEngine(
        'primary',
        plan: _unsnappedPlan('primary'),
      );
      final secondary = _RecordingRoutingEngine(
        'secondary',
        plan: _snappedPlan('secondary'),
      );
      final engine = RoutingProviderChain(
        snappedProviders: [primary, secondary],
        unsnappedFallback: const StraightLineRoutingEngine(),
      );

      final plan = await engine.calculate(request);

      expect(plan.routingSource, 'secondary');
      expect(plan.isSnapped, isTrue);
      expect(primary.calls, 1);
      expect(secondary.calls, 1);
    },
  );

  test(
    'snapToNetwork false stays local and never calls remote providers',
    () async {
      final primary = _RecordingRoutingEngine(
        'primary',
        error: const RoutingException('must not be called'),
      );
      final secondary = _RecordingRoutingEngine(
        'secondary',
        error: const RoutingException('must not be called'),
      );
      final engine = RoutingProviderChain(
        snappedProviders: [primary, secondary],
        unsnappedFallback: const StraightLineRoutingEngine(),
      );

      final plan = await engine.calculate(
        const RouteRequest(
          points: [
            GeoPoint(latitude: 45.0, longitude: 11.0),
            GeoPoint(latitude: 45.01, longitude: 11.01),
          ],
          profile: RouteProfile.hiking,
          snapToNetwork: false,
        ),
      );

      expect(plan.isSnapped, isFalse);
      expect(plan.routingSource, 'straight-line');
      expect(primary.calls, 0);
      expect(secondary.calls, 0);
    },
  );
}

class _RecordingRoutingEngine implements RoutingEngine {
  _RecordingRoutingEngine(this.engineId, {this.plan, this.error});

  @override
  final String engineId;
  final RoutePlan? plan;
  final Object? error;
  int calls = 0;

  @override
  Future<RoutePlan> calculate(RouteRequest request) async {
    calls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return plan!;
  }
}

RoutePlan _snappedPlan(String source) {
  const points = [
    GeoPoint(latitude: 45.0, longitude: 11.0),
    GeoPoint(latitude: 45.005, longitude: 11.005),
    GeoPoint(latitude: 45.01, longitude: 11.01),
  ];
  return RoutePlan(
    geometry: points,
    distanceMeters: 1500,
    ascentMeters: 0,
    descentMeters: 0,
    estimatedDuration: const Duration(minutes: 20),
    profile: RouteProfile.hiking,
    isSnapped: true,
    routingSource: source,
    snappedWaypoints: const [
      GeoPoint(latitude: 45.0, longitude: 11.0),
      GeoPoint(latitude: 45.01, longitude: 11.01),
    ],
  );
}

RoutePlan _unsnappedPlan(String source) {
  const points = [
    GeoPoint(latitude: 45.0, longitude: 11.0),
    GeoPoint(latitude: 45.01, longitude: 11.01),
  ];
  return RoutePlan(
    geometry: points,
    distanceMeters: 1400,
    ascentMeters: 0,
    descentMeters: 0,
    estimatedDuration: const Duration(minutes: 18),
    profile: RouteProfile.hiking,
    isSnapped: false,
    routingSource: source,
  );
}

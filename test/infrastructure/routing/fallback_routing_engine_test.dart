import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';

void main() {
  test('routing failure is not silently converted into a direct line', () async {
    const engine = _FailingRoutingEngine();

    expect(
      () => engine.calculate(
        const RouteRequest(
          points: [
            GeoPoint(latitude: 45.0, longitude: 11.0),
            GeoPoint(latitude: 45.01, longitude: 11.01),
          ],
          profile: RouteProfile.hiking,
        ),
      ),
      throwsA(isA<RoutingException>()),
    );
  });

  test('straight line remains available only as an explicit engine', () async {
    const engine = StraightLineRoutingEngine();
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
  });
}

class _FailingRoutingEngine implements RoutingEngine {
  const _FailingRoutingEngine();
  @override
  String get engineId => 'failing';
  @override
  Future<RoutePlan> calculate(RouteRequest request) {
    throw const RoutingException('offline');
  }
}

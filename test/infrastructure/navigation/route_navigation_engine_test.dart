import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/navigation/route_navigation_engine.dart';

void main() {
  test('navigation emits off-route and back-on-route transitions', () async {
    final location = _FakeLocationEngine();
    final engine = RouteNavigationEngine(
      locationEngine: location,
      offRouteThresholdMeters: 40,
      backOnRouteThresholdMeters: 20,
    );
    addTearDown(engine.dispose);

    const route = RoutePlan(
      geometry: [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.0, longitude: 11.01),
      ],
      distanceMeters: 786,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: Duration(minutes: 10),
      profile: RouteProfile.hiking,
    );

    final events = <NavigationEvent>[];
    final sub = engine.events.listen(events.add);
    addTearDown(sub.cancel);

    await engine.start(route);

    expect(location.lastKeepAliveInBackground, isTrue);

    location.add(
      const PositionSample(
        point: GeoPoint(latitude: 45.001, longitude: 11.005),
        accuracyMeters: 5,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(events.any((e) => e.type == NavigationEventType.offRoute), isTrue);

    location.add(
      const PositionSample(
        point: GeoPoint(latitude: 45.00005, longitude: 11.005),
        accuracyMeters: 5,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(events.any((e) => e.type == NavigationEventType.backOnRoute), isTrue);
  });

  test('navigation emits arrival near route endpoint', () async {
    final location = _FakeLocationEngine();
    final engine = RouteNavigationEngine(locationEngine: location);
    addTearDown(engine.dispose);

    const route = RoutePlan(
      geometry: [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.0, longitude: 11.01),
      ],
      distanceMeters: 786,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: Duration(minutes: 10),
      profile: RouteProfile.hiking,
    );

    final events = <NavigationEvent>[];
    final sub = engine.events.listen(events.add);
    addTearDown(sub.cancel);

    await engine.start(route);

    location.add(
      const PositionSample(
        point: GeoPoint(latitude: 45.0, longitude: 11.00995),
        accuracyMeters: 5,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(events.any((e) => e.type == NavigationEventType.arrived), isTrue);
  });
}

class _FakeLocationEngine implements LocationEngine {
  final _controller = StreamController<PositionSample>.broadcast();

  bool lastKeepAliveInBackground = false;

  void add(PositionSample sample) => _controller.add(sample);

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<PositionSample?> current() async => null;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Stream<PositionSample> watch({
    BatteryMode mode = BatteryMode.balanced,
    bool keepAliveInBackground = false,
  }) {
    lastKeepAliveInBackground = keepAliveInBackground;
    return _controller.stream;
  }
}

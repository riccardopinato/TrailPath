import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/features/planner/application/route_planner_controller.dart';

void main() {
  test('route planner calculates distance and supports undo/redo', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);

    controller.addPoint(
      const GeoPoint(latitude: 45.0, longitude: 11.0),
    );
    controller.addPoint(
      const GeoPoint(latitude: 45.0, longitude: 11.01),
    );

    var state = container.read(routePlannerProvider);
    expect(state.points, hasLength(2));
    expect(state.distanceMeters, greaterThan(700));
    expect(state.distanceMeters, lessThan(900));
    expect(state.canUndo, isTrue);
    expect(state.canRedo, isFalse);
    expect(state.estimatedDuration, isNot(Duration.zero));

    controller.undo();
    state = container.read(routePlannerProvider);
    expect(state.points, hasLength(1));
    expect(state.canRedo, isTrue);

    controller.redo();
    state = container.read(routePlannerProvider);
    expect(state.points, hasLength(2));
  });

  test('changing route profile recalculates estimated duration', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(routePlannerProvider.notifier);
    controller
      ..addPoint(const GeoPoint(latitude: 45.0, longitude: 11.0))
      ..addPoint(const GeoPoint(latitude: 45.0, longitude: 11.05));

    final hikingDuration =
        container.read(routePlannerProvider).estimatedDuration;

    controller.setProfile(RouteProfile.cycling);
    final cyclingDuration =
        container.read(routePlannerProvider).estimatedDuration;

    expect(cyclingDuration, lessThan(hikingDuration));
  });

  test('distance helper returns zero for fewer than two points', () {
    expect(calculateDistanceMeters(const []), 0);
    expect(
      calculateDistanceMeters(
        const [GeoPoint(latitude: 45.0, longitude: 11.0)],
      ),
      0,
    );
  });
}

import 'dart:async';

import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/navigation_math.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class RouteNavigationEngine implements NavigationEngine {
  RouteNavigationEngine({
    required this.locationEngine,
    this.offRouteThresholdMeters = 45,
    this.backOnRouteThresholdMeters = 25,
    this.arrivalThresholdMeters = 25,
  });

  final LocationEngine locationEngine;
  final double offRouteThresholdMeters;
  final double backOnRouteThresholdMeters;
  final double arrivalThresholdMeters;

  final StreamController<NavigationEvent> _controller =
      StreamController<NavigationEvent>.broadcast();

  StreamSubscription<PositionSample>? _subscription;
  RoutePlan? _route;
  bool _isOffRoute = false;
  bool _arrived = false;

  @override
  Stream<NavigationEvent> get events => _controller.stream;

  @override
  Future<void> start(RoutePlan route) async {
    if (route.geometry.length < 2) {
      throw ArgumentError('Navigation requires a route with at least two points.');
    }

    await stop();
    _route = route;
    _isOffRoute = false;
    _arrived = false;

    final enabled = await locationEngine.isServiceEnabled();
    if (!enabled) {
      throw StateError('Location services are disabled.');
    }

    var permission = await locationEngine.hasPermission();
    if (!permission) {
      permission = await locationEngine.requestPermission();
    }
    if (!permission) {
      throw StateError('Location permission is not granted.');
    }

    _controller.add(
      NavigationEvent(
        type: NavigationEventType.started,
        routeDistanceMeters: _routeDistance(route),
        remainingMeters: _routeDistance(route),
      ),
    );

    _subscription = locationEngine.watch().listen(
      _onPosition,
      onError: (Object error, StackTrace stackTrace) {
        if (!_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    );
  }

  void _onPosition(PositionSample sample) {
    final route = _route;
    if (route == null || sample.accuracyMeters > 60) {
      return;
    }

    final projection = projectPointOnRoute(sample.point, route.geometry);
    final endpointDistance =
        haversineMeters(sample.point, route.geometry.last);

    var type = NavigationEventType.instruction;

    if (!_arrived &&
        endpointDistance <= arrivalThresholdMeters &&
        projection.remainingMeters <= 60) {
      _arrived = true;
      _isOffRoute = false;
      type = NavigationEventType.arrived;
    } else if (!_arrived) {
      if (!_isOffRoute &&
          projection.distanceToRouteMeters >= offRouteThresholdMeters) {
        _isOffRoute = true;
        type = NavigationEventType.offRoute;
      } else if (_isOffRoute &&
          projection.distanceToRouteMeters <= backOnRouteThresholdMeters) {
        _isOffRoute = false;
        type = NavigationEventType.backOnRoute;
      }
    }

    _controller.add(
      NavigationEvent(
        type: type,
        currentPoint: sample.point,
        nearestRoutePoint: projection.nearestPoint,
        progressMeters: projection.progressMeters,
        remainingMeters: projection.remainingMeters,
        distanceToRouteMeters: projection.distanceToRouteMeters,
        routeDistanceMeters: projection.routeDistanceMeters,
        isOffRoute: _isOffRoute,
      ),
    );
  }

  double _routeDistance(RoutePlan route) {
    if (route.distanceMeters > 0) {
      return route.distanceMeters;
    }
    var total = 0.0;
    for (var i = 1; i < route.geometry.length; i++) {
      total += haversineMeters(route.geometry[i - 1], route.geometry[i]);
    }
    return total;
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    if (_route != null && !_controller.isClosed) {
      _controller.add(
        const NavigationEvent(type: NavigationEventType.stopped),
      );
    }
    _route = null;
    _isOffRoute = false;
    _arrived = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

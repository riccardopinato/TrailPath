import 'dart:async';

import 'package:trail_path/core/domain/battery_policy.dart';
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
  BatteryMode _batteryMode = BatteryMode.balanced;
  double _maxAcceptedAccuracyMeters = 60;
  bool _disposed = false;
  int _session = 0;
  Future<void> _batteryReconfigureChain = Future<void>.value();

  @override
  Stream<NavigationEvent> get events => _controller.stream;

  @override
  Future<void> start(
    RoutePlan route, {
    BatteryMode mode = BatteryMode.balanced,
  }) async {
    if (_disposed) {
      throw StateError('Navigation engine has been disposed.');
    }
    if (route.geometry.length < 2) {
      throw ArgumentError('Navigation requires a route with at least two points.');
    }

    await stop();
    if (_disposed) {
      return;
    }
    final session = ++_session;
    _route = route;
    _isOffRoute = false;
    _arrived = false;
    _batteryMode = mode;
    _maxAcceptedAccuracyMeters =
        batteryModePolicy(mode).maxAcceptedAccuracyMeters;

    final enabled = await locationEngine.isServiceEnabled();
    if (!_isCurrent(session)) {
      return;
    }
    if (!enabled) {
      throw StateError('Location services are disabled.');
    }

    var permission = await locationEngine.hasPermission();
    if (!_isCurrent(session)) {
      return;
    }
    if (!permission) {
      permission = await locationEngine.requestPermission();
    }
    if (!_isCurrent(session)) {
      return;
    }
    if (!permission) {
      throw StateError('Location permission is not granted.');
    }

    if (!_controller.isClosed) {
      _controller.add(
        NavigationEvent(
        type: NavigationEventType.started,
        routeDistanceMeters: _routeDistance(route),
          remainingMeters: _routeDistance(route),
        ),
      );
    }

    if (!_isCurrent(session)) {
      return;
    }
    _subscription = locationEngine
        .watch(
          mode: mode,
          keepAliveInBackground: true,
        )
        .listen(
      (sample) {
        if (_isCurrent(session)) {
          _onPosition(sample);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_isCurrent(session) && !_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    );
  }

  @override
  Future<void> setBatteryMode(BatteryMode mode) {
    if (_disposed || _batteryMode == mode) {
      return Future<void>.value();
    }

    _batteryMode = mode;
    _maxAcceptedAccuracyMeters =
        batteryModePolicy(mode).maxAcceptedAccuracyMeters;

    final previous = _batteryReconfigureChain;
    final next = () async {
      try {
        await previous;
      } on Object {
        // A failed older reconfiguration must not block a newer mode.
      }
      await _restartLocationStreamForBatteryMode();
    }();
    _batteryReconfigureChain = next;
    return next;
  }

  Future<void> _restartLocationStreamForBatteryMode() async {
    if (_disposed || _route == null || _subscription == null) {
      return;
    }

    final session = _session;
    final previous = _subscription;
    _subscription = null;
    await previous?.cancel();

    if (!_isCurrent(session) || _route == null) {
      return;
    }

    final mode = _batteryMode;
    _subscription = locationEngine
        .watch(
          mode: mode,
          keepAliveInBackground: true,
        )
        .listen(
      (sample) {
        if (_isCurrent(session)) {
          _onPosition(sample);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_isCurrent(session) && !_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    );
  }

  void _onPosition(PositionSample sample) {
    if (_disposed || _controller.isClosed) {
      return;
    }
    final route = _route;
    if (route == null ||
        sample.accuracyMeters > _maxAcceptedAccuracyMeters) {
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

    if (_controller.isClosed) {
      return;
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
    _session++;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();

    if (!_disposed && _route != null && !_controller.isClosed) {
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
    if (_disposed) {
      return;
    }
    _disposed = true;
    _session++;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    _route = null;
    _isOffRoute = false;
    _arrived = false;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  bool _isCurrent(int session) => !_disposed && session == _session;
}

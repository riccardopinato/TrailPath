import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_providers.dart';

final routePlannerProvider =
    NotifierProvider<RoutePlannerController, RoutePlannerState>(
  RoutePlannerController.new,
);

class RoutePlannerState {
  const RoutePlannerState({
    this.points = const [],
    this.geometry = const [],
    this.profile = RouteProfile.hiking,
    this.distanceMeters = 0,
    this.estimatedDuration = Duration.zero,
    this.canUndo = false,
    this.canRedo = false,
    this.isRouting = false,
    this.isSnapped = false,
    this.routingSource = 'local',
  });

  final List<GeoPoint> points;
  final List<GeoPoint> geometry;
  final RouteProfile profile;
  final double distanceMeters;
  final Duration estimatedDuration;
  final bool canUndo;
  final bool canRedo;
  final bool isRouting;
  final bool isSnapped;
  final String routingSource;

  bool get canSave =>
      points.length >= 2 && geometry.length >= 2 && distanceMeters > 0;

  RoutePlannerState copyWith({
    List<GeoPoint>? points,
    List<GeoPoint>? geometry,
    RouteProfile? profile,
    double? distanceMeters,
    Duration? estimatedDuration,
    bool? canUndo,
    bool? canRedo,
    bool? isRouting,
    bool? isSnapped,
    String? routingSource,
  }) {
    return RoutePlannerState(
      points: points ?? this.points,
      geometry: geometry ?? this.geometry,
      profile: profile ?? this.profile,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isRouting: isRouting ?? this.isRouting,
      isSnapped: isSnapped ?? this.isSnapped,
      routingSource: routingSource ?? this.routingSource,
    );
  }
}

class RoutePlannerController extends Notifier<RoutePlannerState> {
  final List<List<GeoPoint>> _undoStack = [];
  final List<List<GeoPoint>> _redoStack = [];
  int _routingGeneration = 0;

  @override
  RoutePlannerState build() => const RoutePlannerState();

  void addPoint(GeoPoint point) {
    _pushUndo();
    _redoStack.clear();
    _applyPoints([...state.points, point]);
  }

  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    _redoStack.add(List<GeoPoint>.unmodifiable(state.points));
    final previous = _undoStack.removeLast();
    _applyPoints(previous);
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    _undoStack.add(List<GeoPoint>.unmodifiable(state.points));
    final next = _redoStack.removeLast();
    _applyPoints(next);
  }

  void clear() {
    if (state.points.isEmpty) {
      return;
    }
    _pushUndo();
    _redoStack.clear();
    _applyPoints(const []);
  }

  void setProfile(RouteProfile profile) {
    if (profile == state.profile) {
      return;
    }

    state = state.copyWith(
      profile: profile,
      isSnapped: false,
      routingSource: 'local',
      estimatedDuration: _estimateDuration(state.distanceMeters, profile),
    );
    unawaited(_refreshRoute());
  }

  void resetAfterSave() {
    _routingGeneration++;
    _undoStack.clear();
    _redoStack.clear();
    state = RoutePlannerState(profile: state.profile);
  }

  void _pushUndo() {
    _undoStack.add(List<GeoPoint>.unmodifiable(state.points));
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void _applyPoints(List<GeoPoint> points) {
    final immutable = List<GeoPoint>.unmodifiable(points);
    final distance = calculateRouteDistanceMeters(immutable);

    state = state.copyWith(
      points: immutable,
      geometry: immutable,
      distanceMeters: distance,
      estimatedDuration: _estimateDuration(distance, state.profile),
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
      isRouting: immutable.length >= 2,
      isSnapped: false,
      routingSource: 'local',
    );

    unawaited(_refreshRoute());
  }

  Future<void> _refreshRoute() async {
    final generation = ++_routingGeneration;
    final waypoints = List<GeoPoint>.unmodifiable(state.points);
    final profile = state.profile;

    if (waypoints.length < 2) {
      state = state.copyWith(
        geometry: waypoints,
        isRouting: false,
        isSnapped: false,
        routingSource: 'local',
      );
      return;
    }

    state = state.copyWith(isRouting: true);

    try {
      final plan = await ref.read(routingEngineProvider).calculate(
            RouteRequest(
              points: waypoints,
              profile: profile,
              snapToNetwork: true,
            ),
          );

      if (generation != _routingGeneration) {
        return;
      }

      state = state.copyWith(
        geometry: plan.geometry,
        distanceMeters: plan.distanceMeters,
        estimatedDuration: plan.estimatedDuration,
        isRouting: false,
        isSnapped: plan.isSnapped,
        routingSource: plan.routingSource,
      );
    } on Object {
      if (generation != _routingGeneration) {
        return;
      }

      final distance = calculateRouteDistanceMeters(waypoints);
      state = state.copyWith(
        geometry: waypoints,
        distanceMeters: distance,
        estimatedDuration: _estimateDuration(distance, profile),
        isRouting: false,
        isSnapped: false,
        routingSource: 'local',
      );
    }
  }
}

double calculateDistanceMeters(List<GeoPoint> points) =>
    calculateRouteDistanceMeters(points);

Duration _estimateDuration(double distanceMeters, RouteProfile profile) {
  if (distanceMeters <= 0) {
    return Duration.zero;
  }

  final speedKmh = switch (profile) {
    RouteProfile.hiking => 4.5,
    RouteProfile.trailRunning => 9.0,
    RouteProfile.walking => 4.8,
    RouteProfile.mountainBike => 15.0,
    RouteProfile.cycling => 18.0,
    RouteProfile.dogWalk => 4.0,
  };

  final seconds = (distanceMeters / 1000 / speedKmh * 3600).round();
  return Duration(seconds: seconds);
}

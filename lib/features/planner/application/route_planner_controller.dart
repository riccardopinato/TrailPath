import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/models.dart';

final routePlannerProvider =
    NotifierProvider<RoutePlannerController, RoutePlannerState>(
  RoutePlannerController.new,
);

class RoutePlannerState {
  const RoutePlannerState({
    this.points = const [],
    this.profile = RouteProfile.hiking,
    this.distanceMeters = 0,
    this.estimatedDuration = Duration.zero,
    this.canUndo = false,
    this.canRedo = false,
  });

  final List<GeoPoint> points;
  final RouteProfile profile;
  final double distanceMeters;
  final Duration estimatedDuration;
  final bool canUndo;
  final bool canRedo;

  bool get canSave => points.length >= 2 && distanceMeters > 0;

  RoutePlannerState copyWith({
    List<GeoPoint>? points,
    RouteProfile? profile,
    double? distanceMeters,
    Duration? estimatedDuration,
    bool? canUndo,
    bool? canRedo,
  }) {
    return RoutePlannerState(
      points: points ?? this.points,
      profile: profile ?? this.profile,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

class RoutePlannerController extends Notifier<RoutePlannerState> {
  final List<List<GeoPoint>> _undoStack = [];
  final List<List<GeoPoint>> _redoStack = [];

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
      estimatedDuration: _estimateDuration(state.distanceMeters, profile),
    );
  }

  void resetAfterSave() {
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
    final distance = calculateDistanceMeters(immutable);
    state = state.copyWith(
      points: immutable,
      distanceMeters: distance,
      estimatedDuration: _estimateDuration(distance, state.profile),
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
    );
  }
}

double calculateDistanceMeters(List<GeoPoint> points) {
  if (points.length < 2) {
    return 0;
  }

  var total = 0.0;
  for (var index = 1; index < points.length; index++) {
    total += _haversineMeters(points[index - 1], points[index]);
  }
  return total;
}

double _haversineMeters(GeoPoint a, GeoPoint b) {
  const earthRadiusMeters = 6371008.8;
  final lat1 = _degreesToRadians(a.latitude);
  final lat2 = _degreesToRadians(b.latitude);
  final deltaLat = _degreesToRadians(b.latitude - a.latitude);
  final deltaLon = _degreesToRadians(b.longitude - a.longitude);

  final sinLat = math.sin(deltaLat / 2);
  final sinLon = math.sin(deltaLon / 2);
  final h = sinLat * sinLat +
      math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
  final arc = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusMeters * arc;
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

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

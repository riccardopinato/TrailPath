import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/elevation_math.dart';
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
    this.elevationProfile = const ElevationProfile.unavailable(),
    this.isElevationLoading = false,
    this.routingError,
    this.importedName,
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
  final ElevationProfile elevationProfile;
  final bool isElevationLoading;
  final String? routingError;
  final String? importedName;

  bool get canSave =>
      routingError == null &&
      points.length >= 2 &&
      geometry.length >= 2 &&
      distanceMeters > 0;

  bool get hasElevation => elevationProfile.isAvailable;

  double get ascentMeters => elevationProfile.ascentMeters;

  double get descentMeters => elevationProfile.descentMeters;

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
    ElevationProfile? elevationProfile,
    bool? isElevationLoading,
    String? routingError,
    bool clearRoutingError = false,
    String? importedName,
    bool clearImportedName = false,
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
      elevationProfile: elevationProfile ?? this.elevationProfile,
      isElevationLoading: isElevationLoading ?? this.isElevationLoading,
      routingError:
          clearRoutingError ? null : routingError ?? this.routingError,
      importedName:
          clearImportedName ? null : importedName ?? this.importedName,
    );
  }
}

class RoutePlannerController extends Notifier<RoutePlannerState> {
  final List<List<GeoPoint>> _undoStack = [];
  final List<List<GeoPoint>> _redoStack = [];
  int _routingGeneration = 0;
  int _elevationGeneration = 0;

  @override
  RoutePlannerState build() {
    ref.onDispose(() {
      _routingGeneration++;
      _elevationGeneration++;
    });
    return const RoutePlannerState();
  }

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

    _elevationGeneration++;
    state = state.copyWith(
      profile: profile,
      isSnapped: false,
      routingSource: 'local',
      estimatedDuration: _estimateDuration(state.distanceMeters, profile),
      elevationProfile: const ElevationProfile.unavailable(),
      isElevationLoading: false,
      clearRoutingError: true,
      clearImportedName: true,
    );
    unawaited(_refreshRoute());
  }

  void resetAfterSave() {
    _routingGeneration++;
    _elevationGeneration++;
    _undoStack.clear();
    _redoStack.clear();
    state = RoutePlannerState(profile: state.profile);
  }

  void importGpx(GpxDocument document) {
    _routingGeneration++;
    _elevationGeneration++;
    _undoStack.clear();
    _redoStack.clear();

    final geometry = List<GeoPoint>.unmodifiable(document.points);
    final distance = calculateRouteDistanceMeters(geometry);
    final hasCompleteElevation =
        geometry.every((point) => point.elevationMeters != null);
    final elevationProfile = hasCompleteElevation
        ? buildElevationProfile(
            geometry,
            source: 'gpx',
          )
        : const ElevationProfile.unavailable();

    state = RoutePlannerState(
      points: [geometry.first, geometry.last],
      geometry: geometry,
      profile: state.profile,
      distanceMeters: distance,
      estimatedDuration: _estimateDuration(distance, state.profile),
      canUndo: false,
      canRedo: false,
      isRouting: false,
      isSnapped: false,
      routingSource: 'gpx',
      elevationProfile: elevationProfile,
      isElevationLoading: !hasCompleteElevation,
      importedName: document.name,
    );

    if (!hasCompleteElevation) {
      unawaited(_refreshImportedElevation(geometry));
    }
  }

  GpxDocument exportGpx(String name) {
    final sourcePoints = state.elevationProfile.isAvailable
        ? state.elevationProfile.points
        : state.geometry;
    if (sourcePoints.length < 2) {
      throw StateError('No route available for GPX export.');
    }

    return GpxDocument(
      name: name,
      points: List<GeoPoint>.unmodifiable(sourcePoints),
    );
  }

  Future<void> _refreshImportedElevation(List<GeoPoint> geometry) async {
    final generation = ++_elevationGeneration;
    try {
      final profile = await ref.read(elevationEngineProvider).resolve(geometry);
      if (!ref.mounted || generation != _elevationGeneration) {
        return;
      }
      state = state.copyWith(
        elevationProfile: profile,
        isElevationLoading: false,
      );
    } on Object {
      if (!ref.mounted || generation != _elevationGeneration) {
        return;
      }
      state = state.copyWith(
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: false,
      );
    }
  }

  void _pushUndo() {
    _undoStack.add(List<GeoPoint>.unmodifiable(state.points));
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void _applyPoints(List<GeoPoint> points) {
    _elevationGeneration++;
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
      elevationProfile: const ElevationProfile.unavailable(),
      isElevationLoading: false,
      clearRoutingError: true,
      clearImportedName: true,
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
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: false,
        clearRoutingError: true,
      );
      return;
    }

    state = state.copyWith(
      isRouting: true,
      clearRoutingError: true,
    );

    try {
      final plan = await ref.read(routingEngineProvider).calculate(
            RouteRequest(
              points: waypoints,
              profile: profile,
              snapToNetwork: true,
            ),
          );

      if (!ref.mounted || generation != _routingGeneration) {
        return;
      }

      state = state.copyWith(
        geometry: plan.geometry,
        distanceMeters: plan.distanceMeters,
        estimatedDuration: plan.estimatedDuration,
        isRouting: false,
        isSnapped: plan.isSnapped,
        routingSource: plan.routingSource,
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: true,
        clearRoutingError: true,
      );

      unawaited(_refreshElevation(generation, plan.geometry));
    } on Object catch (error) {
      if (!ref.mounted || generation != _routingGeneration) {
        return;
      }

      final distance = calculateRouteDistanceMeters(waypoints);
      state = state.copyWith(
        geometry: waypoints,
        distanceMeters: distance,
        estimatedDuration: _estimateDuration(distance, profile),
        isRouting: false,
        isSnapped: false,
        routingSource: 'routing-error',
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: false,
        routingError: error.toString(),
      );
    }
  }

  Future<void> _refreshElevation(
    int routingGeneration,
    List<GeoPoint> geometry,
  ) async {
    final elevationGeneration = ++_elevationGeneration;

    try {
      final profile = await ref.read(elevationEngineProvider).resolve(geometry);

      if (!ref.mounted ||
          routingGeneration != _routingGeneration ||
          elevationGeneration != _elevationGeneration) {
        return;
      }

      state = state.copyWith(
        elevationProfile: profile,
        isElevationLoading: false,
      );
    } on Object {
      if (!ref.mounted ||
          routingGeneration != _routingGeneration ||
          elevationGeneration != _elevationGeneration) {
        return;
      }

      state = state.copyWith(
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: false,
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

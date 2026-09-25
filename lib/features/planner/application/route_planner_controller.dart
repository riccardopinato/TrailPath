import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/elevation_math.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/planner_service_providers.dart';

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
    this.importedName,
    this.routingError,
    this.editHandles = const [],
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
  final String? importedName;
  final String? routingError;
  final List<GeoPoint> editHandles;

  bool get hasRoutingError => routingError != null;

  bool get canSave =>
      !isRouting &&
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
    String? importedName,
    bool clearImportedName = false,
    String? routingError,
    bool clearRoutingError = false,
    List<GeoPoint>? editHandles,
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
      importedName: clearImportedName
          ? null
          : importedName ?? this.importedName,
      routingError: clearRoutingError
          ? null
          : routingError ?? this.routingError,
      editHandles: editHandles ?? this.editHandles,
    );
  }
}

class RoutePlannerController extends Notifier<RoutePlannerState> {
  final List<List<GeoPoint>> _undoStack = [];
  final List<List<GeoPoint>> _redoStack = [];
  List<List<GeoPoint>> _legGeometries = const [];
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
    final previousPoints = List<GeoPoint>.unmodifiable(state.points);
    final previousLegs = _copyLegCache();
    final canPatch = _hasLegCacheFor(previousPoints);

    _pushUndo();
    _redoStack.clear();

    final next = List<GeoPoint>.unmodifiable([...previousPoints, point]);
    if (canPatch) {
      _startRouteEdit(next);
      unawaited(
        _rerouteSpan(
          nextPoints: next,
          previousLegs: previousLegs,
          startWaypoint: previousPoints.length - 1,
          endWaypoint: previousPoints.length,
          oldLegStart: previousLegs.length,
          oldLegRemoveCount: 0,
        ),
      );
      return;
    }

    _applyPoints(next);
  }

  bool addTrace(List<GeoPoint> rawTrace) {
    final trace = simplifyTraceForRouting(rawTrace);
    if (trace.length < 2) {
      return false;
    }

    final previousPoints = List<GeoPoint>.unmodifiable(state.points);
    final previousLegs = _copyLegCache();
    final canPatch = _hasLegCacheFor(previousPoints);

    var append = List<GeoPoint>.of(trace);
    if (previousPoints.isNotEmpty &&
        haversineMeters(previousPoints.last, append.first) <= 30) {
      append = append.skip(1).toList(growable: false);
    }
    if (append.isEmpty) {
      return false;
    }

    final next = List<GeoPoint>.unmodifiable([...previousPoints, ...append]);

    _pushUndo();
    _redoStack.clear();

    if (canPatch && previousPoints.length >= 2) {
      _startRouteEdit(next);
      unawaited(
        _rerouteSpan(
          nextPoints: next,
          previousLegs: previousLegs,
          startWaypoint: previousPoints.length - 1,
          endWaypoint: next.length - 1,
          oldLegStart: previousLegs.length,
          oldLegRemoveCount: 0,
        ),
      );
      return true;
    }

    _applyPoints(next);
    return true;
  }

  void movePoint(int index, GeoPoint point) {
    if (index < 0 || index >= state.points.length) {
      return;
    }

    final previousPoints = List<GeoPoint>.unmodifiable(state.points);
    final previousLegs = _copyLegCache();
    final canPatch = _hasLegCacheFor(previousPoints);
    final next = [...previousPoints];
    next[index] = point;

    _pushUndo();
    _redoStack.clear();

    if (canPatch && next.length >= 2) {
      final startWaypoint = index == 0 ? 0 : index - 1;
      final endWaypoint = index == next.length - 1
          ? next.length - 1
          : index + 1;
      _startRouteEdit(next);
      unawaited(
        _rerouteSpan(
          nextPoints: next,
          previousLegs: previousLegs,
          startWaypoint: startWaypoint,
          endWaypoint: endWaypoint,
          oldLegStart: startWaypoint,
          oldLegRemoveCount: endWaypoint - startWaypoint,
        ),
      );
      return;
    }

    _applyPoints(next);
  }

  void insertPointAt(int index, GeoPoint point) {
    if (index < 0 || index > state.points.length) {
      return;
    }

    final previousPoints = List<GeoPoint>.unmodifiable(state.points);
    final previousLegs = _copyLegCache();
    final canPatch = _hasLegCacheFor(previousPoints);
    final next = [...previousPoints]..insert(index, point);

    _pushUndo();
    _redoStack.clear();

    if (canPatch &&
        previousPoints.length >= 2 &&
        index > 0 &&
        index < previousPoints.length) {
      _startRouteEdit(next);
      unawaited(
        _rerouteSpan(
          nextPoints: next,
          previousLegs: previousLegs,
          startWaypoint: index - 1,
          endWaypoint: index + 1,
          oldLegStart: index - 1,
          oldLegRemoveCount: 1,
        ),
      );
      return;
    }

    _applyPoints(next);
  }

  void insertPointNearRoute(GeoPoint point) {
    if (state.points.length < 2) {
      addPoint(point);
      return;
    }

    final legIndex = _nearestLegIndex(point);
    if (legIndex < 0) {
      addPoint(point);
      return;
    }
    insertPointAt(legIndex + 1, point);
  }

  void removePoint(int index) {
    if (index < 0 || index >= state.points.length) {
      return;
    }

    final previousPoints = List<GeoPoint>.unmodifiable(state.points);
    final previousLegs = _copyLegCache();
    final canPatch = _hasLegCacheFor(previousPoints);
    final next = [...previousPoints]..removeAt(index);

    _pushUndo();
    _redoStack.clear();

    if (next.length < 2 || !canPatch) {
      _applyPoints(next);
      return;
    }

    if (index == 0 || index == previousPoints.length - 1) {
      final remainingLegs = index == 0
          ? previousLegs.skip(1).toList(growable: false)
          : previousLegs.take(previousLegs.length - 1).toList(growable: false);
      _applyCachedRoute(next, remainingLegs);
      return;
    }

    _startRouteEdit(next);
    unawaited(
      _rerouteSpan(
        nextPoints: next,
        previousLegs: previousLegs,
        startWaypoint: index - 1,
        endWaypoint: index,
        oldLegStart: index - 1,
        oldLegRemoveCount: 2,
      ),
    );
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
      editHandles: const [],
      clearImportedName: true,
      clearRoutingError: true,
    );
    unawaited(_refreshRoute());
  }

  void resetAfterSave() {
    _routingGeneration++;
    _elevationGeneration++;
    _undoStack.clear();
    _redoStack.clear();
    _legGeometries = const [];
    state = RoutePlannerState(profile: state.profile);
  }

  void importGpx(GpxDocument document) {
    _routingGeneration++;
    _elevationGeneration++;
    _undoStack.clear();
    _redoStack.clear();
    _legGeometries = const [];

    final geometry = List<GeoPoint>.unmodifiable(document.points);
    final distance = calculateRouteDistanceMeters(geometry);
    final hasCompleteElevation = geometry.every(
      (point) => point.elevationMeters != null,
    );
    final elevationProfile = hasCompleteElevation
        ? buildElevationProfile(geometry, source: 'gpx')
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
    _legGeometries = const [];
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
      editHandles: const [],
      clearImportedName: true,
      clearRoutingError: true,
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
        editHandles: const [],
        clearRoutingError: true,
      );
      return;
    }

    state = state.copyWith(isRouting: true);

    try {
      final plan = await ref
          .read(routingEngineProvider)
          .calculate(
            RouteRequest(
              points: waypoints,
              profile: profile,
              snapToNetwork: true,
            ),
          );

      if (!ref.mounted || generation != _routingGeneration) {
        return;
      }

      final snappedWaypoints = plan.snappedWaypoints.length == waypoints.length
          ? List<GeoPoint>.unmodifiable(plan.snappedWaypoints)
          : waypoints;
      _legGeometries = plan.isSnapped
          ? _splitGeometryIntoLegs(plan.geometry, snappedWaypoints)
          : const [];
      if (_legGeometries.length != snappedWaypoints.length - 1) {
        _legGeometries = const [];
      }

      state = state.copyWith(
        points: snappedWaypoints,
        geometry: plan.geometry,
        distanceMeters: plan.distanceMeters,
        estimatedDuration: plan.estimatedDuration,
        isRouting: false,
        isSnapped: plan.isSnapped,
        routingSource: plan.routingSource,
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: true,
        editHandles: _buildEditHandles(_legGeometries),
        clearRoutingError: true,
      );

      unawaited(_refreshElevation(generation, plan.geometry));
    } on Object catch (error) {
      if (!ref.mounted || generation != _routingGeneration) {
        return;
      }

      _legGeometries = const [];
      state = state.copyWith(
        geometry: const [],
        distanceMeters: 0,
        estimatedDuration: Duration.zero,
        isRouting: false,
        isSnapped: false,
        routingSource: 'unavailable',
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: false,
        editHandles: const [],
        routingError: error.toString(),
      );
    }
  }

  List<List<GeoPoint>> _copyLegCache() {
    return [for (final leg in _legGeometries) List<GeoPoint>.unmodifiable(leg)];
  }

  bool _hasLegCacheFor(List<GeoPoint> points) {
    return state.isSnapped &&
        !state.isRouting &&
        !state.hasRoutingError &&
        points.length >= 2 &&
        _legGeometries.length == points.length - 1 &&
        _legGeometries.every((leg) => leg.length >= 2);
  }

  void _startRouteEdit(List<GeoPoint> points) {
    _elevationGeneration++;
    state = state.copyWith(
      points: List<GeoPoint>.unmodifiable(points),
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
      isRouting: true,
      elevationProfile: const ElevationProfile.unavailable(),
      isElevationLoading: false,
      editHandles: const [],
      clearImportedName: true,
      clearRoutingError: true,
    );
  }

  Future<void> _rerouteSpan({
    required List<GeoPoint> nextPoints,
    required List<List<GeoPoint>> previousLegs,
    required int startWaypoint,
    required int endWaypoint,
    required int oldLegStart,
    required int oldLegRemoveCount,
  }) async {
    final generation = ++_routingGeneration;
    final profile = state.profile;
    final spanPoints = List<GeoPoint>.unmodifiable(
      nextPoints.sublist(startWaypoint, endWaypoint + 1),
    );

    try {
      final plan = await ref
          .read(routingEngineProvider)
          .calculate(
            RouteRequest(
              points: spanPoints,
              profile: profile,
              snapToNetwork: true,
            ),
          );

      if (!ref.mounted || generation != _routingGeneration) {
        return;
      }

      final snappedSpan = plan.snappedWaypoints.length == spanPoints.length
          ? List<GeoPoint>.unmodifiable(plan.snappedWaypoints)
          : spanPoints;
      final replacementLegs = _splitGeometryIntoLegs(
        plan.geometry,
        snappedSpan,
      );

      if (!plan.isSnapped || replacementLegs.length != snappedSpan.length - 1) {
        _legGeometries = const [];
        state = state.copyWith(
          points: List<GeoPoint>.unmodifiable(nextPoints),
          isRouting: true,
          editHandles: const [],
        );
        await _refreshRoute();
        return;
      }

      final snappedPoints = [...nextPoints];
      for (var offset = 0; offset < snappedSpan.length; offset++) {
        snappedPoints[startWaypoint + offset] = snappedSpan[offset];
      }

      final mergedLegs = <List<GeoPoint>>[
        ...previousLegs.take(oldLegStart),
        ...replacementLegs,
        ...previousLegs.skip(oldLegStart + oldLegRemoveCount),
      ];
      _legGeometries = [
        for (final leg in mergedLegs) List<GeoPoint>.unmodifiable(leg),
      ];

      if (_legGeometries.length != snappedPoints.length - 1) {
        _legGeometries = const [];
        state = state.copyWith(
          points: List<GeoPoint>.unmodifiable(snappedPoints),
          isRouting: true,
          editHandles: const [],
        );
        await _refreshRoute();
        return;
      }

      final geometry = _mergeLegs(_legGeometries);
      final distance = calculateRouteDistanceMeters(geometry);
      state = state.copyWith(
        points: List<GeoPoint>.unmodifiable(snappedPoints),
        geometry: geometry,
        distanceMeters: distance,
        estimatedDuration: _estimateDuration(distance, profile),
        isRouting: false,
        isSnapped: true,
        routingSource: plan.routingSource,
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: true,
        editHandles: _buildEditHandles(_legGeometries),
        clearRoutingError: true,
      );

      unawaited(_refreshElevation(generation, geometry));
    } on Object catch (error) {
      if (!ref.mounted || generation != _routingGeneration) {
        return;
      }

      _legGeometries = const [];
      state = state.copyWith(
        geometry: const [],
        distanceMeters: 0,
        estimatedDuration: Duration.zero,
        isRouting: false,
        isSnapped: false,
        routingSource: 'unavailable',
        elevationProfile: const ElevationProfile.unavailable(),
        isElevationLoading: false,
        editHandles: const [],
        routingError: error.toString(),
      );
    }
  }

  void _applyCachedRoute(List<GeoPoint> points, List<List<GeoPoint>> legs) {
    final generation = ++_routingGeneration;
    _elevationGeneration++;
    _legGeometries = [for (final leg in legs) List<GeoPoint>.unmodifiable(leg)];
    final geometry = _mergeLegs(_legGeometries);
    final distance = calculateRouteDistanceMeters(geometry);

    state = state.copyWith(
      points: List<GeoPoint>.unmodifiable(points),
      geometry: geometry,
      distanceMeters: distance,
      estimatedDuration: _estimateDuration(distance, state.profile),
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
      isRouting: false,
      isSnapped: true,
      elevationProfile: const ElevationProfile.unavailable(),
      isElevationLoading: geometry.length >= 2,
      editHandles: _buildEditHandles(_legGeometries),
      clearImportedName: true,
      clearRoutingError: true,
    );

    if (geometry.length >= 2) {
      unawaited(_refreshElevation(generation, geometry));
    }
  }

  int _nearestLegIndex(GeoPoint point) {
    if (_legGeometries.length == state.points.length - 1) {
      var bestLeg = -1;
      var bestDistance = double.infinity;
      for (var legIndex = 0; legIndex < _legGeometries.length; legIndex++) {
        for (final routePoint in _legGeometries[legIndex]) {
          final distance = haversineMeters(point, routePoint);
          if (distance < bestDistance) {
            bestDistance = distance;
            bestLeg = legIndex;
          }
        }
      }
      if (bestLeg >= 0) {
        return bestLeg;
      }
    }

    if (state.points.length < 2) {
      return -1;
    }

    var bestLeg = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < state.points.length - 1; index++) {
      final distance =
          haversineMeters(point, state.points[index]) +
          haversineMeters(point, state.points[index + 1]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestLeg = index;
      }
    }
    return bestLeg;
  }

  List<List<GeoPoint>> _splitGeometryIntoLegs(
    List<GeoPoint> geometry,
    List<GeoPoint> waypoints,
  ) {
    if (waypoints.length < 2 ||
        geometry.length < 2 ||
        geometry.length < waypoints.length) {
      return const [];
    }

    if (waypoints.length == 2) {
      return [List<GeoPoint>.unmodifiable(geometry)];
    }

    final cuts = <int>[0];
    var previousCut = 0;

    for (
      var waypointIndex = 1;
      waypointIndex < waypoints.length - 1;
      waypointIndex++
    ) {
      final minIndex = previousCut + 1;
      final remainingWaypoints = waypoints.length - waypointIndex - 1;
      final maxIndex = geometry.length - remainingWaypoints - 1;
      if (minIndex > maxIndex) {
        return const [];
      }

      var bestIndex = minIndex;
      var bestDistance = double.infinity;
      for (
        var geometryIndex = minIndex;
        geometryIndex <= maxIndex;
        geometryIndex++
      ) {
        final distance = haversineMeters(
          waypoints[waypointIndex],
          geometry[geometryIndex],
        );
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = geometryIndex;
        }
      }

      cuts.add(bestIndex);
      previousCut = bestIndex;
    }

    cuts.add(geometry.length - 1);
    return [
      for (var index = 0; index < cuts.length - 1; index++)
        List<GeoPoint>.unmodifiable(
          geometry.sublist(cuts[index], cuts[index + 1] + 1),
        ),
    ];
  }

  List<GeoPoint> _buildEditHandles(List<List<GeoPoint>> legs) {
    return List<GeoPoint>.unmodifiable([
      for (final leg in legs)
        if (leg.length >= 2) pointAlongPolyline(leg),
    ]);
  }

  List<GeoPoint> _mergeLegs(List<List<GeoPoint>> legs) {
    if (legs.isEmpty) {
      return const [];
    }

    final merged = <GeoPoint>[];
    for (var index = 0; index < legs.length; index++) {
      final leg = legs[index];
      if (leg.isEmpty) {
        continue;
      }
      if (index == 0 || merged.isEmpty) {
        merged.addAll(leg);
      } else {
        merged.addAll(leg.skip(1));
      }
    }
    return List<GeoPoint>.unmodifiable(merged);
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

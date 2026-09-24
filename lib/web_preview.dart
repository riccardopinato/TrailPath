import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrailPathWebPreview());
}

class TrailPathWebPreview extends StatelessWidget {
  const TrailPathWebPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrailPath Web',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
      ),
      home: const _PreviewScreen(),
    );
  }
}

class _PreviewScreen extends StatefulWidget {
  const _PreviewScreen();

  @override
  State<_PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<_PreviewScreen> {
  final List<GeoPoint> _points = <GeoPoint>[];
  final List<List<GeoPoint>> _undoStack = <List<GeoPoint>>[];
  final List<List<GeoPoint>> _redoStack = <List<GeoPoint>>[];
  final _routingService = _WebRoutingService();
  final _searchController = TextEditingController();

  MapLibreMapController? _map;
  bool _styleReady = false;
  List<Circle> _waypointCircles = const [];
  List<Circle> _midpointCircles = const [];
  List<Line> _routeLines = const [];
  Line? _dragPreviewLine;

  RouteProfile _profile = RouteProfile.hiking;
  List<GeoPoint> _geometry = const [];
  List<List<GeoPoint>> _routeLegs = const [];
  double _distanceMeters = 0;
  Duration _duration = Duration.zero;
  bool _routing = false;
  String? _routingError;
  int _routingGeneration = 0;

  bool _routeSelected = false;
  bool _draggingFeature = false;
  int? _selectedWaypointIndex;

  Timer? _searchDebounce;
  List<PlaceSearchResult> _searchResults = const [];
  bool _searchLoading = false;
  String? _searchError;

  @override
  void dispose() {
    _routingGeneration++;
    _searchDebounce?.cancel();
    _searchController.dispose();
    _routingService.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _syncMap() async {
    final map = _map;
    if (map == null || !_styleReady || map.isDisposed) return;

    for (final line in _routeLines) {
      if (map.lines.contains(line)) {
        await map.removeLine(line);
      }
    }
    for (final circle in _waypointCircles) {
      if (map.circles.contains(circle)) {
        await map.removeCircle(circle);
      }
    }
    for (final circle in _midpointCircles) {
      if (map.circles.contains(circle)) {
        await map.removeCircle(circle);
      }
    }

    final nextWaypointCircles = <Circle>[];
    for (var index = 0; index < _points.length; index++) {
      final point = _points[index];
      final selected = _selectedWaypointIndex == index;
      nextWaypointCircles.add(
        await map.addCircle(
          CircleOptions(
            geometry: LatLng(point.latitude, point.longitude),
            circleRadius: selected ? 9 : 7,
            circleColor: index == 0
                ? '#1565C0'
                : selected
                    ? '#FF8F00'
                    : '#2E7D32',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: selected ? 3 : 2,
            draggable: true,
          ),
          <String, dynamic>{
            'kind': 'waypoint',
            'waypointIndex': index,
          },
        ),
      );
    }

    final nextRouteLines = <Line>[];
    if (_geometry.length >= 2) {
      final displayGeometry = simplifyPolylineForDisplay(
        _geometry,
        toleranceMeters: 1.5,
        maxPoints: 2200,
      ).map((point) => LatLng(point.latitude, point.longitude)).toList(
            growable: false,
          );

      if (displayGeometry.length >= 2) {
        nextRouteLines.add(
          await map.addLine(
            LineOptions(
              geometry: displayGeometry,
              lineColor: '#FFFFFF',
              lineWidth: _routeSelected ? 10 : 8,
              lineOpacity: 0.96,
              lineJoin: 'round',
            ),
            const <String, dynamic>{'kind': 'route'},
          ),
        );
        nextRouteLines.add(
          await map.addLine(
            LineOptions(
              geometry: displayGeometry,
              lineColor: _routeSelected ? '#1976D2' : '#2E7D32',
              lineWidth: _routeSelected ? 6 : 5,
              lineOpacity: 0.98,
              lineJoin: 'round',
            ),
            const <String, dynamic>{'kind': 'route'},
          ),
        );
      }
    }

    final nextMidpointCircles = <Circle>[];
    if (_routeSelected && !_routing && !_draggingFeature) {
      for (var index = 0; index < _routeLegs.length; index++) {
        final leg = _routeLegs[index];
        if (leg.length < 2) continue;
        final midpoint = pointAlongPolyline(leg);
        nextMidpointCircles.add(
          await map.addCircle(
            CircleOptions(
              geometry: LatLng(midpoint.latitude, midpoint.longitude),
              circleRadius: 7,
              circleColor: '#FFFFFF',
              circleStrokeColor: '#1976D2',
              circleStrokeWidth: 2.75,
              draggable: true,
            ),
            <String, dynamic>{
              'kind': 'midpoint',
              'legIndex': index,
            },
          ),
        );
      }
    }

    _waypointCircles = nextWaypointCircles;
    _midpointCircles = nextMidpointCircles;
    _routeLines = nextRouteLines;
  }

  void _onMapClick(math.Point<double> _, LatLng latLng) {
    if (_draggingFeature) return;
    _commitPoints([
      ..._points,
      GeoPoint(latitude: latLng.latitude, longitude: latLng.longitude),
    ]);
  }

  void _onMapLongClick(math.Point<double> _, LatLng latLng) {
    if (_geometry.length < 2 || _routeLegs.isEmpty) {
      _onMapClick(_, latLng);
      return;
    }

    final point = GeoPoint(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    var bestLeg = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < _routeLegs.length; index++) {
      final distance = distanceToPolylineMeters(point, _routeLegs[index]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestLeg = index;
      }
    }

    if (bestDistance > 120) {
      _onMapClick(_, latLng);
      return;
    }

    final next = List<GeoPoint>.of(_points)
      ..insert(bestLeg + 1, point);
    _commitPoints(next, selectedIndex: bestLeg + 1);
  }

  void _commitPoints(
    List<GeoPoint> next, {
    int? selectedIndex,
  }) {
    _undoStack.add(List<GeoPoint>.unmodifiable(_points));
    _redoStack.clear();
    setState(() {
      _points
        ..clear()
        ..addAll(next);
      _selectedWaypointIndex = selectedIndex;
      _routeSelected = next.length >= 2;
      _geometry = const [];
      _routeLegs = const [];
      _distanceMeters = 0;
      _duration = Duration.zero;
      _routingError = null;
    });
    unawaited(_syncMap());
    unawaited(_refreshRoute());
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List<GeoPoint>.unmodifiable(_points));
    final previous = _undoStack.removeLast();
    setState(() {
      _points
        ..clear()
        ..addAll(previous);
      _selectedWaypointIndex = null;
      _routeSelected = previous.length >= 2;
      _geometry = const [];
      _routeLegs = const [];
      _distanceMeters = 0;
      _duration = Duration.zero;
      _routingError = null;
    });
    unawaited(_syncMap());
    unawaited(_refreshRoute());
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List<GeoPoint>.unmodifiable(_points));
    final next = _redoStack.removeLast();
    setState(() {
      _points
        ..clear()
        ..addAll(next);
      _selectedWaypointIndex = null;
      _routeSelected = next.length >= 2;
      _geometry = const [];
      _routeLegs = const [];
      _distanceMeters = 0;
      _duration = Duration.zero;
      _routingError = null;
    });
    unawaited(_syncMap());
    unawaited(_refreshRoute());
  }

  void _clear() {
    if (_points.isEmpty) return;
    _undoStack.add(List<GeoPoint>.unmodifiable(_points));
    _redoStack.clear();
    _routingGeneration++;
    setState(() {
      _points.clear();
      _geometry = const [];
      _routeLegs = const [];
      _distanceMeters = 0;
      _duration = Duration.zero;
      _routing = false;
      _routingError = null;
      _selectedWaypointIndex = null;
      _routeSelected = false;
    });
    unawaited(_syncMap());
  }

  void _removeSelectedWaypoint() {
    final index = _selectedWaypointIndex;
    if (index == null || index < 0 || index >= _points.length) return;
    final next = List<GeoPoint>.of(_points)..removeAt(index);
    _commitPoints(next);
  }

  void _setProfile(RouteProfile profile) {
    if (_profile == profile) return;
    setState(() {
      _profile = profile;
      _geometry = const [];
      _routeLegs = const [];
      _distanceMeters = 0;
      _duration = Duration.zero;
      _routingError = null;
    });
    unawaited(_syncMap());
    unawaited(_refreshRoute());
  }

  Future<void> _refreshRoute() async {
    final generation = ++_routingGeneration;
    final requestedPoints = List<GeoPoint>.unmodifiable(_points);
    final profile = _profile;

    if (requestedPoints.length < 2) {
      if (!mounted || generation != _routingGeneration) return;
      setState(() {
        _routing = false;
        _routingError = null;
        _geometry = const [];
        _routeLegs = const [];
        _distanceMeters = 0;
        _duration = Duration.zero;
      });
      await _syncMap();
      return;
    }

    setState(() {
      _routing = true;
      _routingError = null;
    });

    try {
      final plan = await _routingService.route(
        requestedPoints,
        profile: profile,
      );

      if (!mounted || generation != _routingGeneration) return;

      final snapped = plan.snappedWaypoints.length == requestedPoints.length
          ? plan.snappedWaypoints
          : requestedPoints;
      final legs = _splitGeometryIntoLegs(plan.geometry, snapped);

      setState(() {
        _points
          ..clear()
          ..addAll(snapped);
        _geometry = plan.geometry;
        _routeLegs = legs;
        _distanceMeters = plan.distanceMeters;
        _duration = plan.estimatedDuration;
        _routing = false;
        _routingError = null;
        _routeSelected = true;
      });
      await _syncMap();
    } on Object catch (error) {
      if (!mounted || generation != _routingGeneration) return;
      setState(() {
        _routing = false;
        _geometry = const [];
        _routeLegs = const [];
        _distanceMeters = 0;
        _duration = Duration.zero;
        _routingError = _friendlyRoutingError(error);
      });
      await _syncMap();
    }
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
    for (var waypointIndex = 1;
        waypointIndex < waypoints.length - 1;
        waypointIndex++) {
      final minIndex = previousCut + 1;
      final remainingWaypoints = waypoints.length - waypointIndex - 1;
      final maxIndex = geometry.length - remainingWaypoints - 1;
      if (minIndex > maxIndex) return const [];

      var bestIndex = minIndex;
      var bestDistance = double.infinity;
      for (var geometryIndex = minIndex;
          geometryIndex <= maxIndex;
          geometryIndex++) {
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

  void _onCircleTapped(Circle circle) {
    final kind = circle.data?['kind'];
    if (kind == 'midpoint') {
      setState(() {
        _routeSelected = true;
        _selectedWaypointIndex = null;
      });
      unawaited(_syncMap());
      return;
    }

    final rawIndex = circle.data?['waypointIndex'];
    final index = rawIndex is int
        ? rawIndex
        : rawIndex is num
            ? rawIndex.toInt()
            : null;
    if (index == null) return;

    setState(() {
      _selectedWaypointIndex = index;
      _routeSelected = true;
    });
    unawaited(_syncMap());
  }

  void _onLineTapped(Line line) {
    if (line.data?['kind'] != 'route') return;
    setState(() {
      _routeSelected = !_routeSelected;
      if (!_routeSelected) {
        _selectedWaypointIndex = null;
      }
    });
    unawaited(_syncMap());
  }

  void _onFeatureDrag(
    math.Point<double> point,
    LatLng origin,
    LatLng current,
    LatLng delta,
    String id,
    Annotation? annotation,
    DragEventType eventType,
  ) {
    if (annotation is! Circle) return;

    final kind = annotation.data?['kind'];
    final rawIndex = kind == 'midpoint'
        ? annotation.data?['legIndex']
        : annotation.data?['waypointIndex'];
    final index = rawIndex is int
        ? rawIndex
        : rawIndex is num
            ? rawIndex.toInt()
            : null;
    if (index == null) return;

    if (eventType == DragEventType.start) {
      setState(() {
        _draggingFeature = true;
        _routeSelected = true;
        _selectedWaypointIndex = kind == 'midpoint' ? null : index;
      });
      unawaited(_updateDragPreview(kind, index, current));
      return;
    }

    if (eventType == DragEventType.drag) {
      unawaited(_updateDragPreview(kind, index, current));
      return;
    }

    if (eventType != DragEventType.end) return;

    unawaited(_clearDragPreview());
    setState(() => _draggingFeature = false);

    final next = List<GeoPoint>.of(_points);
    final moved = GeoPoint(
      latitude: current.latitude,
      longitude: current.longitude,
    );

    if (kind == 'midpoint') {
      final insertionIndex = index + 1;
      next.insert(insertionIndex, moved);
      _commitPoints(next, selectedIndex: insertionIndex);
      return;
    }

    if (index < 0 || index >= next.length) return;
    next[index] = moved;
    _commitPoints(next, selectedIndex: index);
  }

  Future<void> _updateDragPreview(
    String kind,
    int index,
    LatLng current,
  ) async {
    final map = _map;
    if (map == null || !_styleReady || map.isDisposed) return;

    final preview = <LatLng>[];
    if (kind == 'midpoint') {
      if (index < 0 || index + 1 >= _points.length) return;
      preview
        ..add(_latLng(_points[index]))
        ..add(current)
        ..add(_latLng(_points[index + 1]));
    } else {
      if (index < 0 || index >= _points.length) return;
      if (index > 0) preview.add(_latLng(_points[index - 1]));
      preview.add(current);
      if (index + 1 < _points.length) {
        preview.add(_latLng(_points[index + 1]));
      }
    }

    if (preview.length < 2) return;

    final options = LineOptions(
      geometry: preview,
      lineColor: '#1976D2',
      lineWidth: 4.5,
      lineOpacity: 0.85,
      lineJoin: 'round',
    );
    final existing = _dragPreviewLine;
    if (existing != null && map.lines.contains(existing)) {
      await map.updateLine(existing, options);
      return;
    }

    _dragPreviewLine = await map.addLine(
      options,
      const <String, dynamic>{'kind': 'dragPreview'},
    );
  }

  Future<void> _clearDragPreview() async {
    final map = _map;
    final preview = _dragPreviewLine;
    _dragPreviewLine = null;
    if (map != null &&
        preview != null &&
        !map.isDisposed &&
        map.lines.contains(preview)) {
      await map.removeLine(preview);
    }
  }

  LatLng _latLng(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final normalized = query.trim();
    if (normalized.length < 3) {
      setState(() {
        _searchResults = const [];
        _searchLoading = false;
        _searchError = null;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_performSearch(normalized));
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchLoading = true;
      _searchError = null;
    });

    try {
      final results = await _routingService.search(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _searchResults = results;
        _searchLoading = false;
        _searchError = results.isEmpty ? 'Nessun luogo trovato.' : null;
      });
    } on Object {
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _searchResults = const [];
        _searchLoading = false;
        _searchError = 'Ricerca non disponibile. Riprova.';
      });
    }
  }

  void _selectSearchResult(PlaceSearchResult result) {
    _searchController.clear();
    setState(() {
      _searchResults = const [];
      _searchLoading = false;
      _searchError = null;
    });

    final point = result.point;
    final map = _map;
    if (map != null && !map.isDisposed) {
      unawaited(
        map.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(point.latitude, point.longitude),
            15,
          ),
        ),
      );
    }
    _commitPoints([..._points, point]);
  }

  String _friendlyRoutingError(Object error) {
    final raw = error.toString();
    if (raw.contains('Failed to fetch') ||
        raw.contains('ClientException') ||
        raw.contains('XMLHttpRequest')) {
      return 'Il servizio di routing non è raggiungibile dal browser. Riprova tra poco.';
    }
    return 'Impossibile calcolare il percorso sulla rete stradale/sentieristica.';
  }

  String _distanceLabel() {
    final meters = _distanceMeters;
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _durationLabel() {
    if (_duration == Duration.zero) return '—';
    final hours = _duration.inHours;
    final minutes = _duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes.clamp(1, 59)} min';
    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    final panel = _PlannerPanel(
      searchController: _searchController,
      searchResults: _searchResults,
      searchLoading: _searchLoading,
      searchError: _searchError,
      onSearchChanged: _onSearchChanged,
      onSearchResultSelected: _selectSearchResult,
      pointCount: _points.length,
      distanceLabel: _distanceLabel(),
      durationLabel: _durationLabel(),
      profile: _profile,
      isRouting: _routing,
      routingError: _routingError,
      hasSnappedRoute: _geometry.length >= 2 && !_routing,
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
      hasSelectedWaypoint: _selectedWaypointIndex != null,
      onProfileChanged: _setProfile,
      onUndo: _undo,
      onRedo: _redo,
      onClear: _clear,
      onRemoveSelected: _removeSelectedWaypoint,
    );

    final map = MapLibreMap(
      styleString: MapConfig.plannerStyleUrl,
      initialCameraPosition: const CameraPosition(
        target: LatLng(45.232, 11.750),
        zoom: 11.5,
      ),
      onMapCreated: (controller) {
        _map = controller;
        controller.onCircleTapped.add(_onCircleTapped);
        controller.onLineTapped.add(_onLineTapped);
        controller.onFeatureDrag.add(_onFeatureDrag);
      },
      onStyleLoadedCallback: () {
        _styleReady = true;
        unawaited(_syncMap());
      },
      onMapClick: _onMapClick,
      onMapLongClick: _onMapLongClick,
      myLocationEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      dragEnabled: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrailPath · Web'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                avatar: Icon(
                  _routing ? Icons.sync_rounded : Icons.route_rounded,
                  size: 17,
                ),
                label: Text(_routing ? 'Calcolo percorso…' : 'Routing OSM'),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                SizedBox(width: 380, child: panel),
                const VerticalDivider(width: 1),
                Expanded(child: map),
              ],
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: map),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 430),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: panel,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlannerPanel extends StatelessWidget {
  const _PlannerPanel({
    required this.searchController,
    required this.searchResults,
    required this.searchLoading,
    required this.searchError,
    required this.onSearchChanged,
    required this.onSearchResultSelected,
    required this.pointCount,
    required this.distanceLabel,
    required this.durationLabel,
    required this.profile,
    required this.isRouting,
    required this.routingError,
    required this.hasSnappedRoute,
    required this.canUndo,
    required this.canRedo,
    required this.hasSelectedWaypoint,
    required this.onProfileChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onRemoveSelected,
  });

  final TextEditingController searchController;
  final List<PlaceSearchResult> searchResults;
  final bool searchLoading;
  final String? searchError;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PlaceSearchResult> onSearchResultSelected;
  final int pointCount;
  final String distanceLabel;
  final String durationLabel;
  final RouteProfile profile;
  final bool isRouting;
  final String? routingError;
  final bool hasSnappedRoute;
  final bool canUndo;
  final bool canRedo;
  final bool hasSelectedWaypoint;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Pianifica un percorso',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Click: aggiungi un punto · trascina: modifica · pressione lunga sulla traccia: inserisci un waypoint.',
          ),
          const SizedBox(height: 14),
          SearchBar(
            controller: searchController,
            hintText: 'Cerca luogo o indirizzo',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (searchLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
            onChanged: onSearchChanged,
          ),
          if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 6),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final result in searchResults.take(5))
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(
                        result.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        result.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.add_location_alt_outlined),
                      onTap: () => onSearchResultSelected(result),
                    ),
                ],
              ),
            ),
          ] else if (searchError != null) ...[
            const SizedBox(height: 6),
            Text(
              searchError!,
              style: TextStyle(
                color: scheme.error,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SegmentedButton<RouteProfile>(
            segments: const [
              ButtonSegment(
                value: RouteProfile.hiking,
                icon: Icon(Icons.hiking_rounded),
                label: Text('A piedi'),
              ),
              ButtonSegment(
                value: RouteProfile.cycling,
                icon: Icon(Icons.directions_bike_rounded),
                label: Text('Bici'),
              ),
            ],
            selected: {profile},
            onSelectionChanged: isRouting
                ? null
                : (selection) => onProfileChanged(selection.first),
          ),
          const SizedBox(height: 16),
          if (isRouting) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          if (routingError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_rounded, color: scheme.onErrorContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      routingError!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$pointCount punti · $distanceLabel',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        hasSnappedRoute
                            ? Icons.check_circle_rounded
                            : Icons.more_horiz_rounded,
                        size: 18,
                        color: hasSnappedRoute ? scheme.primary : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasSnappedRoute
                              ? 'Percorso agganciato alla rete · $durationLabel'
                              : pointCount < 2
                                  ? 'Aggiungi almeno 2 punti'
                                  : 'Calcolo percorso…',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !isRouting && canUndo ? onUndo : null,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !isRouting && canRedo ? onRedo : null,
                  icon: const Icon(Icons.redo_rounded),
                  label: const Text('Ripeti'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasSelectedWaypoint) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isRouting ? null : onRemoveSelected,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                label: const Text('Rimuovi punto selezionato'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: pointCount == 0 ? null : onClear,
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Pulisci percorso'),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Routing reale OSM attivo. GPS in background, download offline e notifiche restano funzioni da verificare sull’APK Android.',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebRoutingService {
  _WebRoutingService() : _client = http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 12);
  static const _maxWaypointsPerRequest = 20;

  Future<RoutePlan> route(
    List<GeoPoint> points, {
    required RouteProfile profile,
  }) async {
    if (points.length < 2) {
      throw const RoutingException('At least two points are required.');
    }

    final chunks = chunkRouteWaypoints(
      points,
      maxPointsPerChunk: _maxWaypointsPerRequest,
    );

    final plans = <RoutePlan>[];
    for (final chunk in chunks) {
      plans.add(await _routeChunk(chunk, profile));
    }

    if (plans.length == 1) return plans.single;

    final geometry = <GeoPoint>[];
    final snappedWaypoints = <GeoPoint>[];
    var distanceMeters = 0.0;
    var durationSeconds = 0;

    for (var index = 0; index < plans.length; index++) {
      final plan = plans[index];
      distanceMeters += plan.distanceMeters;
      durationSeconds += plan.estimatedDuration.inSeconds;

      if (index == 0) {
        geometry.addAll(plan.geometry);
        snappedWaypoints.addAll(plan.snappedWaypoints);
        continue;
      }

      if (plan.geometry.isNotEmpty) {
        final seamDistance = geometry.isEmpty
            ? double.infinity
            : haversineMeters(geometry.last, plan.geometry.first);
        geometry.addAll(
          seamDistance <= 2 ? plan.geometry.skip(1) : plan.geometry,
        );
      }

      if (plan.snappedWaypoints.isNotEmpty) {
        snappedWaypoints.addAll(plan.snappedWaypoints.skip(1));
      }
    }

    if (geometry.length < 2 || snappedWaypoints.length != points.length) {
      throw const RoutingException('Incomplete chunked route.');
    }

    return RoutePlan(
      geometry: List<GeoPoint>.unmodifiable(geometry),
      distanceMeters: distanceMeters,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: Duration(seconds: durationSeconds),
      profile: profile,
      isSnapped: true,
      routingSource: 'routing.openstreetmap.de',
      snappedWaypoints: List<GeoPoint>.unmodifiable(snappedWaypoints),
    );
  }

  Future<List<PlaceSearchResult>> search(String query) async {
    final uri = Uri.parse(MapConfig.searchEndpoint).replace(
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'addressdetails': '0',
      },
    );

    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Accept-Language': 'it,en;q=0.8',
      },
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw StateError('Search returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    final results = <PlaceSearchResult>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final displayName = item['display_name']?.toString().trim() ?? '';
      if (displayName.isEmpty) continue;
      final name = item['name']?.toString().trim();
      results.add(
        PlaceSearchResult(
          name: name == null || name.isEmpty
              ? displayName.split(',').first
              : name,
          displayName: displayName,
          point: GeoPoint(latitude: lat, longitude: lon),
        ),
      );
    }
    return List<PlaceSearchResult>.unmodifiable(results);
  }

  Future<RoutePlan> _routeChunk(
    List<GeoPoint> points,
    RouteProfile profile,
  ) async {
    final service = switch (profile) {
      RouteProfile.mountainBike || RouteProfile.cycling => 'routed-bike',
      RouteProfile.hiking ||
      RouteProfile.trailRunning ||
      RouteProfile.walking ||
      RouteProfile.dogWalk => 'routed-foot',
    };

    final coordinates = points
        .map(
          (point) =>
              '${point.longitude.toStringAsFixed(6)},${point.latitude.toStringAsFixed(6)}',
        )
        .join(';');

    final uri = Uri.parse(
      'https://routing.openstreetmap.de/$service/route/v1/driving/$coordinates',
    ).replace(
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw RoutingException(
        'Routing service returned HTTP ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> || payload['code'] != 'Ok') {
      throw const RoutingException('Routing provider did not return a route.');
    }

    final routes = payload['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) {
      throw const RoutingException('No route found.');
    }

    final route = Map<String, dynamic>.from(routes.first as Map);
    final geometryJson = route['geometry'];
    if (geometryJson is! Map) {
      throw const RoutingException('Missing route geometry.');
    }

    final coordinatesJson = geometryJson['coordinates'];
    if (coordinatesJson is! List) {
      throw const RoutingException('Invalid route geometry.');
    }

    final geometry = <GeoPoint>[];
    for (final coordinate in coordinatesJson) {
      if (coordinate is! List || coordinate.length < 2) continue;
      final longitude = coordinate[0];
      final latitude = coordinate[1];
      if (longitude is num && latitude is num) {
        geometry.add(
          GeoPoint(
            latitude: latitude.toDouble(),
            longitude: longitude.toDouble(),
          ),
        );
      }
    }

    if (geometry.length < 2) {
      throw const RoutingException('Empty route geometry.');
    }

    final snappedWaypoints = <GeoPoint>[];
    final waypointsJson = payload['waypoints'];
    if (waypointsJson is List) {
      for (final waypoint in waypointsJson) {
        if (waypoint is! Map) continue;
        final location = waypoint['location'];
        if (location is! List || location.length < 2) continue;
        final longitude = location[0];
        final latitude = location[1];
        if (longitude is num && latitude is num) {
          snappedWaypoints.add(
            GeoPoint(
              latitude: latitude.toDouble(),
              longitude: longitude.toDouble(),
            ),
          );
        }
      }
    }

    if (snappedWaypoints.length != points.length) {
      throw const RoutingException('Waypoint snapping is incomplete.');
    }

    final distance = (route['distance'] as num?)?.toDouble() ?? 0;
    final seconds = (route['duration'] as num?)?.round() ?? 0;

    return RoutePlan(
      geometry: List<GeoPoint>.unmodifiable(geometry),
      distanceMeters: distance,
      ascentMeters: 0,
      descentMeters: 0,
      estimatedDuration: Duration(seconds: seconds),
      profile: profile,
      isSnapped: true,
      routingSource: 'routing.openstreetmap.de',
      snappedWaypoints: List<GeoPoint>.unmodifiable(snappedWaypoints),
    );
  }

  void dispose() => _client.close();
}

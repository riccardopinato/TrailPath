import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/collection_sampling.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/planner_service_providers.dart';
import 'package:trail_path/features/planner/application/route_planner_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TrailPathWebPreview()));
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

class _PreviewScreen extends ConsumerStatefulWidget {
  const _PreviewScreen();

  @override
  ConsumerState<_PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<_PreviewScreen> {
  MapLibreMapController? _map;
  bool _styleReady = false;
  bool _routeSelected = false;
  bool _draggingFeature = false;
  int? _selectedWaypointIndex;
  List<Line> _routeLines = const [];
  List<Circle> _waypointCircles = const [];
  List<Circle> _midpointCircles = const [];
  Circle? _searchCircle;
  PlaceSearchResult? _searchResult;
  RoutePlannerState? _pendingPlanner;
  bool _syncRunning = false;
  bool _searchBusy = false;
  bool _traceMode = false;
  bool _traceDrawing = false;
  bool _traceProcessing = false;
  int? _tracePointerId;
  List<Offset> _traceScreenPoints = const [];
  List<PlaceSearchResult> _searchResults = const [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _pendingPlanner = null;
    _searchController.dispose();
    _map?.dispose();
    super.dispose();
  }

  void _scheduleMapSync(RoutePlannerState planner) {
    _pendingPlanner = planner;
    if (_syncRunning) {
      return;
    }
    _syncRunning = true;
    unawaited(_drainMapSync());
  }

  Future<void> _drainMapSync() async {
    try {
      while (mounted && _pendingPlanner != null) {
        final planner = _pendingPlanner!;
        _pendingPlanner = null;
        await _syncMap(planner);
      }
    } finally {
      _syncRunning = false;
      if (mounted && _pendingPlanner != null) {
        _scheduleMapSync(_pendingPlanner!);
      }
    }
  }

  Future<void> _syncMap(RoutePlannerState planner) async {
    final map = _map;
    if (map == null || !_styleReady || map.isDisposed) {
      return;
    }

    final displayGeometry = simplifyPolylineForDisplay(
      planner.geometry,
      toleranceMeters: 1.5,
      maxPoints: 2200,
    );
    final routeGeometry = displayGeometry
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    final routeOptions = routeGeometry.length >= 2
        ? <LineOptions>[
            LineOptions(
              geometry: routeGeometry,
              lineColor: _routeSelected ? '#1976D2' : '#FFFFFF',
              lineWidth: _routeSelected ? 10 : 8,
              lineOpacity: _routeSelected ? 0.82 : 0.92,
              lineJoin: 'round',
            ),
            LineOptions(
              geometry: routeGeometry,
              lineColor: '#2E7D32',
              lineWidth: 5,
              lineOpacity: 0.98,
              lineJoin: 'round',
            ),
          ]
        : const <LineOptions>[];

    final routeLinesCurrent =
        _routeLines.length == routeOptions.length &&
        _routeLines.every(map.lines.contains);
    if (routeLinesCurrent) {
      for (var index = 0; index < _routeLines.length; index++) {
        await map.updateLine(_routeLines[index], routeOptions[index]);
      }
    } else {
      final stale = _routeLines.where(map.lines.contains).toList(growable: false);
      if (stale.isNotEmpty) {
        await map.removeLines(stale);
      }
      _routeLines = routeOptions.isEmpty
          ? const []
          : await map.addLines(routeOptions, const [
              <String, dynamic>{'kind': 'route', 'role': 'casing'},
              <String, dynamic>{'kind': 'route', 'role': 'route'},
            ]);
    }

    final waypointOptions = <CircleOptions>[
      for (var index = 0; index < planner.points.length; index++)
        CircleOptions(
          geometry: LatLng(
            planner.points[index].latitude,
            planner.points[index].longitude,
          ),
          circleRadius: _selectedWaypointIndex == index
              ? 9
              : index == 0 || index == planner.points.length - 1
              ? 7
              : 5.5,
          circleColor: _selectedWaypointIndex == index
              ? '#1976D2'
              : index == 0
              ? '#205B38'
              : index == planner.points.length - 1
              ? '#E86A45'
              : '#FFFFFF',
          circleStrokeColor: _selectedWaypointIndex == index
              ? '#FFFFFF'
              : '#2F6F45',
          circleStrokeWidth: _selectedWaypointIndex == index ? 3.5 : 2.5,
          draggable: true,
        ),
    ];

    final waypointCirclesCurrent =
        _waypointCircles.length == waypointOptions.length &&
        _waypointCircles.every(map.circles.contains);
    if (waypointCirclesCurrent) {
      for (var index = 0; index < _waypointCircles.length; index++) {
        await map.updateCircle(_waypointCircles[index], waypointOptions[index]);
      }
    } else {
      final stale = _waypointCircles
          .where(map.circles.contains)
          .toList(growable: false);
      if (stale.isNotEmpty) {
        await map.removeCircles(stale);
      }
      _waypointCircles = waypointOptions.isEmpty
          ? const []
          : await map.addCircles(waypointOptions, [
              for (var index = 0; index < waypointOptions.length; index++)
                <String, dynamic>{'kind': 'waypoint', 'waypointIndex': index},
            ]);
    }

    final showHandles =
        _routeSelected &&
        !_draggingFeature &&
        !planner.isRouting &&
        planner.isSnapped &&
        planner.editHandles.length == planner.points.length - 1;
    final midpointOptions = showHandles
        ? <CircleOptions>[
            for (final handle in planner.editHandles)
              CircleOptions(
                geometry: LatLng(handle.latitude, handle.longitude),
                circleRadius: 7.5,
                circleColor: '#FFFFFF',
                circleStrokeColor: '#1976D2',
                circleStrokeWidth: 2.75,
                draggable: true,
              ),
          ]
        : const <CircleOptions>[];

    final midpointCirclesCurrent =
        _midpointCircles.length == midpointOptions.length &&
        _midpointCircles.every(map.circles.contains);
    if (midpointCirclesCurrent) {
      for (var index = 0; index < _midpointCircles.length; index++) {
        await map.updateCircle(_midpointCircles[index], midpointOptions[index]);
      }
    } else {
      final stale = _midpointCircles
          .where(map.circles.contains)
          .toList(growable: false);
      if (stale.isNotEmpty) {
        await map.removeCircles(stale);
      }
      _midpointCircles = midpointOptions.isEmpty
          ? const []
          : await map.addCircles(midpointOptions, [
              for (var index = 0; index < midpointOptions.length; index++)
                <String, dynamic>{'kind': 'midpoint', 'legIndex': index},
            ]);
    }

    final result = _searchResult;
    if (result == null) {
      final stale = _searchCircle;
      _searchCircle = null;
      if (stale != null && map.circles.contains(stale)) {
        await map.removeCircle(stale);
      }
    } else {
      final options = CircleOptions(
        geometry: LatLng(result.point.latitude, result.point.longitude),
        circleRadius: 8,
        circleColor: '#1565C0',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.5,
      );
      final current = _searchCircle;
      if (current != null && map.circles.contains(current)) {
        await map.updateCircle(current, options);
      } else {
        _searchCircle = await map.addCircle(options, const <String, dynamic>{
          'kind': 'search',
        });
      }
    }
  }

  void _addPoint(math.Point<double> _, LatLng latLng) {
    if (_selectedWaypointIndex != null || _routeSelected) {
      setState(() {
        _selectedWaypointIndex = null;
        _routeSelected = false;
      });
    }
    ref
        .read(routePlannerProvider.notifier)
        .addPoint(
          GeoPoint(latitude: latLng.latitude, longitude: latLng.longitude),
        );
  }

  Future<void> _insertPoint(math.Point<double> _, LatLng latLng) async {
    final planner = ref.read(routePlannerProvider);
    final candidate = GeoPoint(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    if (planner.geometry.length >= 2 &&
        distanceToPolylineMeters(candidate, planner.geometry) > 80) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tieni premuto più vicino al percorso.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _selectedWaypointIndex = null;
        _routeSelected = true;
      });
    }
    ref.read(routePlannerProvider.notifier).insertPointNearRoute(candidate);
  }

  void _onCircleTapped(Circle circle) {
    final kind = circle.data?['kind'];
    if (kind == 'midpoint') {
      if (!_routeSelected && mounted) {
        setState(() => _routeSelected = true);
        _scheduleMapSync(ref.read(routePlannerProvider));
      }
      return;
    }

    final rawIndex = circle.data?['waypointIndex'];
    final index = rawIndex is int
        ? rawIndex
        : rawIndex is num
        ? rawIndex.toInt()
        : null;
    if (index == null) {
      return;
    }

    setState(() {
      _selectedWaypointIndex = index;
      _routeSelected = true;
    });
    _scheduleMapSync(ref.read(routePlannerProvider));
  }

  void _onLineTapped(Line line) {
    if (line.data?['kind'] != 'route') {
      return;
    }
    setState(() {
      _routeSelected = !_routeSelected;
      if (!_routeSelected) {
        _selectedWaypointIndex = null;
      }
    });
    _scheduleMapSync(ref.read(routePlannerProvider));
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
    if (annotation is! Circle) {
      return;
    }

    final kind = annotation.data?['kind'];
    final rawIndex = kind == 'midpoint'
        ? (annotation.data?['legIndex'])
        : (annotation.data?['waypointIndex']);
    final index = rawIndex is int
        ? rawIndex
        : rawIndex is num
        ? rawIndex.toInt()
        : null;
    if (index == null) {
      return;
    }

    if (eventType == DragEventType.start) {
      setState(() {
        _draggingFeature = true;
        _routeSelected = true;
        _selectedWaypointIndex = kind == 'midpoint' ? null : index;
      });
      return;
    }

    if (eventType != DragEventType.end) {
      return;
    }

    final pointValue = GeoPoint(
      latitude: current.latitude,
      longitude: current.longitude,
    );
    if (kind == 'midpoint') {
      final insertedIndex = index + 1;
      setState(() {
        _draggingFeature = false;
        _selectedWaypointIndex = insertedIndex;
      });
      ref
          .read(routePlannerProvider.notifier)
          .insertPointAt(insertedIndex, pointValue);
      return;
    }

    setState(() {
      _draggingFeature = false;
      _selectedWaypointIndex = index;
    });
    ref.read(routePlannerProvider.notifier).movePoint(index, pointValue);
  }

  void _removeSelectedWaypoint() {
    final index = _selectedWaypointIndex;
    if (index == null) {
      return;
    }
    setState(() => _selectedWaypointIndex = null);
    ref.read(routePlannerProvider.notifier).removePoint(index);
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.length < 2 || _searchBusy) {
      return;
    }

    setState(() {
      _searchBusy = true;
      _searchResults = const [];
    });

    try {
      final results = await ref
          .read(placeSearchServiceProvider)
          .search(
            query,
            languageCode: Localizations.localeOf(context).languageCode,
          );
      if (!mounted) {
        return;
      }
      setState(() => _searchResults = results);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ricerca non disponibile: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _searchBusy = false);
      }
    }
  }

  Future<void> _focusSearchResult(PlaceSearchResult result) async {
    setState(() {
      _searchResult = result;
      _searchResults = const [];
      _searchController.text = result.name;
    });
    _scheduleMapSync(ref.read(routePlannerProvider));

    final map = _map;
    if (map != null) {
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(result.point.latitude, result.point.longitude),
          15.5,
        ),
      );
    }
  }

  void _addSearchResultAsWaypoint() {
    final result = _searchResult;
    if (result == null) {
      return;
    }
    ref.read(routePlannerProvider.notifier).addPoint(result.point);
  }

  void _toggleTraceMode() {
    if (_traceProcessing) {
      return;
    }
    setState(() {
      _traceMode = !_traceMode;
      _traceDrawing = false;
      _tracePointerId = null;
      _traceScreenPoints = const [];
      _selectedWaypointIndex = null;
      if (_traceMode) {
        _routeSelected = false;
      }
    });
  }

  void _onTracePointerDown(PointerDownEvent event) {
    if (!_traceMode ||
        _traceProcessing ||
        _tracePointerId != null ||
        ref.read(routePlannerProvider).isRouting) {
      return;
    }
    _tracePointerId = event.pointer;
    setState(() {
      _traceDrawing = true;
      _traceScreenPoints = [event.localPosition];
    });
  }

  void _onTracePointerMove(PointerMoveEvent event) {
    if (!_traceMode ||
        !_traceDrawing ||
        _tracePointerId != event.pointer ||
        _traceScreenPoints.isEmpty) {
      return;
    }
    if ((event.localPosition - _traceScreenPoints.last).distance < 5) {
      return;
    }
    setState(() {
      _traceScreenPoints = [..._traceScreenPoints, event.localPosition];
    });
  }

  void _onTracePointerUp(PointerUpEvent event) {
    if (_tracePointerId != event.pointer) {
      return;
    }

    final points = List<Offset>.of(_traceScreenPoints);
    if (points.isEmpty || (event.localPosition - points.last).distance >= 2) {
      points.add(event.localPosition);
    }

    _tracePointerId = null;
    setState(() {
      _traceDrawing = false;
      _traceScreenPoints = const [];
    });
    unawaited(_commitTrace(points));
  }

  void _onTracePointerCancel(PointerCancelEvent event) {
    if (_tracePointerId != event.pointer) {
      return;
    }
    _tracePointerId = null;
    if (mounted) {
      setState(() {
        _traceDrawing = false;
        _traceScreenPoints = const [];
      });
    }
  }

  Future<void> _commitTrace(List<Offset> screenPoints) async {
    final map = _map;
    if (map == null || screenPoints.length < 2 || _traceProcessing) {
      return;
    }

    final sampled = sampleEvenly(screenPoints, maxItems: 56);
    setState(() => _traceProcessing = true);
    try {
      final geoPoints = <GeoPoint>[];
      for (final offset in sampled) {
        final coordinates = await map.toLatLng(
          math.Point<double>(offset.dx, offset.dy),
        );
        geoPoints.add(
          GeoPoint(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      final accepted = ref.read(routePlannerProvider.notifier).addTrace(
            geoPoints,
          );
      if (!accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Traccia troppo corta.')),
        );
        return;
      }

      setState(() {
        _routeSelected = true;
        _selectedWaypointIndex = null;
      });
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Traccia non disponibile: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _traceProcessing = false);
      }
    }
  }

  String _distanceLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _durationLabel(Duration duration) {
    if (duration == Duration.zero) {
      return '—';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '${minutes.clamp(1, 59)} min';
    }
    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(routePlannerProvider);
    final controller = ref.read(routePlannerProvider.notifier);

    ref.listen<RoutePlannerState>(routePlannerProvider, (previous, next) {
      if (previous == null ||
          !identical(previous.points, next.points) ||
          !identical(previous.geometry, next.geometry) ||
          previous.isRouting != next.isRouting) {
        _scheduleMapSync(next);
      }
    });

    final panel = _PlannerPanel(
      planner: planner,
      distanceLabel: _distanceLabel(planner.distanceMeters),
      durationLabel: _durationLabel(planner.estimatedDuration),
      searchController: _searchController,
      searchBusy: _searchBusy,
      searchResults: _searchResults,
      selectedSearchResult: _searchResult,
      selectedWaypointIndex: _selectedWaypointIndex,
      traceMode: _traceMode,
      traceProcessing: _traceProcessing,
      onSearch: _searchPlaces,
      onSearchSelected: _focusSearchResult,
      onAddSearchWaypoint: _addSearchResultAsWaypoint,
      onToggleTrace: _toggleTraceMode,
      onProfileChanged: controller.setProfile,
      onUndo: planner.canUndo ? controller.undo : null,
      onRedo: planner.canRedo ? controller.redo : null,
      onRemoveWaypoint: _selectedWaypointIndex == null
          ? null
          : _removeSelectedWaypoint,
      onClear: planner.points.isEmpty
          ? null
          : () {
              setState(() {
                _selectedWaypointIndex = null;
                _routeSelected = false;
              });
              controller.clear();
            },
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
        _scheduleMapSync(ref.read(routePlannerProvider));
      },
      onMapClick: (point, coordinates) {
        if (!_traceMode) {
          _addPoint(point, coordinates);
        }
      },
      onMapLongClick: (point, coordinates) {
        if (!_traceMode) {
          unawaited(_insertPoint(point, coordinates));
        }
      },
      annotationOrder: const [AnnotationType.line, AnnotationType.circle],
      annotationConsumeTapEvents: const [
        AnnotationType.line,
        AnnotationType.circle,
      ],
      doubleClickZoomEnabled: false,
      dragEnabled: true,
      myLocationEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
    );

    final mapSurface = Stack(
      children: [
        Positioned.fill(child: map),
        if (_traceMode)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onTracePointerDown,
              onPointerMove: _onTracePointerMove,
              onPointerUp: _onTracePointerUp,
              onPointerCancel: _onTracePointerCancel,
              child: CustomPaint(
                painter: _TracePainter(
                  points: _traceScreenPoints,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
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
                  planner.isRouting ? Icons.sync_rounded : Icons.route_rounded,
                  size: 17,
                ),
                label: Text(
                  planner.isRouting
                      ? 'Calcolo percorso…'
                      : planner.isSnapped
                      ? 'Routing OSM'
                      : 'Planner condiviso',
                ),
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
                SizedBox(width: 400, child: panel),
                const VerticalDivider(width: 1),
                Expanded(child: mapSurface),
              ],
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: mapSurface),
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
    required this.planner,
    required this.distanceLabel,
    required this.durationLabel,
    required this.searchController,
    required this.searchBusy,
    required this.searchResults,
    required this.selectedSearchResult,
    required this.selectedWaypointIndex,
    required this.traceMode,
    required this.traceProcessing,
    required this.onSearch,
    required this.onSearchSelected,
    required this.onAddSearchWaypoint,
    required this.onToggleTrace,
    required this.onProfileChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onRemoveWaypoint,
    required this.onClear,
  });

  final RoutePlannerState planner;
  final String distanceLabel;
  final String durationLabel;
  final TextEditingController searchController;
  final bool searchBusy;
  final List<PlaceSearchResult> searchResults;
  final PlaceSearchResult? selectedSearchResult;
  final int? selectedWaypointIndex;
  final bool traceMode;
  final bool traceProcessing;
  final VoidCallback onSearch;
  final ValueChanged<PlaceSearchResult> onSearchSelected;
  final VoidCallback onAddSearchWaypoint;
  final VoidCallback onToggleTrace;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onRemoveWaypoint;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final routeReady =
        planner.geometry.length >= 2 && planner.isSnapped && !planner.isRouting;

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
            'Il Web usa lo stesso core planner dell’app: waypoint, profilo, '
            'routing, editing, undo/redo ed elevazione condividono la stessa '
            'logica applicativa.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              labelText: 'Cerca luogo o sentiero',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchBusy
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Cerca',
                      onPressed: onSearch,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
            ),
          ),
          if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final result in searchResults.take(4))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
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
                onTap: () => onSearchSelected(result),
              ),
          ],
          if (selectedSearchResult != null) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onAddSearchWaypoint,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(
                'Aggiungi ${selectedSearchResult!.name} al percorso',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<RouteProfile>(
                  value: planner.profile,
                  isExpanded: true,
                  items: [
                    for (final profile in RouteProfile.values)
                      DropdownMenuItem(
                        value: profile,
                        child: Text(_profileLabel(profile)),
                      ),
                  ],
                  onChanged: planner.isRouting
                      ? null
                      : (profile) {
                          if (profile != null) {
                            onProfileChanged(profile);
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (planner.isRouting || planner.isElevationLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          if (planner.routingError != null) ...[
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
                      _friendlyRoutingError(planner.routingError!),
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
                  _MetricRow(
                    icon: Icons.route_rounded,
                    label:
                        '${planner.points.length} punti · $distanceLabel · $durationLabel',
                  ),
                  const SizedBox(height: 8),
                  _MetricRow(
                    icon: routeReady
                        ? Icons.check_circle_rounded
                        : Icons.more_horiz_rounded,
                    label: routeReady
                        ? 'Percorso agganciato · ${planner.routingSource}'
                        : planner.points.length < 2
                        ? 'Aggiungi almeno 2 punti'
                        : planner.isRouting
                        ? 'Calcolo percorso…'
                        : 'Percorso non disponibile',
                    iconColor: routeReady ? scheme.primary : null,
                  ),
                  if (planner.hasElevation) ...[
                    const SizedBox(height: 8),
                    _MetricRow(
                      icon: Icons.terrain_rounded,
                      label:
                          '+${planner.ascentMeters.round()} m / '
                          '-${planner.descentMeters.round()} m',
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (selectedWaypointIndex != null) ...[
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: onRemoveWaypoint,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(
                'Rimuovi waypoint ${selectedWaypointIndex! + 1}',
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: planner.isRouting || traceProcessing
                ? null
                : onToggleTrace,
            icon: Icon(
              traceMode ? Icons.close_rounded : Icons.draw_rounded,
            ),
            label: Text(
              traceMode ? 'Esci da Trace Mode' : 'Trace Mode',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: planner.isRouting ? null : onUndo,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: planner.isRouting ? null : onRedo,
                  icon: const Icon(Icons.redo_rounded),
                  label: const Text('Ripeti'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: onClear,
            icon: const Icon(Icons.delete_sweep_rounded),
            label: const Text('Pulisci percorso'),
          ),
          const SizedBox(height: 12),
          Text(
            'Click: aggiungi waypoint · long-press: inserisci sulla route · '
            'drag: sposta waypoint/midpoint.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'GPS in background, registrazione e download offline restano '
            'funzioni native da validare sull’APK Android.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({
    required this.points,
    required this.color,
  });

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _profileLabel(RouteProfile profile) {
  return switch (profile) {
    RouteProfile.hiking => 'Hiking',
    RouteProfile.trailRunning => 'Trail running',
    RouteProfile.walking => 'Walking',
    RouteProfile.mountainBike => 'Mountain bike',
    RouteProfile.cycling => 'Cycling',
    RouteProfile.dogWalk => 'Dog walk',
  };
}

String _friendlyRoutingError(String raw) {
  if (raw.contains('timed out') ||
      raw.contains('network request failed') ||
      raw.contains('ClientException')) {
    return 'Il servizio di routing non è raggiungibile. Riprova tra poco.';
  }
  return raw.replaceFirst('RoutingException: ', '');
}

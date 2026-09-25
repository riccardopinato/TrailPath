import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/collection_sampling.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/planner/application/route_planner_controller.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  static const _fallbackCenter = LatLng(45.232, 11.750);

  MapLibreMapController? _mapController;
  StreamSubscription<PositionSample>? _positionSubscription;
  PositionSample? _position;
  bool _permissionGranted = false;
  bool _locationServiceEnabled = true;
  bool _locationBusy = true;
  bool _styleReady = false;
  bool _searchBusy = false;
  PlaceSearchResult? _searchResult;
  int? _selectedWaypointIndex;
  bool _routeSelected = false;
  bool _draggingFeature = false;
  bool _traceMode = false;
  bool _traceDrawing = false;
  bool _traceProcessing = false;
  int? _tracePointerId;
  List<Offset> _traceScreenPoints = const [];
  bool _annotationSyncRunning = false;
  bool _annotationSyncQueued = false;
  List<Line> _routeLines = const [];
  List<Circle> _waypointCircles = const [];
  List<Circle> _midpointCircles = const [];
  Circle? _searchCircle;
  Line? _dragPreviewLine;
  String? _locationError;
  final TextEditingController _searchController = TextEditingController();

  bool get _runningWidgetTest =>
      Platform.environment['FLUTTER_TEST']?.toLowerCase() == 'true';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_initializeLocation);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (mounted) {
      setState(() {
        _locationBusy = true;
        _locationError = null;
      });
    }

    if (_runningWidgetTest) {
      if (mounted) {
        setState(() => _locationBusy = false);
      }
      return;
    }

    try {
      final engine = ref.read(locationEngineProvider);
      final serviceEnabled = await engine.isServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationServiceEnabled = false;
            _locationBusy = false;
          });
        }
        return;
      }

      var permission = await engine.hasPermission();
      if (!permission) {
        permission = await engine.requestPermission();
      }

      if (!permission) {
        if (mounted) {
          setState(() {
            _permissionGranted = false;
            _locationBusy = false;
          });
        }
        return;
      }

      final current = await engine.current();
      if (!mounted) {
        return;
      }

      setState(() {
        _permissionGranted = true;
        _locationServiceEnabled = true;
        _locationBusy = false;
        _position = current;
        _locationError = null;
      });

      if (current != null) {
        await _focusPosition(current, zoom: 15.5);
      }

      await _positionSubscription?.cancel();
      _positionSubscription = engine.watch().listen(
        (sample) {
          if (!mounted) {
            return;
          }
          setState(() => _position = sample);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (mounted) {
            setState(() => _locationError = error.toString());
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _locationBusy = false;
          _locationError = error.toString();
        });
      }
    }
  }

  Future<void> _focusPosition(PositionSample sample, {double zoom = 16}) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(sample.point.latitude, sample.point.longitude),
        zoom,
      ),
    );
  }

  Future<void> _resolveLocationIssue() async {
    if (_locationBusy) {
      return;
    }

    final engine = ref.read(locationEngineProvider);
    try {
      if (!_locationServiceEnabled) {
        await engine.openLocationSettings();
      } else if (!_permissionGranted) {
        await engine.openAppSettings();
      }
    } on Object {
      // Re-check below and surface a localized status chip if access remains
      // unavailable.
    }

    if (mounted) {
      await _initializeLocation();
    }
  }

  Future<void> _centerOnUser() async {
    final engine = ref.read(locationEngineProvider);
    if (_locationBusy) {
      return;
    }

    if (!_locationServiceEnabled || !_permissionGranted) {
      await _initializeLocation();
      return;
    }

    var sample = _position;
    sample ??= await engine.current();
    if (sample != null) {
      if (mounted) {
        setState(() => _position = sample);
      }
      await _focusPosition(sample);
    }
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.length < 2 || _searchBusy) {
      return;
    }

    setState(() => _searchBusy = true);
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final results = await ref
          .read(placeSearchServiceProvider)
          .search(query, languageCode: languageCode);

      if (!mounted) {
        return;
      }

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).noSearchResults)),
        );
        return;
      }

      final selected = await showModalBottomSheet<PlaceSearchResult>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          final strings = AppLocalizations.of(context);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                    child: Text(
                      strings.searchPlace,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            result.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            result.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(result),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: Text(
                      'Search data © OpenStreetMap contributors',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (selected != null && mounted) {
        await _focusSearchResult(selected);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).searchFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _searchBusy = false);
      }
    }
  }

  Future<void> _focusSearchResult(PlaceSearchResult result) async {
    if (mounted) {
      setState(() => _searchResult = result);
    }
    await _syncPlannerAnnotations();

    final controller = _mapController;
    if (controller == null) {
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(result.point.latitude, result.point.longitude),
        15.5,
      ),
    );
  }

  void _addWaypoint(LatLng coordinates) {
    if (_selectedWaypointIndex != null && mounted) {
      setState(() => _selectedWaypointIndex = null);
    }
    ref
        .read(routePlannerProvider.notifier)
        .addPoint(
          GeoPoint(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
          ),
        );
  }

  Future<void> _insertWaypoint(LatLng coordinates) async {
    final planner = ref.read(routePlannerProvider);
    final candidate = GeoPoint(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );

    if (planner.geometry.length >= 2) {
      var toleranceMeters = 60.0;
      final controller = _mapController;
      if (controller != null) {
        try {
          final metersPerPixel = await controller.getMetersPerPixelAtLatitude(
            candidate.latitude,
          );
          toleranceMeters = (metersPerPixel * 28).clamp(12.0, 80.0).toDouble();
        } on Object {
          // Keep the conservative geographic fallback when projection data is
          // temporarily unavailable.
        }
      }

      if (!mounted) {
        return;
      }

      final distance = distanceToPolylineMeters(candidate, planner.geometry);
      if (distance > toleranceMeters) {
        unawaited(HapticFeedback.warningNotification());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).routePressTooFar),
          ),
        );
        return;
      }
    }

    if (mounted) {
      setState(() {
        _selectedWaypointIndex = null;
        _routeSelected = true;
      });
    }
    unawaited(HapticFeedback.selectionClick());
    ref.read(routePlannerProvider.notifier).insertPointNearRoute(candidate);
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
    unawaited(
      _traceMode
          ? HapticFeedback.selectionClick()
          : HapticFeedback.lightImpact(),
    );
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
    unawaited(HapticFeedback.selectionClick());
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
    final controller = _mapController;
    if (controller == null || screenPoints.length < 2 || _traceProcessing) {
      return;
    }

    final sampled = sampleEvenly(screenPoints, maxItems: 56);
    if (sampled.length < 2) {
      return;
    }

    setState(() => _traceProcessing = true);
    try {
      final geoPoints = <GeoPoint>[];
      for (final offset in sampled) {
        final coordinates = await controller.toLatLng(
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

      final accepted = ref
          .read(routePlannerProvider.notifier)
          .addTrace(geoPoints);
      if (!accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).traceTooShort)),
        );
        return;
      }

      setState(() {
        _routeSelected = true;
        _selectedWaypointIndex = null;
      });
      unawaited(HapticFeedback.mediumImpact());
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).traceFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _traceProcessing = false);
      }
    }
  }

  void _undo() {
    if (_selectedWaypointIndex != null && mounted) {
      setState(() => _selectedWaypointIndex = null);
    }
    ref.read(routePlannerProvider.notifier).undo();
  }

  void _redo() {
    if (_selectedWaypointIndex != null && mounted) {
      setState(() => _selectedWaypointIndex = null);
    }
    ref.read(routePlannerProvider.notifier).redo();
  }

  void _clearRoute() {
    if (mounted) {
      setState(() {
        _selectedWaypointIndex = null;
        _routeSelected = false;
      });
    }
    ref.read(routePlannerProvider.notifier).clear();
  }

  void _removeSelectedWaypoint() {
    final index = _selectedWaypointIndex;
    if (index == null) {
      return;
    }
    setState(() => _selectedWaypointIndex = null);
    ref.read(routePlannerProvider.notifier).removePoint(index);
  }

  void _onCircleTapped(Circle circle) {
    final kind = circle.data?['kind'];
    if (kind == 'midpoint') {
      if (mounted && !_routeSelected) {
        setState(() => _routeSelected = true);
        unawaited(_syncPlannerAnnotations());
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
    unawaited(_syncPlannerAnnotations());
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
    unawaited(_syncPlannerAnnotations());
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
      if (mounted) {
        setState(() {
          _draggingFeature = true;
          _routeSelected = true;
          _selectedWaypointIndex = kind == 'midpoint' ? null : index;
        });
      }
      unawaited(HapticFeedback.selectionClick());
      unawaited(_updateDragPreview(kind, index, current));
      return;
    }

    if (eventType == DragEventType.drag) {
      unawaited(_updateDragPreview(kind, index, current));
      return;
    }

    if (eventType != DragEventType.end) {
      return;
    }

    unawaited(_clearDragPreview());
    unawaited(HapticFeedback.lightImpact());

    if (kind == 'midpoint') {
      final insertedIndex = index + 1;
      if (mounted) {
        setState(() {
          _draggingFeature = false;
          _routeSelected = true;
          _selectedWaypointIndex = insertedIndex;
        });
      }
      ref
          .read(routePlannerProvider.notifier)
          .insertPointAt(
            insertedIndex,
            GeoPoint(latitude: current.latitude, longitude: current.longitude),
          );
      return;
    }

    if (mounted) {
      setState(() {
        _draggingFeature = false;
        _selectedWaypointIndex = index;
        _routeSelected = true;
      });
    }
    ref
        .read(routePlannerProvider.notifier)
        .movePoint(
          index,
          GeoPoint(latitude: current.latitude, longitude: current.longitude),
        );
  }

  Future<void> _updateDragPreview(
    String kind,
    int index,
    LatLng current,
  ) async {
    final controller = _mapController;
    if (controller == null || !_styleReady) {
      return;
    }

    final planner = ref.read(routePlannerProvider);
    final preview = <LatLng>[];
    if (kind == 'midpoint') {
      if (index < 0 || index + 1 >= planner.points.length) {
        return;
      }
      preview
        ..add(_latLng(planner.points[index]))
        ..add(current)
        ..add(_latLng(planner.points[index + 1]));
    } else {
      if (index < 0 || index >= planner.points.length) {
        return;
      }
      if (index > 0) {
        preview.add(_latLng(planner.points[index - 1]));
      }
      preview.add(current);
      if (index + 1 < planner.points.length) {
        preview.add(_latLng(planner.points[index + 1]));
      }
    }

    if (preview.length < 2) {
      return;
    }

    final options = LineOptions(
      geometry: preview,
      lineColor: '#1976D2',
      lineWidth: 4.5,
      lineOpacity: 0.82,
      lineJoin: 'round',
    );
    final existing = _dragPreviewLine;
    if (existing != null && controller.lines.contains(existing)) {
      await controller.updateLine(existing, options);
      return;
    }

    _dragPreviewLine = await controller.addLine(options, <String, dynamic>{
      'kind': 'dragPreview',
    });
  }

  Future<void> _clearDragPreview() async {
    final controller = _mapController;
    final preview = _dragPreviewLine;
    _dragPreviewLine = null;
    if (controller != null &&
        preview != null &&
        controller.lines.contains(preview)) {
      await controller.removeLine(preview);
    }
  }

  LatLng _latLng(GeoPoint point) => LatLng(point.latitude, point.longitude);

  Future<void> _importGpx() async {
    final strings = AppLocalizations.of(context);
    final gpxService = ref.read(gpxServiceProvider);
    final plannerController = ref.read(routePlannerProvider.notifier);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['gpx'],
      );
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      final xml = utf8.decode(bytes);
      final document = await gpxService.parse(xml);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedWaypointIndex = null;
        _routeSelected = false;
      });
      plannerController.importGpx(document);
      await _syncPlannerAnnotations();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.gpxImported)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.gpxImportError)));
      }
    }
  }

  Future<void> _shareCurrentGpx() async {
    final strings = AppLocalizations.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    try {
      final planner = ref.read(routePlannerProvider);
      if (!planner.canSave) {
        return;
      }

      final name = planner.importedName?.trim().isNotEmpty == true
          ? planner.importedName!.trim()
          : 'TrailPath route';
      final document = ref.read(routePlannerProvider.notifier).exportGpx(name);
      final xml = await ref.read(gpxServiceProvider).export(document);
      final fileName = _safeGpxFileName(name);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(xml)),
              mimeType: 'application/gpx+xml',
            ),
          ],
          fileNameOverrides: [fileName],
          title: name,
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.gpxExportError)));
      }
    }
  }

  Future<void> _syncPlannerAnnotations() async {
    _annotationSyncQueued = true;
    if (_annotationSyncRunning) {
      return;
    }

    _annotationSyncRunning = true;
    try {
      while (_annotationSyncQueued && mounted) {
        _annotationSyncQueued = false;
        await _performPlannerAnnotationSync();
      }
    } finally {
      _annotationSyncRunning = false;
    }
  }

  Future<void> _performPlannerAnnotationSync() async {
    if (_runningWidgetTest || !_styleReady) {
      return;
    }

    final controller = _mapController;
    if (controller == null || controller.isDisposed) {
      return;
    }

    final planner = ref.read(routePlannerProvider);
    final displayGeometry = simplifyPolylineForDisplay(
      planner.geometry,
      toleranceMeters: 1.5,
      maxPoints: 2200,
    );
    final routeGeometry = displayGeometry.map(_latLng).toList(growable: false);
    final waypoints = planner.points.map(_latLng).toList(growable: false);

    final routeOptions = routeGeometry.length >= 2
        ? <LineOptions>[
            LineOptions(
              geometry: routeGeometry,
              lineColor: _routeSelected ? '#1976D2' : '#FFFFFF',
              lineWidth: _routeSelected ? 10.0 : 8.0,
              lineOpacity: _routeSelected ? 0.82 : 0.88,
              lineJoin: 'round',
            ),
            LineOptions(
              geometry: routeGeometry,
              lineColor: '#21633C',
              lineWidth: 5.0,
              lineOpacity: 0.98,
              lineJoin: 'round',
            ),
          ]
        : const <LineOptions>[];

    final routeLinesCurrent =
        _routeLines.length == routeOptions.length &&
        _routeLines.every(controller.lines.contains);
    if (routeLinesCurrent) {
      for (var index = 0; index < _routeLines.length; index++) {
        await controller.updateLine(_routeLines[index], routeOptions[index]);
      }
    } else {
      final stale = _routeLines
          .where(controller.lines.contains)
          .toList(growable: false);
      if (stale.isNotEmpty) {
        await controller.removeLines(stale);
      }
      _routeLines = routeOptions.isEmpty
          ? const []
          : await controller.addLines(routeOptions, const [
              <String, dynamic>{'kind': 'route', 'role': 'casing'},
              <String, dynamic>{'kind': 'route', 'role': 'route'},
            ]);
    }

    final waypointOptions = <CircleOptions>[
      for (var index = 0; index < waypoints.length; index++)
        CircleOptions(
          geometry: waypoints[index],
          circleRadius: _selectedWaypointIndex == index
              ? 9
              : index == 0 || index == waypoints.length - 1
              ? 7
              : 5.5,
          circleColor: _selectedWaypointIndex == index
              ? '#1976D2'
              : index == 0
              ? '#205B38'
              : index == waypoints.length - 1
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
        _waypointCircles.every(controller.circles.contains);
    if (waypointCirclesCurrent) {
      for (var index = 0; index < _waypointCircles.length; index++) {
        await controller.updateCircle(
          _waypointCircles[index],
          waypointOptions[index],
        );
      }
    } else {
      final stale = _waypointCircles
          .where(controller.circles.contains)
          .toList(growable: false);
      if (stale.isNotEmpty) {
        await controller.removeCircles(stale);
      }
      _waypointCircles = waypointOptions.isEmpty
          ? const []
          : await controller.addCircles(waypointOptions, [
              for (var index = 0; index < waypointOptions.length; index++)
                <String, dynamic>{'kind': 'waypoint', 'waypointIndex': index},
            ]);
    }

    final editHandles = planner.editHandles
        .map(_latLng)
        .toList(growable: false);
    final showHandles =
        _routeSelected &&
        !_draggingFeature &&
        !planner.isRouting &&
        planner.isSnapped &&
        editHandles.length == waypoints.length - 1;
    final midpointOptions = showHandles
        ? <CircleOptions>[
            for (final handle in editHandles)
              CircleOptions(
                geometry: handle,
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
        _midpointCircles.every(controller.circles.contains);
    if (midpointCirclesCurrent) {
      for (var index = 0; index < _midpointCircles.length; index++) {
        await controller.updateCircle(
          _midpointCircles[index],
          midpointOptions[index],
        );
      }
    } else {
      final stale = _midpointCircles
          .where(controller.circles.contains)
          .toList(growable: false);
      if (stale.isNotEmpty) {
        await controller.removeCircles(stale);
      }
      _midpointCircles = midpointOptions.isEmpty
          ? const []
          : await controller.addCircles(midpointOptions, [
              for (var index = 0; index < midpointOptions.length; index++)
                <String, dynamic>{'kind': 'midpoint', 'legIndex': index},
            ]);
    }

    final searchResult = _searchResult;
    if (searchResult == null) {
      final stale = _searchCircle;
      _searchCircle = null;
      if (stale != null && controller.circles.contains(stale)) {
        await controller.removeCircle(stale);
      }
    } else {
      final options = CircleOptions(
        geometry: _latLng(searchResult.point),
        circleRadius: 8,
        circleColor: '#1565C0',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.5,
        draggable: false,
      );
      final current = _searchCircle;
      if (current != null && controller.circles.contains(current)) {
        await controller.updateCircle(current, options);
      } else {
        _searchCircle = await controller.addCircle(options, <String, dynamic>{
          'kind': 'search',
        });
      }
    }
  }

  Future<void> _saveRoute() async {
    final database = ref.read(appDatabaseProvider);
    final plannerController = ref.read(routePlannerProvider.notifier);
    final planner = ref.read(routePlannerProvider);
    if (!planner.canSave) {
      return;
    }

    final strings = AppLocalizations.of(context);
    final nameController = TextEditingController(
      text: planner.importedName?.trim().isNotEmpty == true
          ? planner.importedName!.trim()
          : '${strings.route} ${DateTime.now().day}/${DateTime.now().month}',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.saveRoute),
        content: TextField(
          controller: nameController,
          autofocus: true,
          maxLength: 80,
          decoration: InputDecoration(labelText: strings.routeName),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(nameController.text.trim()),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    nameController.dispose();

    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }

    await database.savePlannedRoute(
      name: name.trim(),
      profile: planner.profile.name,
      waypointsData: planner.points,
      geometryData: planner.elevationProfile.isAvailable
          ? planner.elevationProfile.points
          : planner.geometry,
      distanceMeters: planner.distanceMeters,
      ascentMeters: planner.ascentMeters,
      descentMeters: planner.descentMeters,
      estimatedDuration: planner.estimatedDuration,
    );

    if (!mounted) {
      return;
    }
    plannerController.resetAfterSave();
    await _syncPlannerAnnotations();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.routeSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final planner = ref.watch(routePlannerProvider);

    ref.listen<RoutePlannerState>(routePlannerProvider, (previous, next) {
      if (previous?.geometry != next.geometry ||
          previous?.isRouting != next.isRouting) {
        unawaited(_syncPlannerAnnotations());
      }
    });

    return Stack(
      children: [
        Positioned.fill(
          child: _runningWidgetTest
              ? _MapTestFallback(dark: dark)
              : MapLibreMap(
                  styleString: MapConfig.plannerStyleUrl,
                  initialCameraPosition: const CameraPosition(
                    target: _fallbackCenter,
                    zoom: 6.8,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    controller.onCircleTapped.add(_onCircleTapped);
                    controller.onLineTapped.add(_onLineTapped);
                    controller.onFeatureDrag.add(_onFeatureDrag);
                    final sample = _position;
                    if (sample != null) {
                      unawaited(_focusPosition(sample, zoom: 15.5));
                    }
                  },
                  onStyleLoadedCallback: () {
                    _styleReady = true;
                    unawaited(_syncPlannerAnnotations());
                  },
                  onMapClick: (point, coordinates) {
                    if (!_traceMode) {
                      _addWaypoint(coordinates);
                    }
                  },
                  onMapLongClick: (point, coordinates) {
                    if (!_traceMode) {
                      unawaited(_insertWaypoint(coordinates));
                    }
                  },
                  annotationOrder: const [
                    AnnotationType.line,
                    AnnotationType.circle,
                  ],
                  annotationConsumeTapEvents: const [
                    AnnotationType.line,
                    AnnotationType.circle,
                  ],
                  doubleClickZoomEnabled: false,
                  dragEnabled: true,
                  compassEnabled: true,
                  compassViewPosition: CompassViewPosition.topRight,
                  myLocationEnabled: _permissionGranted,
                  myLocationRenderMode: _permissionGranted
                      ? MyLocationRenderMode.compass
                      : MyLocationRenderMode.normal,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  trackCameraPosition: false,
                  logoEnabled: false,
                  attributionButtonPosition:
                      AttributionButtonPosition.bottomRight,
                ),
        ),
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
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xD91A241E)
                            : const Color(0xEFFFFFFF),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.terrain, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'TrailPath',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _MapActionButton(
                      icon: Icons.draw_rounded,
                      dark: dark,
                      tooltip: strings.traceMode,
                      active: _traceMode,
                      onTap: planner.isRouting ? null : _toggleTraceMode,
                    ),
                    const SizedBox(width: 8),
                    _MapActionButton(
                      icon: Icons.undo_rounded,
                      dark: dark,
                      tooltip: strings.undo,
                      onTap: planner.canUndo ? _undo : null,
                    ),
                    const SizedBox(width: 8),
                    _MapActionButton(
                      icon: Icons.redo_rounded,
                      dark: dark,
                      tooltip: strings.redo,
                      onTap: planner.canRedo ? _redo : null,
                    ),
                    const SizedBox(width: 8),
                    _MapActionButton(
                      icon: _locationBusy
                          ? Icons.hourglass_top_rounded
                          : Icons.my_location,
                      dark: dark,
                      tooltip: strings.centerLocation,
                      onTap: _centerOnUser,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xEB172019)
                        : const Color(0xF5FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => unawaited(_searchPlaces()),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: strings.searchPlace,
                      prefixIcon: const Icon(Icons.search, size: 21),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      suffixIcon: _searchBusy
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: strings.searchPlace,
                              onPressed: _searchPlaces,
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (!_locationServiceEnabled ||
                    (!_permissionGranted && !_locationBusy) ||
                    _locationError != null)
                  _LocationStatusChip(
                    message: !_locationServiceEnabled
                        ? strings.locationServiceOff
                        : _locationError != null
                        ? strings.locationUnavailable
                        : strings.locationPermissionNeeded,
                    dark: dark,
                    onTap: _resolveLocationIssue,
                  ),
                if (_traceMode) ...[
                  const SizedBox(height: 8),
                  _TraceStatusChip(
                    message: _traceProcessing
                        ? strings.traceProcessing
                        : _traceDrawing
                        ? strings.traceDrawing
                        : strings.traceHint,
                    dark: dark,
                    busy: _traceProcessing,
                  ),
                ],
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _PlannerCard(
              strings: strings,
              planner: planner,
              position: _position,
              locationReady:
                  _permissionGranted &&
                  _locationServiceEnabled &&
                  _locationError == null,
              onProfileChanged: (profile) {
                ref.read(routePlannerProvider.notifier).setProfile(profile);
              },
              selectedWaypointIndex: _selectedWaypointIndex,
              routeSelected: _routeSelected,
              draggingFeature: _draggingFeature,
              onRemoveWaypoint: _selectedWaypointIndex == null
                  ? null
                  : _removeSelectedWaypoint,
              onClear: planner.points.isEmpty ? null : _clearRoute,
              onImport: _importGpx,
              onShare: planner.canSave ? _shareCurrentGpx : null,
              onSave: planner.canSave ? _saveRoute : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlannerCard extends StatelessWidget {
  const _PlannerCard({
    required this.strings,
    required this.planner,
    required this.position,
    required this.locationReady,
    required this.onProfileChanged,
    required this.selectedWaypointIndex,
    required this.routeSelected,
    required this.draggingFeature,
    required this.onRemoveWaypoint,
    required this.onClear,
    required this.onImport,
    required this.onShare,
    required this.onSave,
  });

  final AppLocalizations strings;
  final RoutePlannerState planner;
  final PositionSample? position;
  final bool locationReady;
  final ValueChanged<RouteProfile> onProfileChanged;
  final int? selectedWaypointIndex;
  final bool routeSelected;
  final bool draggingFeature;
  final VoidCallback? onRemoveWaypoint;
  final VoidCallback? onClear;
  final VoidCallback onImport;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heading = position?.headingDegrees;
    final accuracy = position?.accuracyMeters;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.createRoute,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${planner.points.length} ${strings.pointsShort}',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'v${MapConfig.appVersion}',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            planner.points.isEmpty
                ? strings.tapMapHint
                : strings.tapMapContinue,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (planner.points.length >= 2) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  routeSelected
                      ? Icons.edit_road_rounded
                      : Icons.gesture_rounded,
                  size: 15,
                  color: routeSelected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    draggingFeature
                        ? strings.routeDragActive
                        : routeSelected
                        ? strings.routeEditActive
                        : strings.routeEditHint,
                    style: TextStyle(
                      color: routeSelected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (selectedWaypointIndex != null) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.fromLTRB(11, 7, 7, 7),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 17,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${strings.waypointSelected} #${selectedWaypointIndex! + 1}',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRemoveWaypoint,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(strings.removeWaypoint),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final profile in RouteProfile.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      selected: planner.profile == profile,
                      label: Text(_profileLabel(strings, profile)),
                      onSelected: (_) => onProfileChanged(profile),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: strings.distance,
                  value: _formatDistance(planner.distanceMeters),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: strings.duration,
                  value: _formatDuration(planner.estimatedDuration),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: strings.waypoints,
                  value: planner.points.length.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RoutingStatus(strings: strings, planner: planner),
          if (planner.points.length >= 2) ...[
            const SizedBox(height: 12),
            _ElevationPanel(strings: strings, planner: planner),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                locationReady ? Icons.gps_fixed : Icons.gps_not_fixed,
                size: 17,
                color: locationReady ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  locationReady
                      ? strings.locationReady
                      : strings.locationWaiting,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (accuracy != null)
                Text(
                  '±${accuracy.round()} m',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (heading != null) ...[
                const SizedBox(width: 9),
                Transform.rotate(
                  angle: heading * 3.141592653589793 / 180,
                  child: Icon(
                    Icons.navigation_rounded,
                    size: 17,
                    color: scheme.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: strings.importGpx,
                onPressed: onImport,
                icon: const Icon(Icons.file_open_outlined),
              ),
              if (planner.points.isNotEmpty)
                IconButton(
                  tooltip: strings.clear,
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              if (planner.canSave)
                IconButton(
                  tooltip: strings.shareGpx,
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              const Spacer(),
              if (planner.canSave)
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(strings.saveRoute),
                )
              else
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(strings.importGpx),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _profileLabel(AppLocalizations strings, RouteProfile profile) {
  return switch (profile) {
    RouteProfile.hiking => strings.profileHiking,
    RouteProfile.trailRunning => strings.profileTrailRun,
    RouteProfile.walking => strings.profileWalking,
    RouteProfile.mountainBike => strings.profileMtb,
    RouteProfile.cycling => strings.profileCycling,
    RouteProfile.dogWalk => strings.profileDogWalk,
  };
}

String _formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _formatDuration(Duration duration) {
  if (duration == Duration.zero) {
    return '--';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) {
    return '$minutes min';
  }
  final minuteText = minutes.toString().padLeft(2, '0');
  return '$hours h $minuteText';
}

class _ElevationPanel extends StatefulWidget {
  const _ElevationPanel({required this.strings, required this.planner});

  final AppLocalizations strings;
  final RoutePlannerState planner;

  @override
  State<_ElevationPanel> createState() => _ElevationPanelState();
}

class _ElevationPanelState extends State<_ElevationPanel> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant _ElevationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sampleCount = widget.planner.elevationProfile.samples.length;
    if (_selectedIndex != null && _selectedIndex! >= sampleCount) {
      _selectedIndex = sampleCount == 0 ? null : sampleCount - 1;
    }
  }

  void _selectAt(double dx, double width) {
    final samples = widget.planner.elevationProfile.samples;
    if (samples.isEmpty || width <= 0) {
      return;
    }
    final normalized = (dx / width).clamp(0.0, 1.0);
    final index = (normalized * (samples.length - 1)).round();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final planner = widget.planner;
    final profile = planner.elevationProfile;

    if (planner.isElevationLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            widget.strings.elevationLoading,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (!profile.isAvailable || profile.samples.length < 2) {
      return Row(
        children: [
          Icon(
            Icons.terrain_outlined,
            size: 17,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.strings.elevationUnavailable,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final selectedIndex = (_selectedIndex ?? 0)
        .clamp(0, profile.samples.length - 1)
        .toInt();
    final selected = profile.samples[selectedIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.strings.elevationProfile,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '+${profile.ascentMeters.round()} m',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '−${profile.descentMeters.round()} m',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _selectAt(details.localPosition.dx, constraints.maxWidth),
                onHorizontalDragStart: (details) =>
                    _selectAt(details.localPosition.dx, constraints.maxWidth),
                onHorizontalDragUpdate: (details) =>
                    _selectAt(details.localPosition.dx, constraints.maxWidth),
                child: SizedBox(
                  height: 88,
                  child: CustomPaint(
                    painter: _ElevationProfilePainter(
                      profile: profile,
                      selectedIndex: _selectedIndex,
                      lineColor: scheme.primary,
                      fillColor: scheme.primary.withValues(alpha: 0.14),
                      guideColor: scheme.onSurfaceVariant.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _ElevationValue(
                label: widget.strings.elevation,
                value: '${selected.point.elevationMeters?.round() ?? 0} m',
              ),
              const SizedBox(width: 16),
              _ElevationValue(
                label: widget.strings.distance,
                value: _formatDistance(selected.distanceMeters),
              ),
              const SizedBox(width: 16),
              _ElevationValue(
                label: widget.strings.grade,
                value:
                    '${selected.gradePercent >= 0 ? '+' : ''}${selected.gradePercent.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElevationValue extends StatelessWidget {
  const _ElevationValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ElevationProfilePainter extends CustomPainter {
  const _ElevationProfilePainter({
    required this.profile,
    required this.selectedIndex,
    required this.lineColor,
    required this.fillColor,
    required this.guideColor,
  });

  final ElevationProfile profile;
  final int? selectedIndex;
  final Color lineColor;
  final Color fillColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final samples = profile.samples;
    if (samples.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final minElevation = profile.minElevationMeters;
    final elevationSpan = (profile.maxElevationMeters - minElevation).abs() < 1
        ? 1.0
        : profile.maxElevationMeters - minElevation;
    final totalDistance = samples.last.distanceMeters <= 0
        ? 1.0
        : samples.last.distanceMeters;

    Offset pointFor(ElevationSample sample) {
      final x = sample.distanceMeters / totalDistance * size.width;
      final normalized =
          (sample.point.elevationMeters! - minElevation) / elevationSpan;
      final y = size.height - (normalized * (size.height - 6)) - 3;
      return Offset(x, y);
    }

    final linePath = Path();
    final first = pointFor(samples.first);
    linePath.moveTo(first.dx, first.dy);
    for (var index = 1; index < samples.length; index++) {
      final point = pointFor(samples[index]);
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < samples.length) {
      final selectedPoint = pointFor(samples[selectedIndex!]);
      canvas.drawLine(
        Offset(selectedPoint.dx, 0),
        Offset(selectedPoint.dx, size.height),
        Paint()
          ..color = guideColor
          ..strokeWidth = 1,
      );
      canvas.drawCircle(selectedPoint, 4.5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ElevationProfilePainter oldDelegate) {
    return oldDelegate.profile != profile ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.guideColor != guideColor;
  }
}

class _RoutingStatus extends StatelessWidget {
  const _RoutingStatus({required this.strings, required this.planner});

  final AppLocalizations strings;
  final RoutePlannerState planner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (icon, label) = planner.points.length < 2
        ? (Icons.alt_route_rounded, strings.routingReady)
        : planner.isRouting
        ? (Icons.sync_rounded, strings.routingCalculating)
        : planner.hasRoutingError
        ? (Icons.cloud_off_rounded, strings.routeUnavailable)
        : planner.isSnapped
        ? (Icons.route_rounded, strings.routeSnapped)
        : (Icons.alt_route_rounded, strings.routeLocalFallback);

    return Semantics(
      liveRegion: planner.isRouting || planner.hasRoutingError,
      label: label,
      child: ExcludeSemantics(
        child: Row(
          children: [
            if (planner.isRouting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 17, color: scheme.primary),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.dark,
    required this.tooltip,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final bool dark;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      enabled: onTap != null,
      selected: active,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: active
              ? Theme.of(context).colorScheme.primaryContainer
              : dark
              ? const Color(0xD91A241E)
              : const Color(0xEFFFFFFF),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Opacity(
              opacity: onTap == null ? 0.38 : 1,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  icon,
                  size: 20,
                  color: active
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TraceStatusChip extends StatelessWidget {
  const _TraceStatusChip({
    required this.message,
    required this.dark,
    required this.busy,
  });

  final String message;
  final bool dark;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: dark ? const Color(0xE6222A24) : const Color(0xF7FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.draw_rounded, size: 17, color: scheme.primary),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationStatusChip extends StatelessWidget {
  const _LocationStatusChip({
    required this.message,
    required this.dark,
    required this.onTap,
  });

  final String message;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: message,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
        color: dark ? const Color(0xE6222A24) : const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_outlined, size: 17),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({required this.points, required this.color});

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
  bool shouldRepaint(covariant _TracePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

class _MapTestFallback extends StatelessWidget {
  const _MapTestFallback({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: dark ? const Color(0xFF17261D) : const Color(0xFFDDE8D9),
      child: const Center(child: Icon(Icons.map_outlined, size: 54)),
    );
  }
}

String _safeGpxFileName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'[^A-Za-z0-9._ -]+'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  return '${cleaned.isEmpty ? 'TrailPath_route' : cleaned}.gpx';
}

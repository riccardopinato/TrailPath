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
  final _routingService = _WebRoutingService();

  MapLibreMapController? _map;
  bool _styleReady = false;
  List<Circle> _circles = const [];
  List<Line> _lines = const [];
  RouteProfile _profile = RouteProfile.hiking;
  List<GeoPoint> _geometry = const [];
  double _distanceMeters = 0;
  Duration _duration = Duration.zero;
  bool _routing = false;
  String? _routingError;
  int _routingGeneration = 0;

  @override
  void dispose() {
    _routingGeneration++;
    _routingService.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _syncMap() async {
    final map = _map;
    if (map == null || !_styleReady || map.isDisposed) return;

    for (final line in _lines) {
      if (map.lines.contains(line)) {
        await map.removeLine(line);
      }
    }
    for (final circle in _circles) {
      if (map.circles.contains(circle)) {
        await map.removeCircle(circle);
      }
    }

    final nextCircles = <Circle>[];
    for (var index = 0; index < _points.length; index++) {
      final point = _points[index];
      nextCircles.add(
        await map.addCircle(
          CircleOptions(
            geometry: LatLng(point.latitude, point.longitude),
            circleRadius: 7,
            circleColor: index == 0 ? '#1565C0' : '#2E7D32',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ),
          <String, dynamic>{'index': index},
        ),
      );
    }

    final nextLines = <Line>[];
    if (_geometry.length >= 2) {
      final geometry = simplifyPolylineForDisplay(
        _geometry,
        toleranceMeters: 1.5,
        maxPoints: 2200,
      ).map((point) => LatLng(point.latitude, point.longitude)).toList(
            growable: false,
          );

      if (geometry.length >= 2) {
        nextLines.add(
          await map.addLine(
            LineOptions(
              geometry: geometry,
              lineColor: '#FFFFFF',
              lineWidth: 8,
              lineOpacity: 0.96,
              lineJoin: 'round',
            ),
          ),
        );
        nextLines.add(
          await map.addLine(
            LineOptions(
              geometry: geometry,
              lineColor: '#2E7D32',
              lineWidth: 5,
              lineOpacity: 0.98,
              lineJoin: 'round',
            ),
          ),
        );
      }
    }

    _circles = nextCircles;
    _lines = nextLines;
  }

  void _addPoint(math.Point<double> _, LatLng latLng) {
    setState(() {
      _points.add(
        GeoPoint(latitude: latLng.latitude, longitude: latLng.longitude),
      );
      _geometry = const [];
      _distanceMeters = 0;
      _duration = Duration.zero;
      _routingError = null;
    });
    unawaited(_syncMap());
    unawaited(_refreshRoute());
  }

  void _undo() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      _geometry = const [];
      _distanceMeters = 0;
      _duration = Duration.zero;
      _routingError = null;
    });
    unawaited(_syncMap());
    unawaited(_refreshRoute());
  }

  void _clear() {
    _routingGeneration++;
    setState(() {
      _points.clear();
      _geometry = const [];
      _distanceMeters = 0;
      _duration = Duration.zero;
      _routing = false;
      _routingError = null;
    });
    unawaited(_syncMap());
  }

  void _setProfile(RouteProfile profile) {
    if (_profile == profile) return;
    setState(() {
      _profile = profile;
      _geometry = const [];
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

      setState(() {
        _points
          ..clear()
          ..addAll(snapped);
        _geometry = plan.geometry;
        _distanceMeters = plan.distanceMeters;
        _duration = plan.estimatedDuration;
        _routing = false;
        _routingError = null;
      });
      await _syncMap();
    } on Object catch (error) {
      if (!mounted || generation != _routingGeneration) return;
      setState(() {
        _routing = false;
        _geometry = const [];
        _distanceMeters = 0;
        _duration = Duration.zero;
        _routingError = _friendlyRoutingError(error);
      });
      await _syncMap();
    }
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
      pointCount: _points.length,
      distanceLabel: _distanceLabel(),
      durationLabel: _durationLabel(),
      profile: _profile,
      isRouting: _routing,
      routingError: _routingError,
      hasSnappedRoute: _geometry.length >= 2 && !_routing,
      onProfileChanged: _setProfile,
      onUndo: _points.isEmpty ? null : _undo,
      onClear: _points.isEmpty ? null : _clear,
    );

    final map = MapLibreMap(
      styleString: MapConfig.plannerStyleUrl,
      initialCameraPosition: const CameraPosition(
        target: LatLng(45.232, 11.750),
        zoom: 11.5,
      ),
      onMapCreated: (controller) => _map = controller,
      onStyleLoadedCallback: () {
        _styleReady = true;
        unawaited(_syncMap());
      },
      onMapClick: _addPoint,
      myLocationEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
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
                SizedBox(width: 360, child: panel),
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
                  constraints: const BoxConstraints(maxHeight: 310),
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
    required this.pointCount,
    required this.distanceLabel,
    required this.durationLabel,
    required this.profile,
    required this.isRouting,
    required this.routingError,
    required this.hasSnappedRoute,
    required this.onProfileChanged,
    required this.onUndo,
    required this.onClear,
  });

  final int pointCount;
  final String distanceLabel;
  final String durationLabel;
  final RouteProfile profile;
  final bool isRouting;
  final String? routingError;
  final bool hasSnappedRoute;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;

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
            'Clicca sulla mappa: TrailPath aggancia i punti alla rete OSM e segue strade, piste ciclabili e sentieri disponibili.',
          ),
          const SizedBox(height: 18),
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
                  onPressed: isRouting ? null : onUndo,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('Pulisci'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'La preview Web usa routing reale. GPS in background, download offline e notifiche restano funzioni da verificare sull’APK Android.',
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

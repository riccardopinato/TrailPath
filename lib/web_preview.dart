import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
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
      title: 'TrailPath Web Preview',
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
  MapLibreMapController? _map;
  bool _styleReady = false;
  List<Circle> _circles = const [];
  List<Line> _lines = const [];
  RouteProfile _profile = RouteProfile.hiking;

  double get _distanceMeters => calculateRouteDistanceMeters(_points);

  @override
  void dispose() {
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
    if (_points.length >= 2) {
      final geometry = _points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList(growable: false);
      nextLines.add(
        await map.addLine(
          LineOptions(
            geometry: geometry,
            lineColor: '#FFFFFF',
            lineWidth: 8,
            lineOpacity: 0.95,
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
            lineOpacity: 0.95,
            lineJoin: 'round',
          ),
        ),
      );
    }

    _circles = nextCircles;
    _lines = nextLines;
  }

  void _addPoint(math.Point<double> _, LatLng latLng) {
    setState(() {
      _points.add(
        GeoPoint(latitude: latLng.latitude, longitude: latLng.longitude),
      );
    });
    unawaited(_syncMap());
  }

  void _undo() {
    if (_points.isEmpty) return;
    setState(_points.removeLast);
    unawaited(_syncMap());
  }

  void _clear() {
    setState(_points.clear);
    unawaited(_syncMap());
  }

  String _distanceLabel() {
    final meters = _distanceMeters;
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    final panel = _PlannerPanel(
      pointCount: _points.length,
      distanceLabel: _distanceLabel(),
      profile: _profile,
      onProfileChanged: (value) => setState(() => _profile = value),
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
        title: const Text('TrailPath · Web Preview'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(label: Text('Preview browser')),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                SizedBox(width: 340, child: panel),
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
                  constraints: const BoxConstraints(maxHeight: 260),
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
    required this.profile,
    required this.onProfileChanged,
    required this.onUndo,
    required this.onClear,
  });

  final int pointCount;
  final String distanceLabel;
  final RouteProfile profile;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Pianifica un percorso',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Clicca sulla mappa per aggiungere punti. Questa preview serve a controllare rapidamente UI e interazioni dal browser.',
            style: Theme.of(context).textTheme.bodyMedium,
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
            onSelectionChanged: (selection) =>
                onProfileChanged(selection.first),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUndo,
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
          const Text(
            'GPS in background, mappe offline native e notifiche restano da verificare sull’APK Android/AppLab.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

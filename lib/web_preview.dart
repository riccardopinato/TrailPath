import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
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
  List<Circle> _circles = const [];
  List<Line> _lines = const [];
  RoutePlannerState? _pendingPlanner;
  bool _syncRunning = false;

  @override
  void dispose() {
    _pendingPlanner = null;
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
    for (var index = 0; index < planner.points.length; index++) {
      final point = planner.points[index];
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
    if (planner.geometry.length >= 2) {
      final geometry =
          simplifyPolylineForDisplay(
                planner.geometry,
                toleranceMeters: 1.5,
                maxPoints: 2200,
              )
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false);

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
    ref
        .read(routePlannerProvider.notifier)
        .addPoint(
          GeoPoint(latitude: latLng.latitude, longitude: latLng.longitude),
        );
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
          !identical(previous.geometry, next.geometry)) {
        _scheduleMapSync(next);
      }
    });

    final panel = _PlannerPanel(
      planner: planner,
      distanceLabel: _distanceLabel(planner.distanceMeters),
      durationLabel: _durationLabel(planner.estimatedDuration),
      onProfileChanged: controller.setProfile,
      onUndo: planner.canUndo ? controller.undo : null,
      onRedo: planner.canRedo ? controller.redo : null,
      onClear: planner.points.isEmpty ? null : controller.clear,
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
        _scheduleMapSync(ref.read(routePlannerProvider));
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
                  constraints: const BoxConstraints(maxHeight: 360),
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
    required this.onProfileChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  final RoutePlannerState planner;
  final String distanceLabel;
  final String durationLabel;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
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
            'routing, undo/redo, distanza ed elevazione condividono la stessa '
            'logica applicativa.',
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 14),
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

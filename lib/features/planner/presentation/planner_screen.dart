import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/planner/application/route_planner_controller.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  static const _styleUrl = 'https://demotiles.maplibre.org/style.json';
  static const _fallbackCenter = LatLng(45.232, 11.750);

  MapLibreMapController? _mapController;
  StreamSubscription<PositionSample>? _positionSubscription;
  PositionSample? _position;
  bool _permissionGranted = false;
  bool _locationServiceEnabled = true;
  bool _locationBusy = true;
  bool _styleReady = false;
  String? _locationError;

  LocationEngine get _locationEngine => ref.read(locationEngineProvider);

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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (_runningWidgetTest) {
      if (mounted) {
        setState(() => _locationBusy = false);
      }
      return;
    }

    try {
      final serviceEnabled = await _locationEngine.isServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationServiceEnabled = false;
            _locationBusy = false;
          });
        }
        return;
      }

      var permission = await _locationEngine.hasPermission();
      if (!permission) {
        permission = await _locationEngine.requestPermission();
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

      final current = await _locationEngine.current();
      if (!mounted) {
        return;
      }

      setState(() {
        _permissionGranted = true;
        _locationBusy = false;
        _position = current;
        _locationError = null;
      });

      if (current != null) {
        await _focusPosition(current, zoom: 15.5);
      }

      await _positionSubscription?.cancel();
      _positionSubscription = _locationEngine.watch().listen(
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

  Future<void> _centerOnUser() async {
    if (_locationBusy) {
      return;
    }

    if (!_locationServiceEnabled || !_permissionGranted) {
      await _initializeLocation();
      return;
    }

    var sample = _position;
    sample ??= await _locationEngine.current();
    if (sample != null) {
      if (mounted) {
        setState(() => _position = sample);
      }
      await _focusPosition(sample);
    }
  }

  Future<void> _addWaypoint(LatLng coordinates) async {
    ref.read(routePlannerProvider.notifier).addPoint(
          GeoPoint(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
          ),
        );
    await _syncPlannerAnnotations();
  }

  Future<void> _undo() async {
    ref.read(routePlannerProvider.notifier).undo();
    await _syncPlannerAnnotations();
  }

  Future<void> _redo() async {
    ref.read(routePlannerProvider.notifier).redo();
    await _syncPlannerAnnotations();
  }

  Future<void> _clearRoute() async {
    ref.read(routePlannerProvider.notifier).clear();
    await _syncPlannerAnnotations();
  }

  Future<void> _syncPlannerAnnotations() async {
    if (_runningWidgetTest || !_styleReady) {
      return;
    }

    final controller = _mapController;
    if (controller == null) {
      return;
    }

    final planner = ref.read(routePlannerProvider);
    final geometry = planner.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    await controller.clearLines();
    await controller.clearCircles();

    if (geometry.length >= 2) {
      await controller.addLine(
        LineOptions(
          geometry: geometry,
          lineColor: '#2F6F45',
          lineWidth: 5.5,
          lineOpacity: 0.96,
          lineJoin: 'round',
        ),
      );
    }

    if (geometry.isNotEmpty) {
      await controller.addCircles(
        [
          for (var index = 0; index < geometry.length; index++)
            CircleOptions(
              geometry: geometry[index],
              circleRadius: index == 0 || index == geometry.length - 1 ? 7 : 5,
              circleColor: index == 0
                  ? '#205B38'
                  : index == geometry.length - 1
                      ? '#E86A45'
                      : '#FFFFFF',
              circleStrokeColor: '#2F6F45',
              circleStrokeWidth: 2.5,
            ),
        ],
      );
    }
  }

  Future<void> _saveRoute() async {
    final planner = ref.read(routePlannerProvider);
    if (!planner.canSave) {
      return;
    }

    final strings = AppLocalizations.of(context);
    final nameController = TextEditingController(
      text: '${strings.route} ${DateTime.now().day}/${DateTime.now().month}',
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

    await ref.read(appDatabaseProvider).savePlannedRoute(
          name: name.trim(),
          profile: planner.profile.name,
          points: planner.points
              .map(
                (point) => (
                  latitude: point.latitude,
                  longitude: point.longitude,
                ),
              )
              .toList(growable: false),
          distanceMeters: planner.distanceMeters,
          estimatedDuration: planner.estimatedDuration,
        );

    ref.read(routePlannerProvider.notifier).resetAfterSave();
    await _syncPlannerAnnotations();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.routeSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final planner = ref.watch(routePlannerProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: _runningWidgetTest
              ? _MapTestFallback(dark: dark)
              : MapLibreMap(
                  styleString: _styleUrl,
                  initialCameraPosition: const CameraPosition(
                    target: _fallbackCenter,
                    zoom: 6.8,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
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
                    unawaited(_addWaypoint(coordinates));
                  },
                  compassEnabled: true,
                  compassViewPosition: CompassViewPosition.topRight,
                  myLocationEnabled: _permissionGranted,
                  myLocationRenderMode: _permissionGranted
                      ? MyLocationRenderMode.compass
                      : MyLocationRenderMode.normal,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  trackCameraPosition: true,
                  logoEnabled: false,
                  attributionButtonPosition:
                      AttributionButtonPosition.bottomRight,
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
                  height: 50,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 21),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.searchPlace,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                    onTap: _initializeLocation,
                  ),
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
              onClear: planner.points.isEmpty ? null : _clearRoute,
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
    required this.onClear,
    required this.onSave,
  });

  final AppLocalizations strings;
  final RoutePlannerState planner;
  final PositionSample? position;
  final bool locationReady;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback? onClear;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'v0.3',
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
            planner.points.isEmpty ? strings.tapMapHint : strings.tapMapContinue,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
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
          const SizedBox(height: 13),
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
          if (planner.points.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(strings.clear),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(strings.saveRoute),
                ),
              ],
            ),
          ],
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
    return '${minutes} min';
  }
  final minuteText = minutes.toString().padLeft(2, '0');
  return '$hours h $minuteText';
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
    this.onTap,
  });

  final IconData icon;
  final bool dark;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: dark ? const Color(0xD91A241E) : const Color(0xEFFFFFFF),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.38 : 1,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, size: 20),
            ),
          ),
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
    return Align(
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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';

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

  Future<void> _focusPosition(
    PositionSample sample, {
    double zoom = 16,
  }) async {
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

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
                      icon: Icons.layers_outlined,
                      dark: dark,
                      tooltip: strings.mapLayers,
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
              position: _position,
              locationReady:
                  _permissionGranted && _locationServiceEnabled && _locationError == null,
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
    required this.position,
    required this.locationReady,
  });

  final AppLocalizations strings;
  final PositionSample? position;
  final bool locationReady;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heading = position?.headingDegrees;
    final accuracy = position?.accuracyMeters;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.96),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'v0.2',
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
            strings.tapMapHint,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _Metric(label: strings.distance, value: '0.0 km'),
              ),
              Expanded(
                child: _Metric(label: strings.ascent, value: '+0 m'),
              ),
              Expanded(
                child: _Metric(label: strings.duration, value: '--'),
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
        ],
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
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20),
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
      child: const Center(
        child: Icon(Icons.map_outlined, size: 54),
      ),
    );
  }
}

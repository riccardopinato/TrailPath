import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/infrastructure/maps/outdoor_map_style.dart';
import 'package:trail_path/features/outdoor/application/battery_mode_controller.dart';

class BackToCarScreen extends ConsumerStatefulWidget {
  const BackToCarScreen({
    super.key,
    required this.returnPoint,
  });

  final ReturnPoint returnPoint;

  @override
  ConsumerState<BackToCarScreen> createState() => _BackToCarScreenState();
}

class _BackToCarScreenState extends ConsumerState<BackToCarScreen> {
  MapLibreMapController? _mapController;
  StreamSubscription<PositionSample>? _positionSubscription;
  PositionSample? _position;
  String? _error;
  bool _styleReady = false;
  bool _loading = true;
  Circle? _carCircle;
  Circle? _currentCircle;
  Line? _returnLine;
  Future<void> _mapRenderChain = Future<void>.value();
  int _renderGeneration = 0;
  DateTime? _lastCameraFollowAt;

  bool get _runningWidgetTest =>
      Platform.environment['FLUTTER_TEST']?.toLowerCase() == 'true';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_initialize);
  }

  @override
  void dispose() {
    _renderGeneration++;
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (_runningWidgetTest) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final engine = ref.read(locationEngineProvider);
      final batteryModeFuture = ref.read(batteryModeProvider.future);
      if (!await engine.isServiceEnabled()) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'location-service';
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
            _loading = false;
            _error = 'permission';
          });
        }
        return;
      }

      final mode = await batteryModeFuture;
      final current = await engine.current();
      if (!mounted) {
        return;
      }

      setState(() {
        _position = current;
        _loading = false;
        _error = null;
      });
      await _draw();

      await _positionSubscription?.cancel();
      _positionSubscription = engine.watch(mode: mode).listen(
        (sample) {
          if (!mounted) {
            return;
          }
          setState(() {
            _position = sample;
            _error = null;
          });
          unawaited(_draw());
        },
        onError: (Object error, StackTrace stackTrace) {
          if (mounted) {
            setState(() => _error = error.toString());
          }
        },
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _draw() {
    final generation = ++_renderGeneration;
    final previous = _mapRenderChain;
    final next = () async {
      try {
        await previous;
      } on Object {
        // Keep the latest GPS render independent from stale map updates.
      }
      if (generation != _renderGeneration) {
        return;
      }
      await _renderReturnPath();
    }();
    _mapRenderChain = next;
    return next;
  }

  Future<void> _renderReturnPath() async {
    if (_runningWidgetTest || !_styleReady) {
      return;
    }

    final controller = _mapController;
    if (controller == null) {
      return;
    }

    final car = widget.returnPoint.point;
    final carOptions = CircleOptions(
      geometry: LatLng(car.latitude, car.longitude),
      circleRadius: 9,
      circleColor: '#D84315',
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2.5,
    );
    final carCircle = _carCircle;
    if (carCircle == null) {
      _carCircle = await controller.addCircle(carOptions);
    } else {
      await controller.updateCircle(carCircle, carOptions);
    }

    final current = _position;
    if (current == null) {
      return;
    }

    final currentOptions = CircleOptions(
      geometry: LatLng(
        current.point.latitude,
        current.point.longitude,
      ),
      circleRadius: 8,
      circleColor: '#1565C0',
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2.5,
    );
    final currentCircle = _currentCircle;
    if (currentCircle == null) {
      _currentCircle = await controller.addCircle(currentOptions);
    } else {
      await controller.updateCircle(currentCircle, currentOptions);
    }

    final returnOptions = LineOptions(
      geometry: [
        LatLng(current.point.latitude, current.point.longitude),
        LatLng(car.latitude, car.longitude),
      ],
      lineColor: '#2F6F45',
      lineWidth: 4,
      lineOpacity: 0.92,
    );
    final returnLine = _returnLine;
    if (returnLine == null) {
      _returnLine = await controller.addLine(returnOptions);
    } else {
      await controller.updateLine(returnLine, returnOptions);
    }

    final now = DateTime.now();
    final lastFollow = _lastCameraFollowAt;
    if (lastFollow == null ||
        now.difference(lastFollow) >= const Duration(milliseconds: 850)) {
      _lastCameraFollowAt = now;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(current.point.latitude, current.point.longitude),
          _cameraZoomForDistance(
            haversineMeters(current.point, car),
          ),
        ),
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  Future<void> _shareCarPosition() async {
    final point = widget.returnPoint.point;
    final lat = point.latitude.toStringAsFixed(6);
    final lon = point.longitude.toStringAsFixed(6);
    await SharePlus.instance.share(
      ShareParams(
        subject: 'TrailPath · Back to Car',
        text:
            'TrailPath · Back to Car\n'
            '$lat, $lon\n'
            'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=17/$lat/$lon',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final first = widget.returnPoint.point;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _runningWidgetTest
                ? const ColoredBox(color: Color(0xFFDDE8D9))
                : MapLibreMap(
                    styleString: MapConfig.styleUrl,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(first.latitude, first.longitude),
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    onStyleLoadedCallback: () {
                      _styleReady = true;
                      _carCircle = null;
                      _currentCircle = null;
                      _returnLine = null;
                      unawaited(OutdoorMapStyle.enhance(controller));
                      unawaited(_draw());
                    },
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    logoEnabled: false,
                    attributionButtonPosition:
                        AttributionButtonPosition.bottomRight,
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Material(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.96),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        strings.backToCar,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.96),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: strings.sharePosition,
                      onPressed: _shareCarPosition,
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
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
              child: _BackToCarPanel(
                strings: strings,
                position: _position,
                target: widget.returnPoint,
                loading: _loading,
                error: _error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackToCarPanel extends StatelessWidget {
  const _BackToCarPanel({
    required this.strings,
    required this.position,
    required this.target,
    required this.loading,
    required this.error,
  });

  final AppLocalizations strings;
  final PositionSample? position;
  final ReturnPoint target;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = position;
    final distance = current == null
        ? null
        : haversineMeters(current.point, target.point);
    final bearing = current == null
        ? null
        : bearingDegrees(current.point, target.point);
    final relativeBearing = bearing == null
        ? null
        : normalizeDegrees(bearing - (current?.headingDegrees ?? 0));

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
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Transform.rotate(
                  angle: (relativeBearing ?? 0) * 3.141592653589793 / 180,
                  child: Icon(
                    Icons.navigation_rounded,
                    size: 30,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      distance == null
                          ? strings.waitingForGps
                          : _formatDistance(distance),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bearing == null
                          ? strings.distanceToCar
                          : '${strings.direction} · '
                              '${_cardinalDirection(bearing)} '
                              '${bearing.round()}°',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error == 'permission'
                  ? strings.locationPermissionNeeded
                  : error == 'location-service'
                      ? strings.locationServiceOff
                      : error!,
              style: TextStyle(
                color: scheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

double _cameraZoomForDistance(double meters) {
  if (meters < 250) {
    return 16;
  }
  if (meters < 1000) {
    return 14.5;
  }
  if (meters < 5000) {
    return 12.5;
  }
  return 10.5;
}

String _formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _cardinalDirection(double bearing) {
  const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final normalized = normalizeDegrees(bearing);
  final index = ((normalized + 22.5) / 45).floor() % labels.length;
  return labels[index];
}

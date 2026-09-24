import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/navigation/application/active_navigation_controller.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({
    super.key,
    required this.routeName,
    required this.route,
  });

  final String routeName;
  final RoutePlan route;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  MapLibreMapController? _mapController;
  bool _styleReady = false;
  bool _navigationStarted = false;
  bool _followUser = true;
  bool _drawRunning = false;
  bool _drawQueued = false;
  NavigationEvent? _queuedEvent;
  Line? _routeLine;
  Circle? _currentCircle;
  Line? _offRouteLine;
  ActiveNavigationController? _navigationController;

  bool get _runningWidgetTest =>
      Platform.environment['FLUTTER_TEST']?.toLowerCase() == 'true';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigationStarted) {
      return;
    }
    _navigationStarted = true;
    final languageCode = Localizations.localeOf(context).languageCode;
    final controller = ref.read(activeNavigationProvider.notifier);
    _navigationController = controller;
    Future<void>.microtask(() => controller.start(widget.route, languageCode));
  }

  @override
  void dispose() {
    final controller = _navigationController;
    if (controller != null) {
      unawaited(controller.stop());
    }
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _drawRoute(NavigationEvent? event) async {
    _queuedEvent = event;
    _drawQueued = true;
    if (_drawRunning) {
      return;
    }

    _drawRunning = true;
    try {
      while (_drawQueued && mounted) {
        _drawQueued = false;
        final next = _queuedEvent;
        await _performDrawRoute(next);
      }
    } finally {
      _drawRunning = false;
    }
  }

  Future<void> _performDrawRoute(NavigationEvent? event) async {
    if (_runningWidgetTest || !_styleReady) {
      return;
    }
    final controller = _mapController;
    if (controller == null || controller.isDisposed) {
      return;
    }

    final routeGeometry = simplifyPolylineForDisplay(
      widget.route.geometry,
      toleranceMeters: 1.5,
      maxPoints: 2500,
    ).map((p) => LatLng(p.latitude, p.longitude)).toList(growable: false);

    final currentRouteLine = _routeLine;
    if (routeGeometry.length >= 2 &&
        (currentRouteLine == null ||
            !controller.lines.contains(currentRouteLine))) {
      _routeLine = await controller.addLine(
        LineOptions(
          geometry: routeGeometry,
          lineColor: '#2F6F45',
          lineWidth: 5.5,
          lineOpacity: 0.95,
          lineJoin: 'round',
        ),
        const <String, dynamic>{'kind': 'navigationRoute'},
      );
    }

    final current = event?.currentPoint;
    final nearest = event?.nearestRoutePoint;
    if (current != null) {
      final currentOptions = CircleOptions(
        geometry: LatLng(current.latitude, current.longitude),
        circleRadius: 8,
        circleColor: event?.isOffRoute == true ? '#D84315' : '#1565C0',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.5,
      );
      final marker = _currentCircle;
      if (marker != null && controller.circles.contains(marker)) {
        await controller.updateCircle(marker, currentOptions);
      } else {
        _currentCircle = await controller.addCircle(
          currentOptions,
          const <String, dynamic>{'kind': 'navigationPosition'},
        );
      }

      if (_followUser) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(current.latitude, current.longitude),
            16.5,
          ),
        );
      }
    }

    if (event?.isOffRoute == true && current != null && nearest != null) {
      final connectorOptions = LineOptions(
        geometry: [
          LatLng(current.latitude, current.longitude),
          LatLng(nearest.latitude, nearest.longitude),
        ],
        lineColor: '#D84315',
        lineWidth: 3.5,
        lineOpacity: 0.9,
      );
      final connector = _offRouteLine;
      if (connector != null && controller.lines.contains(connector)) {
        await controller.updateLine(connector, connectorOptions);
      } else {
        _offRouteLine = await controller.addLine(
          connectorOptions,
          const <String, dynamic>{'kind': 'offRouteConnector'},
        );
      }
    } else {
      final connector = _offRouteLine;
      _offRouteLine = null;
      if (connector != null && controller.lines.contains(connector)) {
        await controller.removeLine(connector);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(activeNavigationProvider);
    final event = state.event;
    final first = widget.route.geometry.first;

    ref.listen<ActiveNavigationState>(activeNavigationProvider, (
      previous,
      next,
    ) {
      if (previous?.event != next.event) {
        unawaited(_drawRoute(next.event));
      }
    });

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
                      zoom: 14.5,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    onStyleLoadedCallback: () {
                      _styleReady = true;
                      unawaited(_drawRoute(event));
                    },
                    onMapClick: (point, coordinates) {
                      if (_followUser && mounted) {
                        setState(() => _followUser = false);
                      }
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
                    shape: const CircleBorder(),
                    color: Theme.of(context).colorScheme.surface
                        .withValues(alpha: 0.96),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        widget.routeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    shape: const CircleBorder(),
                    color: Theme.of(context).colorScheme.surface
                        .withValues(alpha: 0.96),
                    child: IconButton(
                      tooltip: strings.centerLocation,
                      onPressed: () {
                        setState(() => _followUser = !_followUser);
                        if (_followUser) {
                          unawaited(_drawRoute(event));
                        }
                      },
                      icon: Icon(
                        _followUser
                            ? Icons.gps_fixed_rounded
                            : Icons.gps_not_fixed_rounded,
                      ),
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
              child: _NavigationPanel(strings: strings, state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({required this.strings, required this.state});

  final AppLocalizations strings;
  final ActiveNavigationState state;

  @override
  Widget build(BuildContext context) {
    final event = state.event;
    final scheme = Theme.of(context).colorScheme;
    final remaining =
        event?.remainingMeters ?? state.route?.distanceMeters ?? 0;
    final progress = event?.progressFraction ?? 0;
    final distanceToRoute = event?.distanceToRouteMeters ?? 0;
    final offRoute = event?.isOffRoute == true;

    final statusText = switch (event?.type) {
      NavigationEventType.offRoute => strings.offRoute,
      NavigationEventType.backOnRoute => strings.backOnRoute,
      NavigationEventType.arrived => strings.arrived,
      _ => strings.navigationActive,
    };

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
              Icon(
                offRoute
                    ? Icons.warning_amber_rounded
                    : Icons.navigation_rounded,
                color: offRoute ? scheme.error : scheme.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'v${MapConfig.appVersion}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _NavMetric(
                  label: strings.remainingDistance,
                  value: _formatDistance(remaining),
                ),
              ),
              Expanded(
                child: _NavMetric(
                  label: strings.routeProgress,
                  value: '${(progress * 100).round()}%',
                ),
              ),
              Expanded(
                child: _NavMetric(
                  label: strings.distanceFromRoute,
                  value: _formatDistance(distanceToRoute),
                ),
              ),
            ],
          ),
          if (offRoute) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.alt_route_rounded, color: scheme.onErrorContainer),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      strings.backToRouteHint,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 10),
            Text(
              state.error!,
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

class _NavMetric extends StatelessWidget {
  const _NavMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/infrastructure/maps/outdoor_map_style.dart';
import 'package:trail_path/features/navigation/application/active_navigation_controller.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key, required this.routeName, required this.route});

  final String routeName;
  final RoutePlan route;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  MapLibreMapController? _mapController;
  bool _styleReady = false;
  bool _navigationStarted = false;
  ActiveNavigationController? _navigationController;
  Line? _routeLine;
  Line? _returnLine;
  Circle? _currentCircle;
  Future<void> _mapRenderChain = Future<void>.value();
  int _renderGeneration = 0;
  DateTime? _lastCameraFollowAt;

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
    Future<void>.microtask(
      () => controller.start(
        widget.route,
        languageCode,
      ),
    );
  }

  @override
  void dispose() {
    _renderGeneration++;
    final controller = _navigationController;
    if (controller != null) {
      unawaited(controller.stop());
    }
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _drawRoute(NavigationEvent? event) {
    final generation = ++_renderGeneration;
    final previous = _mapRenderChain;
    final next = () async {
      try {
        await previous;
      } on Object {
        // Never let an old map update block the latest navigation fix.
      }
      if (generation != _renderGeneration) {
        return;
      }
      await _renderRoute(event);
    }();
    _mapRenderChain = next;
    return next;
  }

  Future<void> _renderRoute(NavigationEvent? event) async {
    if (_runningWidgetTest || !_styleReady) return;
    final controller = _mapController;
    if (controller == null) return;

    _routeLine ??= await controller.addLine(
        LineOptions(
          geometry: widget.route.geometry
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(growable: false),
          lineColor: '#2F6F45',
          lineWidth: 5.5,
          lineOpacity: 0.95,
          lineJoin: 'round',
        ),
      );

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
      final currentCircle = _currentCircle;
      if (currentCircle == null) {
        _currentCircle = await controller.addCircle(currentOptions);
      } else {
        await controller.updateCircle(currentCircle, currentOptions);
      }

      final now = DateTime.now();
      final lastFollow = _lastCameraFollowAt;
      if (lastFollow == null ||
          now.difference(lastFollow) >= const Duration(milliseconds: 850)) {
        _lastCameraFollowAt = now;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(current.latitude, current.longitude),
            16.5,
          ),
          duration: const Duration(milliseconds: 350),
        );
      }
    }

    if (event?.isOffRoute == true && current != null && nearest != null) {
      final returnOptions = LineOptions(
        geometry: [
          LatLng(current.latitude, current.longitude),
          LatLng(nearest.latitude, nearest.longitude),
        ],
        lineColor: '#D84315',
        lineWidth: 3.5,
        lineOpacity: 0.9,
      );
      final returnLine = _returnLine;
      if (returnLine == null) {
        _returnLine = await controller.addLine(returnOptions);
      } else {
        await controller.updateLine(returnLine, returnOptions);
      }
    } else {
      final returnLine = _returnLine;
      if (returnLine != null) {
        await controller.removeLine(returnLine);
        _returnLine = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(activeNavigationProvider);
    final event = state.event;
    final first = widget.route.geometry.first;

    ref.listen<ActiveNavigationState>(
      activeNavigationProvider,
      (previous, next) {
        if (previous?.event != next.event) {
          unawaited(_drawRoute(next.event));
        }
      },
    );

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
                      _routeLine = null;
                      _returnLine = null;
                      _currentCircle = null;
                      unawaited(OutdoorMapStyle.enhance(controller));
                      unawaited(_drawRoute(event));
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
                    color: Theme.of(context)
                        .colorScheme
                        .surface
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
                        color: Theme.of(context)
                            .colorScheme
                            .surface
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
    final remaining = event?.remainingMeters ?? state.route?.distanceMeters ?? 0;
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
                offRoute ? Icons.warning_amber_rounded : Icons.navigation_rounded,
                color: offRoute ? scheme.error : scheme.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              const Text('v0.9.3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
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
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
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

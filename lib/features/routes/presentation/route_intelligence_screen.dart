import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/app_preferences.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/route_intelligence.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/localization/measurement_formatter.dart';
import 'package:trail_path/core/services/service_providers.dart';

class RouteIntelligenceScreen extends ConsumerStatefulWidget {
  const RouteIntelligenceScreen({super.key});

  @override
  ConsumerState<RouteIntelligenceScreen> createState() =>
      _RouteIntelligenceScreenState();
}

class _RouteIntelligenceScreenState
    extends ConsumerState<RouteIntelligenceScreen> {
  double _targetDistance = 10;
  RouteProfile _profile = RouteProfile.hiking;
  bool _busy = false;
  List<RouteCandidate> _circularCandidates = const [];
  List<RouteCandidate> _alternatives = const [];
  String? _selectedRouteId;
  AlternativeRoutePreference _alternativePreference =
      AlternativeRoutePreference.shortest;
  List<OutdoorPoi> _pois = const [];
  List<RouteWeatherSample> _weather = const [];
  RouteSurfaceSummary? _surface;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final routes = ref.watch(savedRoutesProvider);
    final imperial = context.distanceUnits == DistanceUnitPreference.imperial;
    final minimumTarget = imperial ? 2.0 : 3.0;
    final maximumTarget = imperial ? 25.0 : 40.0;
    final targetDistance = _targetDistance
        .clamp(minimumTarget, maximumTarget)
        .toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(strings.routeLab)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _SectionCard(
            title: strings.circularRoute,
            icon: Icons.all_inclusive_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.circularRouteHint,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.formatTargetDistance(targetDistance),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                Slider(
                  value: targetDistance,
                  min: minimumTarget,
                  max: maximumTarget,
                  divisions: (maximumTarget - minimumTarget).round(),
                  label: context.formatTargetDistance(targetDistance),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _targetDistance = value),
                ),
                DropdownButtonFormField<RouteProfile>(
                  initialValue: _profile,
                  decoration: InputDecoration(
                    labelText: strings.defaultActivity,
                  ),
                  items: [
                    for (final profile in RouteProfile.values)
                      DropdownMenuItem(
                        value: profile,
                        child: Text(_profileLabel(strings, profile)),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _profile = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _generateCircular,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(strings.generateRoutes),
                ),
                if (_circularCandidates.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (var i = 0; i < _circularCandidates.length; i++) ...[
                    _CandidateCard(
                      title: '${strings.routeOption} ${i + 1}',
                      candidate: _circularCandidates[i],
                      onSave: () => _saveCandidate(
                        _circularCandidates[i],
                        strings.circularRoute,
                      ),
                    ),
                    if (i != _circularCandidates.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: strings.routeAlternatives,
            icon: Icons.alt_route_rounded,
            child: routes.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (error, stackTrace) =>
                  Text(strings.routeAlternativesUnavailable),
              data: (saved) {
                if (saved.isEmpty) {
                  return Text(strings.noRoutes);
                }
                _selectedRouteId ??= saved.first.id;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue:
                          saved.any((route) => route.id == _selectedRouteId)
                          ? _selectedRouteId
                          : saved.first.id,
                      decoration: InputDecoration(labelText: strings.route),
                      items: [
                        for (final route in saved)
                          DropdownMenuItem(
                            value: route.id,
                            child: Text(
                              route.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _selectedRouteId = value),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AlternativeRoutePreference>(
                      initialValue: _alternativePreference,
                      decoration: InputDecoration(
                        labelText: strings.routeAlternatives,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: AlternativeRoutePreference.shortest,
                          child: Text(strings.shortestRoute),
                        ),
                        DropdownMenuItem(
                          value: AlternativeRoutePreference.leastClimb,
                          child: Text(strings.leastClimb),
                        ),
                        DropdownMenuItem(
                          value: AlternativeRoutePreference.moreTrail,
                          child: Text(strings.moreTrail),
                        ),
                        DropdownMenuItem(
                          value: AlternativeRoutePreference.moreRoad,
                          child: Text(strings.moreRoad),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _alternativePreference = value);
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _generateAlternatives,
                      icon: const Icon(Icons.route_rounded),
                      label: Text(strings.generateAlternatives),
                    ),
                    if (_alternatives.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (var i = 0; i < _alternatives.length; i++) ...[
                        _CandidateCard(
                          title: '${strings.alternative} ${i + 1}',
                          candidate: _alternatives[i],
                          onSave: () => _saveCandidate(
                            _alternatives[i],
                            strings.alternative,
                          ),
                        ),
                        if (i != _alternatives.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: strings.routeContext,
            icon: Icons.explore_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.routeContextHint,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: _busy || _selectedRouteId == null
                      ? null
                      : _analyzeRoute,
                  icon: const Icon(Icons.travel_explore_rounded),
                  label: Text(strings.analyzeRoute),
                ),
                if (_surface != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${strings.surface}: ${_surfaceLabel(strings, _surface!)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
                if (_weather.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    strings.weatherAlongRoute,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final sample in _weather)
                        Chip(
                          avatar: const Icon(Icons.cloud_outlined, size: 17),
                          label: Text(
                            '${context.formatTemperature(sample.temperatureCelsius)} · ${context.formatPrecipitation(sample.precipitationMm)} · ${context.formatSpeed(sample.windKmh)}',
                          ),
                        ),
                    ],
                  ),
                ],
                if (_pois.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    strings.outdoorPois,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  for (final poi in _pois.take(12))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_poiIcon(poi.type)),
                      title: Text(poi.name),
                      subtitle: Text(
                        '${context.formatDistance(poi.distanceFromRouteMeters)} ${strings.fromRoute}',
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateCircular() async {
    final strings = AppLocalizations.of(context);
    final units = context.distanceUnits;
    final minimumTarget = units == DistanceUnitPreference.imperial ? 2.0 : 3.0;
    final maximumTarget = units == DistanceUnitPreference.imperial
        ? 25.0
        : 40.0;
    final displayTarget = _targetDistance
        .clamp(minimumTarget, maximumTarget)
        .toDouble();
    final targetDistanceMeters =
        displayTarget *
        (units == DistanceUnitPreference.imperial ? 1609.344 : 1000.0);

    setState(() {
      _busy = true;
      _error = null;
      _circularCandidates = const [];
    });

    try {
      final location = ref.read(locationEngineProvider);
      var allowed = await location.hasPermission();
      if (!allowed) {
        allowed = await location.requestPermission();
      }
      if (!allowed) {
        throw StateError(strings.locationPermissionNeeded);
      }
      final current = await location.current();
      if (current == null) {
        throw StateError(strings.locationUnavailable);
      }

      final candidates = await ref
          .read(routeIntelligenceEngineProvider)
          .generateCircularRoutes(
            CircularRouteRequest(
              start: current.point,
              targetDistanceMeters: targetDistanceMeters,
              profile: _profile,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _circularCandidates = candidates;
        if (candidates.isEmpty) {
          _error = strings.noRouteCandidates;
        }
      });
    } on Object {
      if (mounted) {
        setState(() => _error = strings.routeGenerationFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _generateAlternatives() async {
    final strings = AppLocalizations.of(context);
    final routeId = _selectedRouteId;
    if (routeId == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _alternatives = const [];
    });

    try {
      final database = ref.read(appDatabaseProvider);
      final route = await database.getSavedRoute(routeId);
      if (route == null) {
        throw StateError('missing-route');
      }
      final plan = database.savedRouteToPlan(route);
      final candidates = await ref
          .read(routeIntelligenceEngineProvider)
          .alternatives(plan, preference: _alternativePreference);
      if (!mounted) {
        return;
      }
      setState(() {
        _alternatives = candidates;
        if (candidates.isEmpty) {
          _error = strings.noRouteCandidates;
        }
      });
    } on Object {
      if (mounted) {
        setState(() => _error = strings.routeGenerationFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _analyzeRoute() async {
    final strings = AppLocalizations.of(context);
    final routeId = _selectedRouteId;
    if (routeId == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _pois = const [];
      _weather = const [];
      _surface = null;
    });

    try {
      final database = ref.read(appDatabaseProvider);
      final saved = await database.getSavedRoute(routeId);
      if (saved == null) {
        throw StateError('missing-route');
      }
      final plan = database.savedRouteToPlan(saved);
      final service = ref.read(outdoorContextServiceProvider);
      final results = await Future.wait<Object>([
        service.poisAlongRoute(plan.geometry),
        service.weatherAlongRoute(plan.geometry),
        service.surfaceSummary(plan.geometry),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _pois = results[0] as List<OutdoorPoi>;
        _weather = results[1] as List<RouteWeatherSample>;
        _surface = results[2] as RouteSurfaceSummary;
      });
    } on Object {
      if (mounted) {
        setState(() => _error = strings.routeContextFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveCandidate(RouteCandidate candidate, String prefix) async {
    final strings = AppLocalizations.of(context);
    final plan = candidate.plan;
    final geometry = plan.geometry;
    if (geometry.length < 2) {
      return;
    }
    final waypoints = plan.snappedWaypoints.length >= 2
        ? plan.snappedWaypoints
        : <GeoPoint>[
            geometry.first,
            pointAlongPolyline(geometry, fraction: 0.33),
            pointAlongPolyline(geometry, fraction: 0.66),
            geometry.last,
          ];

    await ref
        .read(appDatabaseProvider)
        .savePlannedRoute(
          name:
              '$prefix ${DateTime.now().toLocal().toIso8601String().substring(0, 16)}',
          profile: plan.profile.name,
          waypointsData: waypoints,
          geometryData: geometry,
          distanceMeters: plan.distanceMeters,
          ascentMeters: plan.ascentMeters,
          descentMeters: plan.descentMeters,
          estimatedDuration: plan.estimatedDuration,
        );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.routeSaved)));
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.title,
    required this.candidate,
    required this.onSave,
  });

  final String title;
  final RouteCandidate candidate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final plan = candidate.plan;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.formatDistance(plan.distanceMeters)} · ${context.formatElevation(plan.ascentMeters, signed: true)} · ${_duration(plan.estimatedDuration)}',
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: strings.saveRoute,
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
    );
  }
}

IconData _poiIcon(OutdoorPoiType type) {
  return switch (type) {
    OutdoorPoiType.drinkingWater => Icons.water_drop_outlined,
    OutdoorPoiType.shelter => Icons.cabin_outlined,
    OutdoorPoiType.alpineHut => Icons.house_siding_outlined,
    OutdoorPoiType.viewpoint => Icons.visibility_outlined,
    OutdoorPoiType.parking => Icons.local_parking_outlined,
    OutdoorPoiType.toilets => Icons.wc_outlined,
  };
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

String _surfaceLabel(AppLocalizations strings, RouteSurfaceSummary summary) {
  final type = summary.dominant;
  final percentage = (summary.fraction(type) * 100).round();
  final label = switch (type) {
    RouteSurfaceType.paved => strings.surfacePaved,
    RouteSurfaceType.gravel => strings.surfaceGravel,
    RouteSurfaceType.dirt => strings.surfaceDirt,
    RouteSurfaceType.trail => strings.surfaceTrail,
    RouteSurfaceType.unknown => strings.surfaceUnknown,
  };
  return '$label · $percentage%';
}

String _duration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) {
    return '$minutes min';
  }
  return '$hours h ${minutes.toString().padLeft(2, '0')}';
}

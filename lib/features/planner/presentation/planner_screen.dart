import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trail_path/core/config/map_config.dart';
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
  String? _locationError;
  final TextEditingController _searchController = TextEditingController();

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
        _locationServiceEnabled = true;
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

  Future<void> _resolveLocationIssue() async {
    if (_locationBusy) {
      return;
    }

    try {
      if (!_locationServiceEnabled) {
        await _locationEngine.openLocationSettings();
      } else if (!_permissionGranted) {
        await _locationEngine.openAppSettings();
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

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.length < 2 || _searchBusy) {
      return;
    }

    setState(() => _searchBusy = true);
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final results = await ref.read(placeSearchServiceProvider).search(
            query,
            languageCode: languageCode,
          );

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
                      separatorBuilder: (_, __) => const Divider(height: 1),
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

  Future<void> _importGpx() async {
    final strings = AppLocalizations.of(context);
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
      final document = await ref.read(gpxServiceProvider).parse(xml);
      ref.read(routePlannerProvider.notifier).importGpx(document);
      await _syncPlannerAnnotations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.gpxImported)),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.gpxImportError)),
        );
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
      final document =
          ref.read(routePlannerProvider.notifier).exportGpx(name);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.gpxExportError)),
        );
      }
    }
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
    final routeGeometry = planner.geometry
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final waypoints = planner.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    await controller.clearLines();
    await controller.clearCircles();

    if (routeGeometry.length >= 2) {
      await controller.addLine(
        LineOptions(
          geometry: routeGeometry,
          lineColor: '#2F6F45',
          lineWidth: 5.5,
          lineOpacity: 0.96,
          lineJoin: 'round',
        ),
      );
    }

    final searchResult = _searchResult;
    final circles = <CircleOptions>[
      for (var index = 0; index < waypoints.length; index++)
        CircleOptions(
          geometry: waypoints[index],
          circleRadius: index == 0 || index == waypoints.length - 1 ? 7 : 5,
          circleColor: index == 0
              ? '#205B38'
              : index == waypoints.length - 1
                  ? '#E86A45'
                  : '#FFFFFF',
          circleStrokeColor: '#2F6F45',
          circleStrokeWidth: 2.5,
        ),
      if (searchResult != null)
        CircleOptions(
          geometry: LatLng(
            searchResult.point.latitude,
            searchResult.point.longitude,
          ),
          circleRadius: 8,
          circleColor: '#1565C0',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2.5,
        ),
    ];
    if (circles.isNotEmpty) {
      await controller.addCircles(circles);
    }
  }

  Future<void> _saveRoute() async {
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

    await ref.read(appDatabaseProvider).savePlannedRoute(
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

    ref.listen<RoutePlannerState>(
      routePlannerProvider,
      (previous, next) {
        if (previous?.geometry != next.geometry ||
            previous?.isRouting != next.isRouting) {
          unawaited(_syncPlannerAnnotations());
        }
      },
    );

    return Stack(
      children: [
        Positioned.fill(
          child: _runningWidgetTest
              ? _MapTestFallback(dark: dark)
              : MapLibreMap(
                  styleString: MapConfig.styleUrl,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'v0.6.0',
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
          const SizedBox(height: 12),
          _RoutingStatus(
            strings: strings,
            planner: planner,
          ),
          if (planner.points.length >= 2) ...[
            const SizedBox(height: 12),
            _ElevationPanel(
              strings: strings,
              planner: planner,
            ),
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
  const _ElevationPanel({
    required this.strings,
    required this.planner,
  });

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
                      guideColor:
                          scheme.onSurfaceVariant.withValues(alpha: 0.35),
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
                value:
                    '${selected.point.elevationMeters?.round() ?? 0} m',
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
  const _ElevationValue({
    required this.label,
    required this.value,
  });

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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
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
    final elevationSpan =
        (profile.maxElevationMeters - minElevation).abs() < 1
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
      canvas.drawCircle(
        selectedPoint,
        4.5,
        Paint()..color = lineColor,
      );
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
  const _RoutingStatus({
    required this.strings,
    required this.planner,
  });

  final AppLocalizations strings;
  final RoutePlannerState planner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (icon, label) = planner.points.length < 2
        ? (Icons.alt_route_rounded, strings.routingReady)
        : planner.isRouting
            ? (Icons.sync_rounded, strings.routingCalculating)
            : planner.isSnapped
                ? (Icons.route_rounded, strings.routeSnapped)
                : (Icons.cloud_off_rounded, strings.routeLocalFallback);

    return Row(
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


String _safeGpxFileName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'[^A-Za-z0-9._ -]+'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  return '${cleaned.isEmpty ? 'TrailPath_route' : cleaned}.gpx';
}

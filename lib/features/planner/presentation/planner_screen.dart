import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/location/application/location_controller.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with WidgetsBindingObserver {
  static const _mapStyle = 'https://tiles.openfreemap.org/styles/liberty';
  static const _fallbackCamera = CameraPosition(
    target: LatLng(45.25, 10.5),
    zoom: 5.8,
  );

  MapLibreMapController? _mapController;
  PositionSample? _lastPushedSample;
  bool _didInitialCenter = false;

  bool get _supportsInteractiveMap {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationControllerProvider.notifier).retry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final location = ref.watch(locationControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<LocationUiState>(locationControllerProvider, (previous, next) {
      _pushLocationToMap(next);
    });

    return Stack(
      children: [
        Positioned.fill(
          child: _supportsInteractiveMap
              ? MapLibreMap(
                  styleString: _mapStyle,
                  initialCameraPosition: _fallbackCamera,
                  compassEnabled: true,
                  compassViewPosition: CompassViewPosition.topRight,
                  attributionButtonPosition: AttributionButtonPosition.topLeft,
                  logoEnabled: false,
                  myLocationEnabled: location.hasUsableLocation,
                  locationSource: ManualLocationSource(),
                  myLocationRenderMode: MyLocationRenderMode.compass,
                  myLocationTrackingMode: location.isFollowing
                      ? MyLocationTrackingMode.trackingCompass
                      : MyLocationTrackingMode.none,
                  minMaxZoomPreference: const MinMaxZoomPreference(2, 19),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _pushLocationToMap(
                      ref.read(locationControllerProvider),
                      force: true,
                    );
                  },
                  onCameraTrackingDismissed: () {
                    ref
                        .read(locationControllerProvider.notifier)
                        .setFollowing(false);
                  },
                )
              : _DesktopMapFallback(dark: dark),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _BrandPill(dark: dark),
                    const Spacer(),
                    _MapActionButton(
                      icon: Icons.layers_outlined,
                      dark: dark,
                      tooltip: strings.mapLayers,
                    ),
                    const SizedBox(width: 8),
                    _MapActionButton(
                      icon: location.isFollowing
                          ? Icons.gps_fixed
                          : Icons.my_location,
                      dark: dark,
                      tooltip: strings.myLocation,
                      active: location.isFollowing,
                      onPressed: () => _onLocationPressed(location),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SearchBar(strings: strings, dark: dark),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _LocationStatusChip(
                    state: location,
                    strings: strings,
                    onPressed: () => _onLocationStatusPressed(location),
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
            child: _PlannerCard(strings: strings),
          ),
        ),
      ],
    );
  }

  Future<void> _onLocationPressed(LocationUiState location) async {
    final notifier = ref.read(locationControllerProvider.notifier);

    switch (location.status) {
      case LocationUiStatus.ready:
        if (location.sample == null) {
          await notifier.retry();
          return;
        }

        notifier.setFollowing(true);
        await _centerOn(location.sample!, bearing: true);
        return;
      case LocationUiStatus.permissionDenied:
        await notifier.requestAccess();
        return;
      case LocationUiStatus.permissionDeniedForever:
      case LocationUiStatus.serviceDisabled:
        await notifier.openRelevantSettings();
        return;
      case LocationUiStatus.unavailable:
      case LocationUiStatus.checking:
        await notifier.retry();
        return;
    }
  }

  Future<void> _onLocationStatusPressed(LocationUiState location) async {
    final notifier = ref.read(locationControllerProvider.notifier);

    switch (location.status) {
      case LocationUiStatus.permissionDenied:
        await notifier.requestAccess();
        return;
      case LocationUiStatus.permissionDeniedForever:
      case LocationUiStatus.serviceDisabled:
        await notifier.openRelevantSettings();
        return;
      case LocationUiStatus.unavailable:
        await notifier.retry();
        return;
      case LocationUiStatus.ready:
        if (location.sample != null) {
          notifier.setFollowing(true);
          await _centerOn(location.sample!, bearing: true);
        }
        return;
      case LocationUiStatus.checking:
        return;
    }
  }

  Future<void> _pushLocationToMap(
    LocationUiState state, {
    bool force = false,
  }) async {
    final controller = _mapController;
    final sample = state.sample;
    if (controller == null || sample == null || !state.hasUsableLocation) {
      return;
    }

    if (!force && identical(sample, _lastPushedSample)) {
      return;
    }
    _lastPushedSample = sample;

    await controller.updateManualLocation(
      ManualLocationUpdate(
        target: LatLng(sample.point.latitude, sample.point.longitude),
        horizontalAccuracy: sample.accuracyMeters,
        altitude: sample.point.elevationMeters,
        bearing: sample.headingDegrees,
        speed: sample.speedMetersPerSecond,
        timestamp: sample.point.timestamp,
      ),
    );

    if (!_didInitialCenter) {
      _didInitialCenter = true;
      await _centerOn(sample);
    }
  }

  Future<void> _centerOn(
    PositionSample sample, {
    bool bearing = false,
  }) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    await controller.easeCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(sample.point.latitude, sample.point.longitude),
          zoom: 16.5,
          bearing: bearing ? (sample.headingDegrees ?? 0) : 0,
        ),
      ),
      duration: const Duration(milliseconds: 650),
      interpolation: CameraAnimationInterpolation.linear,
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: dark ? const Color(0xE61A241E) : const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
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
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.strings, required this.dark});

  final AppLocalizations strings;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: dark ? const Color(0xF2172019) : const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.09),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationStatusChip extends StatelessWidget {
  const _LocationStatusChip({
    required this.state,
    required this.strings,
    required this.onPressed,
  });

  final LocationUiState state;
  final AppLocalizations strings;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, tone) = switch (state.status) {
      LocationUiStatus.checking => (
          Icons.location_searching,
          strings.gpsChecking,
          scheme.secondary,
        ),
      LocationUiStatus.ready => (
          Icons.gps_fixed,
          state.sample == null
              ? strings.gpsWaiting
              : strings.gpsAccuracy(state.sample!.accuracyMeters),
          scheme.primary,
        ),
      LocationUiStatus.serviceDisabled => (
          Icons.location_disabled,
          strings.gpsDisabled,
          scheme.error,
        ),
      LocationUiStatus.permissionDenied => (
          Icons.location_off_outlined,
          strings.gpsPermissionRequired,
          scheme.error,
        ),
      LocationUiStatus.permissionDeniedForever => (
          Icons.settings_outlined,
          strings.gpsOpenSettings,
          scheme.error,
        ),
      LocationUiStatus.unavailable => (
          Icons.sync_problem_outlined,
          strings.gpsUnavailable,
          scheme.error,
        ),
    };

    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      child: InkWell(
        onTap: state.status == LocationUiStatus.checking ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: tone),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerCard extends StatelessWidget {
  const _PlannerCard({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.map_outlined, size: 17, color: scheme.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.mapPositionReady,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
    this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final bool dark;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: active
            ? scheme.primary
            : dark
            ? const Color(0xE61A241E)
            : const Color(0xF2FFFFFF),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 20,
              color: active ? scheme.onPrimary : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopMapFallback extends StatelessWidget {
  const _DesktopMapFallback({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF17261D), Color(0xFF15241C)]
              : const [Color(0xFFE8F0E3), Color(0xFFD9E6D4)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.map_outlined,
          size: 72,
          color: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}

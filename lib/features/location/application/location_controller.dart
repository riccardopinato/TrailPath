import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';

enum LocationUiStatus {
  checking,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationUiState {
  const LocationUiState({
    required this.status,
    this.sample,
    this.isFollowing = false,
  });

  final LocationUiStatus status;
  final PositionSample? sample;
  final bool isFollowing;

  bool get hasUsableLocation =>
      status == LocationUiStatus.ready && sample != null;

  LocationUiState copyWith({
    LocationUiStatus? status,
    PositionSample? sample,
    bool? isFollowing,
  }) {
    return LocationUiState(
      status: status ?? this.status,
      sample: sample ?? this.sample,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

final locationControllerProvider =
    NotifierProvider<LocationController, LocationUiState>(
      LocationController.new,
    );

class LocationController extends Notifier<LocationUiState> {
  StreamSubscription<PositionSample>? _positionSubscription;
  StreamSubscription<bool>? _serviceSubscription;
  bool _initializing = false;

  LocationEngine get _engine => ref.read(locationEngineProvider);

  @override
  LocationUiState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
      _serviceSubscription?.cancel();
    });

    _serviceSubscription = _engine.serviceStatus().listen(_onServiceChanged);
    scheduleMicrotask(initialize);

    return const LocationUiState(status: LocationUiStatus.checking);
  }

  Future<void> initialize() async {
    if (_initializing) {
      return;
    }
    _initializing = true;

    try {
      final serviceEnabled = await _engine.isServiceEnabled();
      if (!serviceEnabled) {
        await _stopPositionStream();
        state = LocationUiState(
          status: LocationUiStatus.serviceDisabled,
          sample: state.sample,
          isFollowing: false,
        );
        return;
      }

      final permission = await _engine.permissionStatus();
      if (!permission.isGranted) {
        await _stopPositionStream();
        state = LocationUiState(
          status: switch (permission) {
            LocationPermissionState.deniedForever =>
              LocationUiStatus.permissionDeniedForever,
            LocationPermissionState.unavailable =>
              LocationUiStatus.unavailable,
            _ => LocationUiStatus.permissionDenied,
          },
          sample: state.sample,
          isFollowing: false,
        );
        return;
      }

      final current = await _engine.current();
      state = LocationUiState(
        status: LocationUiStatus.ready,
        sample: current ?? state.sample,
        isFollowing: state.isFollowing,
      );
      _startPositionStream();
    } catch (_) {
      await _stopPositionStream();
      state = LocationUiState(
        status: LocationUiStatus.unavailable,
        sample: state.sample,
        isFollowing: false,
      );
    } finally {
      _initializing = false;
    }
  }

  Future<void> requestAccess() async {
    state = LocationUiState(
      status: LocationUiStatus.checking,
      sample: state.sample,
      isFollowing: state.isFollowing,
    );

    try {
      final permission = await _engine.requestPermission();
      if (permission.isGranted) {
        await initialize();
        return;
      }

      state = LocationUiState(
        status: permission == LocationPermissionState.deniedForever
            ? LocationUiStatus.permissionDeniedForever
            : LocationUiStatus.permissionDenied,
        sample: state.sample,
        isFollowing: false,
      );
    } catch (_) {
      state = LocationUiState(
        status: LocationUiStatus.unavailable,
        sample: state.sample,
        isFollowing: false,
      );
    }
  }

  Future<void> openRelevantSettings() async {
    final opened = state.status == LocationUiStatus.serviceDisabled
        ? await _engine.openLocationSettings()
        : await _engine.openAppSettings();

    if (opened) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    await initialize();
  }

  Future<void> retry() => initialize();

  void setFollowing(bool value) {
    state = state.copyWith(isFollowing: value);
  }

  void _onServiceChanged(bool enabled) {
    if (enabled) {
      unawaited(initialize());
      return;
    }

    unawaited(_stopPositionStream());
    state = LocationUiState(
      status: LocationUiStatus.serviceDisabled,
      sample: state.sample,
      isFollowing: false,
    );
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = _engine.watch().listen(
      (sample) {
        state = LocationUiState(
          status: LocationUiStatus.ready,
          sample: sample,
          isFollowing: state.isFollowing,
        );
      },
      onError: (_) {
        state = LocationUiState(
          status: LocationUiStatus.unavailable,
          sample: state.sample,
          isFollowing: false,
        );
      },
    );
  }

  Future<void> _stopPositionStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class GeolocatorTrackRecorder implements TrackRecorder {
  GeolocatorTrackRecorder();

  final StreamController<TrackRecorderSnapshot> _controller =
      StreamController<TrackRecorderSnapshot>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _ticker;

  TrackRecorderStatus _status = TrackRecorderStatus.idle;
  final List<GeoPoint> _points = <GeoPoint>[];
  double _distanceMeters = 0;
  double _ascentMeters = 0;
  Duration _elapsedBase = Duration.zero;
  DateTime? _activeStartedAt;
  double? _currentSpeedMetersPerSecond;
  double? _accuracyMeters;
  BatteryMode _batteryMode = BatteryMode.balanced;
  bool _disposed = false;
  int _session = 0;

  @override
  Stream<TrackRecorderSnapshot> get snapshots => _controller.stream;

  @override
  Future<void> setBatteryMode(BatteryMode mode) async {
    if (_disposed || _batteryMode == mode) {
      return;
    }
    _batteryMode = mode;
    if (_status == TrackRecorderStatus.recording) {
      final session = ++_session;
      final previous = _positionSubscription;
      _positionSubscription = null;
      await previous?.cancel();
      if (_isCurrent(session) && _status == TrackRecorderStatus.recording) {
        await _startPositionStream(session);
      }
    }
  }

  @override
  Future<void> start() async {
    _ensureUsable();
    final session = ++_session;
    await _cancelStreams();
    if (!_isCurrent(session)) {
      return;
    }

    _points.clear();
    _distanceMeters = 0;
    _ascentMeters = 0;
    _elapsedBase = Duration.zero;
    _currentSpeedMetersPerSecond = null;
    _accuracyMeters = null;
    _status = TrackRecorderStatus.recording;
    _activeStartedAt = DateTime.now();
    _emit();
    _startTicker();

    try {
      await _startPositionStream(session);
    } on Object {
      if (_isCurrent(session)) {
        ++_session;
        await _cancelStreams();
        _status = TrackRecorderStatus.idle;
        _activeStartedAt = null;
        _emit();
      }
      rethrow;
    }
  }

  @override
  Future<void> restore(TrackRecorderSnapshot snapshot) async {
    _ensureUsable();
    ++_session;
    await _cancelStreams();
    if (_disposed) {
      return;
    }

    _points
      ..clear()
      ..addAll(snapshot.points);
    _distanceMeters = snapshot.distanceMeters;
    _ascentMeters = snapshot.ascentMeters;
    _elapsedBase = snapshot.elapsed;
    _currentSpeedMetersPerSecond = snapshot.currentSpeedMetersPerSecond;
    _accuracyMeters = snapshot.accuracyMeters;
    _activeStartedAt = null;
    _status = TrackRecorderStatus.paused;
    _emit();
  }

  @override
  Future<void> pause() async {
    if (_disposed || _status != TrackRecorderStatus.recording) {
      return;
    }
    ++_session;
    _captureElapsed();
    _status = TrackRecorderStatus.paused;
    await _cancelStreams();
    _emit();
  }

  @override
  Future<void> resume() async {
    _ensureUsable();
    if (_status != TrackRecorderStatus.paused) {
      return;
    }

    final session = ++_session;
    _status = TrackRecorderStatus.recording;
    _activeStartedAt = DateTime.now();
    _emit();
    _startTicker();

    try {
      await _startPositionStream(session);
    } on Object {
      if (_isCurrent(session)) {
        ++_session;
        _captureElapsed();
        await _cancelStreams();
        _status = TrackRecorderStatus.paused;
        _emit();
      }
      rethrow;
    }
  }

  @override
  Future<TrackRecorderSnapshot> stop() async {
    ++_session;
    if (_status == TrackRecorderStatus.recording) {
      _captureElapsed();
    }
    _status = TrackRecorderStatus.stopping;
    await _cancelStreams();

    final completed = _snapshot(TrackRecorderStatus.completed);
    if (!_controller.isClosed) {
      _controller.add(completed);
    }
    _status = TrackRecorderStatus.idle;
    _activeStartedAt = null;
    return completed;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    ++_session;
    await _cancelStreams();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  Future<void> _startPositionStream(int session) async {
    if (!_isCurrent(session)) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_isCurrent(session)) {
      return;
    }
    if (!serviceEnabled) {
      throw const TrackRecorderException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (!_isCurrent(session)) {
      return;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!_isCurrent(session)) {
      return;
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const TrackRecorderException('Location permission is not granted.');
    }

    final settings = _locationSettings();
    if (!_isCurrent(session)) {
      return;
    }

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        if (_isCurrent(session)) {
          _onPosition(position);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_isCurrent(session) && !_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    );
  }

  LocationSettings _locationSettings() {
    final policy = batteryModePolicy(_batteryMode);
    final accuracy = _accuracy(policy.accuracy);

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: policy.distanceFilterMeters,
        intervalDuration: policy.interval,
        useMSLAltitude: true,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'TrailPath · registrazione attiva',
          notificationText:
              'La traccia GPS continua anche con TrailPath in background.',
          enableWakeLock: policy.keepCpuAwake,
          setOngoing: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.fitness,
        distanceFilter: policy.distanceFilterMeters,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: policy.distanceFilterMeters,
    );
  }

  LocationAccuracy _accuracy(GpsAccuracyPreset preset) {
    return switch (preset) {
      GpsAccuracyPreset.navigation => LocationAccuracy.bestForNavigation,
      GpsAccuracyPreset.high => LocationAccuracy.high,
      GpsAccuracyPreset.medium => LocationAccuracy.medium,
    };
  }

  void _onPosition(Position position) {
    if (_disposed || _status != TrackRecorderStatus.recording) {
      return;
    }

    _accuracyMeters = position.accuracy;
    _currentSpeedMetersPerSecond =
        position.speed.isFinite && position.speed >= 0 ? position.speed : null;

    final policy = batteryModePolicy(_batteryMode);
    if (position.accuracy.isFinite &&
        position.accuracy > policy.maxAcceptedAccuracyMeters) {
      _emit();
      return;
    }

    final next = GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      elevationMeters: position.altitude.isFinite ? position.altitude : null,
      timestamp: position.timestamp,
    );

    if (_points.isNotEmpty) {
      final previous = _points.last;
      final segmentDistance = haversineMeters(previous, next);

      if (segmentDistance < policy.minimumSegmentMeters) {
        _emit();
        return;
      }

      final seconds = next.timestamp != null && previous.timestamp != null
          ? next.timestamp!.difference(previous.timestamp!).inMilliseconds /
              1000
          : null;
      if (seconds != null && seconds > 0 && segmentDistance / seconds > 55) {
        _emit();
        return;
      }

      _distanceMeters += segmentDistance;

      final previousElevation = previous.elevationMeters;
      final currentElevation = next.elevationMeters;
      if (previousElevation != null && currentElevation != null) {
        final delta = currentElevation - previousElevation;
        if (delta >= 2) {
          _ascentMeters += delta;
        }
      }
    }

    _points.add(next);
    _emit();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!_disposed && _status == TrackRecorderStatus.recording) {
          _emit();
        }
      },
    );
  }

  void _captureElapsed() {
    final startedAt = _activeStartedAt;
    if (startedAt != null) {
      _elapsedBase += DateTime.now().difference(startedAt);
    }
    _activeStartedAt = null;
  }

  Duration get _elapsed {
    final startedAt = _activeStartedAt;
    if (_status == TrackRecorderStatus.recording && startedAt != null) {
      return _elapsedBase + DateTime.now().difference(startedAt);
    }
    return _elapsedBase;
  }

  TrackRecorderSnapshot _snapshot([TrackRecorderStatus? status]) {
    return TrackRecorderSnapshot(
      status: status ?? _status,
      points: List<GeoPoint>.unmodifiable(_points),
      distanceMeters: _distanceMeters,
      ascentMeters: _ascentMeters,
      elapsed: _elapsed,
      currentSpeedMetersPerSecond: _currentSpeedMetersPerSecond,
      accuracyMeters: _accuracyMeters,
    );
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_snapshot());
    }
  }

  Future<void> _cancelStreams() async {
    _ticker?.cancel();
    _ticker = null;
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
  }

  bool _isCurrent(int session) => !_disposed && session == _session;

  void _ensureUsable() {
    if (_disposed) {
      throw StateError('Track recorder has been disposed.');
    }
  }
}

class TrackRecorderException implements Exception {
  const TrackRecorderException(this.message);

  final String message;

  @override
  String toString() => 'TrackRecorderException: $message';
}

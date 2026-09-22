import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
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
  List<GeoPoint> _points = const [];
  double _distanceMeters = 0;
  double _ascentMeters = 0;
  Duration _elapsedBase = Duration.zero;
  DateTime? _activeStartedAt;
  double? _currentSpeedMetersPerSecond;
  double? _accuracyMeters;

  @override
  Stream<TrackRecorderSnapshot> get snapshots => _controller.stream;

  @override
  Future<void> start() async {
    await _cancelStreams();
    _points = const [];
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
      await _startPositionStream();
    } on Object {
      await _cancelStreams();
      _status = TrackRecorderStatus.idle;
      _activeStartedAt = null;
      _emit();
      rethrow;
    }
  }

  @override
  Future<void> restore(TrackRecorderSnapshot snapshot) async {
    await _cancelStreams();
    _points = List<GeoPoint>.unmodifiable(snapshot.points);
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
    if (_status != TrackRecorderStatus.recording) {
      return;
    }
    _captureElapsed();
    _status = TrackRecorderStatus.paused;
    await _cancelStreams();
    _emit();
  }

  @override
  Future<void> resume() async {
    if (_status != TrackRecorderStatus.paused) {
      return;
    }
    _status = TrackRecorderStatus.recording;
    _activeStartedAt = DateTime.now();
    _emit();
    _startTicker();
    try {
      await _startPositionStream();
    } on Object {
      _captureElapsed();
      await _cancelStreams();
      _status = TrackRecorderStatus.paused;
      _emit();
      rethrow;
    }
  }

  @override
  Future<TrackRecorderSnapshot> stop() async {
    if (_status == TrackRecorderStatus.recording) {
      _captureElapsed();
    }
    _status = TrackRecorderStatus.stopping;
    await _cancelStreams();
    final completed = _snapshot(TrackRecorderStatus.completed);
    _controller.add(completed);
    _status = TrackRecorderStatus.idle;
    _activeStartedAt = null;
    return completed;
  }

  @override
  Future<void> dispose() async {
    await _cancelStreams();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  Future<void> _startPositionStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const TrackRecorderException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const TrackRecorderException('Location permission is not granted.');
    }

    final settings = _locationSettings();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (Object error, StackTrace stackTrace) {
        if (!_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    );
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 3),
        useMSLAltitude: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'TrailPath · registrazione attiva',
          notificationText:
              'La traccia GPS continua anche con TrailPath in background.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );
  }

  void _onPosition(Position position) {
    if (_status != TrackRecorderStatus.recording) {
      return;
    }

    _accuracyMeters = position.accuracy;
    _currentSpeedMetersPerSecond =
        position.speed.isFinite && position.speed >= 0 ? position.speed : null;

    if (position.accuracy.isFinite && position.accuracy > 40) {
      _emit();
      return;
    }

    final next = GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      elevationMeters:
          position.altitude.isFinite ? position.altitude : null,
      timestamp: position.timestamp,
    );

    if (_points.isNotEmpty) {
      final previous = _points.last;
      final segmentDistance = haversineMeters(previous, next);

      if (segmentDistance < 2) {
        _emit();
        return;
      }

      final seconds = next.timestamp != null && previous.timestamp != null
          ? next.timestamp!.difference(previous.timestamp!).inMilliseconds /
              1000
          : null;
      if (seconds != null &&
          seconds > 0 &&
          segmentDistance / seconds > 55) {
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

    _points = List<GeoPoint>.unmodifiable([..._points, next]);
    _emit();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _emit(),
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
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}

class TrackRecorderException implements Exception {
  const TrackRecorderException(this.message);

  final String message;

  @override
  String toString() => 'TrackRecorderException: $message';
}

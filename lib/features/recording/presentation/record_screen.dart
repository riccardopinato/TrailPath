import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/recording/application/recording_controller.dart';
import 'package:trail_path/infrastructure/maps/outdoor_map_style.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  static const _fallbackCenter = LatLng(45.232, 11.750);

  MapLibreMapController? _mapController;
  bool _styleReady = false;
  Line? _trackLine;
  Circle? _startCircle;
  Circle? _endCircle;
  DateTime? _lastCameraFollowAt;
  Future<void> _mapRenderChain = Future<void>.value();
  int _trackRenderGeneration = 0;

  bool get _runningWidgetTest =>
      Platform.environment['FLUTTER_TEST']?.toLowerCase() == 'true';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(recordingControllerProvider.notifier).checkRecovery(),
    );
  }

  @override
  void dispose() {
    _trackRenderGeneration++;
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _syncTrack(
    TrackRecorderSnapshot snapshot, {
    bool follow = true,
  }) {
    final generation = ++_trackRenderGeneration;
    final previous = _mapRenderChain;
    final next = () async {
      try {
        await previous;
      } on Object {
        // A stale rendering failure must not block the latest GPS snapshot.
      }
      if (generation != _trackRenderGeneration) {
        return;
      }
      await _renderTrack(snapshot, follow: follow);
    }();
    _mapRenderChain = next;
    return next;
  }

  Future<void> _renderTrack(
    TrackRecorderSnapshot snapshot, {
    required bool follow,
  }) async {
    if (_runningWidgetTest || !_styleReady) {
      return;
    }

    final controller = _mapController;
    if (controller == null) {
      return;
    }

    final geometry = snapshot.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    if (geometry.length >= 2) {
      final options = LineOptions(
        geometry: geometry,
        lineColor: '#E86A45',
        lineWidth: 5.5,
        lineOpacity: 0.96,
        lineJoin: 'round',
      );
      final line = _trackLine;
      if (line == null) {
        _trackLine = await controller.addLine(options);
      } else {
        await controller.updateLine(line, options);
      }
    } else {
      final line = _trackLine;
      if (line != null) {
        await controller.removeLine(line);
        _trackLine = null;
      }
    }

    if (geometry.isEmpty) {
      final start = _startCircle;
      final end = _endCircle;
      if (start != null) {
        await controller.removeCircle(start);
        _startCircle = null;
      }
      if (end != null) {
        await controller.removeCircle(end);
        _endCircle = null;
      }
      return;
    }

    final startOptions = CircleOptions(
      geometry: geometry.first,
      circleRadius: 6,
      circleColor: '#2F6F45',
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2.2,
    );
    final start = _startCircle;
    if (start == null) {
      _startCircle = await controller.addCircle(startOptions);
    } else {
      await controller.updateCircle(start, startOptions);
    }

    final endOptions = CircleOptions(
      geometry: geometry.last,
      circleRadius: 7,
      circleColor: '#E86A45',
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2.4,
    );
    final end = _endCircle;
    if (end == null) {
      _endCircle = await controller.addCircle(endOptions);
    } else {
      await controller.updateCircle(end, endOptions);
    }

    if (follow) {
      final now = DateTime.now();
      final lastFollow = _lastCameraFollowAt;
      if (lastFollow == null ||
          now.difference(lastFollow) >= const Duration(milliseconds: 850)) {
        _lastCameraFollowAt = now;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(geometry.last, 16.2),
          duration: const Duration(milliseconds: 350),
        );
      }
    }
  }

  Future<void> _finishRecording() async {
    final strings = AppLocalizations.of(context);
    final recordingController =
        ref.read(recordingControllerProvider.notifier);
    final now = DateTime.now();
    final defaultName =
        '${strings.record} ${now.day}/${now.month} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final controller = TextEditingController(text: defaultName);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.finish),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(labelText: strings.activityName),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || name == null) {
      return;
    }

    final saved = await recordingController.finish(name);

    if (!mounted) {
      return;
    }

    await _syncTrack(
      const TrackRecorderSnapshot(
        status: TrackRecorderStatus.idle,
        points: [],
        distanceMeters: 0,
        elapsed: Duration.zero,
      ),
      follow: false,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? strings.activitySaved : strings.activityTooShort,
        ),
      ),
    );
  }

  Future<void> _discardRecording() async {
    final strings = AppLocalizations.of(context);
    final recordingController =
        ref.read(recordingControllerProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.discard),
        content: Text(strings.recoveredRecordingHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.discard),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await recordingController.discard();
    await _syncTrack(
      const TrackRecorderSnapshot(
        status: TrackRecorderStatus.idle,
        points: [],
        distanceMeters: 0,
        elapsed: Duration.zero,
      ),
      follow: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(recordingControllerProvider);
    final snapshot = state.snapshot;
    final dark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<RecordingState>(
      recordingControllerProvider,
      (previous, next) {
        if (previous?.snapshot.points.length != next.snapshot.points.length ||
            previous?.snapshot.status != next.snapshot.status) {
          unawaited(_syncTrack(next.snapshot));
        }
      },
    );

    return Stack(
      children: [
        Positioned.fill(
          child: _runningWidgetTest
              ? _RecordMapFallback(dark: dark)
              : MapLibreMap(
                  styleString: MapConfig.styleUrl,
                  initialCameraPosition: const CameraPosition(
                    target: _fallbackCenter,
                    zoom: 6.8,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onStyleLoadedCallback: () {
                    _styleReady = true;
                    _trackLine = null;
                    _startCircle = null;
                    _endCircle = null;
                    unawaited(OutdoorMapStyle.enhance(_mapController));
                    unawaited(_syncTrack(snapshot));
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xE61A241E)
                        : const Color(0xF5FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        snapshot.status == TrackRecorderStatus.recording
                            ? Icons.fiber_manual_record_rounded
                            : Icons.route_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        snapshot.status == TrackRecorderStatus.recording
                            ? strings.recording
                            : snapshot.status == TrackRecorderStatus.paused
                                ? strings.paused
                                : strings.record,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xE61A241E)
                        : const Color(0xF5FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'v0.6',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
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
            child: _RecorderPanel(
              strings: strings,
              state: state,
              onProfileChanged:
                  ref.read(recordingControllerProvider.notifier).setProfile,
              onStart: ref.read(recordingControllerProvider.notifier).start,
              onPause: ref.read(recordingControllerProvider.notifier).pause,
              onResume: ref.read(recordingControllerProvider.notifier).resume,
              onFinish: _finishRecording,
              onDiscard: _discardRecording,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecorderPanel extends StatelessWidget {
  const _RecorderPanel({
    required this.strings,
    required this.state,
    required this.onProfileChanged,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    required this.onDiscard,
  });

  final AppLocalizations strings;
  final RecordingState state;
  final ValueChanged<RouteProfile> onProfileChanged;
  final Future<void> Function() onStart;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onFinish;
  final Future<void> Function() onDiscard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final snapshot = state.snapshot;
    final active = state.isActive;

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
          if (state.hasRecoveredDraft) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.restore_rounded,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.recoveredRecording,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.recoveredRecordingHint,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _RecordingMetric(
                  value: _formatElapsed(snapshot.elapsed),
                  label: strings.duration,
                  large: true,
                ),
              ),
              _RecordingMetric(
                value: _formatDistance(snapshot.distanceMeters),
                label: strings.distance,
              ),
              const SizedBox(width: 18),
              _RecordingMetric(
                value: '+${snapshot.ascentMeters.round()} m',
                label: strings.ascent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RecordingMetric(
                  value: _formatPace(snapshot),
                  label: strings.currentPace,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _RecordingMetric(
                  value: snapshot.accuracyMeters == null
                      ? '--'
                      : '±${snapshot.accuracyMeters!.round()} m',
                  label: strings.gpsAccuracy,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _RecordingMetric(
                  value: snapshot.points.length.toString(),
                  label: strings.pointsShort,
                ),
              ),
            ],
          ),
          if (!active) ...[
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
                        selected: state.profile == profile,
                        label: Text(_profileLabel(strings, profile)),
                        onSelected: (_) => onProfileChanged(profile),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 13),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                state.error!,
                style: TextStyle(
                  color: scheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Row(
            children: [
              if (!active)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.isCheckingRecovery ? null : onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(strings.startRecording),
                  ),
                )
              else ...[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed:
                        snapshot.status == TrackRecorderStatus.recording
                            ? onPause
                            : onResume,
                    icon: Icon(
                      snapshot.status == TrackRecorderStatus.recording
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      snapshot.status == TrackRecorderStatus.recording
                          ? strings.pause
                          : strings.resume,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(strings.finish),
                  ),
                ),
              ],
              if (state.hasRecoveredDraft) ...[
                const SizedBox(width: 9),
                IconButton.filledTonal(
                  tooltip: strings.discard,
                  onPressed: onDiscard,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.backgroundRecording,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
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

class _RecordingMetric extends StatelessWidget {
  const _RecordingMetric({
    required this.value,
    required this.label,
    this.large = false,
  });

  final String value;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: large ? 27 : 17,
            fontWeight: FontWeight.w900,
            letterSpacing: large ? -1 : -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RecordMapFallback extends StatelessWidget {
  const _RecordMapFallback({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: dark ? const Color(0xFF17261D) : const Color(0xFFDDE8D9),
      child: const Center(
        child: Icon(Icons.route_rounded, size: 54),
      ),
    );
  }
}

String _formatElapsed(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String _formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

String _formatPace(TrackRecorderSnapshot snapshot) {
  if (snapshot.distanceMeters < 50 || snapshot.elapsed.inSeconds <= 0) {
    return '--';
  }
  final secondsPerKm =
      snapshot.elapsed.inSeconds / (snapshot.distanceMeters / 1000);
  final minutes = secondsPerKm ~/ 60;
  final seconds = (secondsPerKm % 60).round().clamp(0, 59);
  return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
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

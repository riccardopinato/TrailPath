import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/outdoor/application/battery_mode_controller.dart';
import 'package:trail_path/features/outdoor/presentation/back_to_car_screen.dart';

class OutdoorScreen extends ConsumerStatefulWidget {
  const OutdoorScreen({super.key});

  @override
  ConsumerState<OutdoorScreen> createState() => _OutdoorScreenState();
}

class _OutdoorScreenState extends ConsumerState<OutdoorScreen> {
  late Future<SafetySnapshot> _safetyFuture;
  bool _locationActionBusy = false;

  @override
  void initState() {
    super.initState();
    _safetyFuture = ref.read(safetyServiceProvider).inspect();
  }

  Future<void> _refreshSafety() async {
    final future = ref.read(safetyServiceProvider).inspect();
    setState(() => _safetyFuture = future);
    await future;
  }

  Future<PositionSample?> _currentPosition() async {
    final engine = ref.read(locationEngineProvider);
    if (!await engine.isServiceEnabled()) {
      return null;
    }
    var permission = await engine.hasPermission();
    if (!permission) {
      permission = await engine.requestPermission();
    }
    if (!permission) {
      return null;
    }
    return engine.current();
  }

  Future<void> _saveCarHere() async {
    if (_locationActionBusy) {
      return;
    }
    final strings = AppLocalizations.of(context);
    final database = ref.read(appDatabaseProvider);

    setState(() => _locationActionBusy = true);
    try {
      final current = await _currentPosition();
      if (current == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.locationUnavailable)),
          );
        }
        return;
      }

      await database.saveReturnPoint(
            point: current.point,
            accuracyMeters: current.accuracyMeters,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.carPositionSaved)),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _locationActionBusy = false);
      }
    }
  }

  Future<void> _clearCar() async {
    final strings = AppLocalizations.of(context);
    final database = ref.read(appDatabaseProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.clearCar),
        content: Text(strings.clearCarHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await database.clearReturnPoint();
    }
  }

  Future<void> _shareCurrentPosition() async {
    if (_locationActionBusy) {
      return;
    }
    final strings = AppLocalizations.of(context);

    setState(() => _locationActionBusy = true);
    try {
      final current = await _currentPosition();
      if (current == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.locationUnavailable)),
          );
        }
        return;
      }

      final lat = current.point.latitude.toStringAsFixed(6);
      final lon = current.point.longitude.toStringAsFixed(6);
      await SharePlus.instance.share(
        ShareParams(
          subject: 'TrailPath',
          text:
              '${strings.sharedPositionMessage}\n'
              '$lat, $lon\n'
              'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=17/$lat/$lon',
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.sharePositionError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _locationActionBusy = false);
      }
    }
  }

  Future<void> _openBackToCar(ReturnPoint point) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BackToCarScreen(returnPoint: point),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final modeAsync = ref.watch(batteryModeProvider);
    final returnPointAsync = ref.watch(returnPointProvider);
    final mode = modeAsync.when(
      data: (value) => value,
      loading: () => BatteryMode.balanced,
      error: (error, stackTrace) => BatteryMode.balanced,
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshSafety,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text(
              strings.outdoor,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              strings.outdoorHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _BatteryModeCard(
              strings: strings,
              mode: mode,
              loading: modeAsync.isLoading,
              onChanged: (selected) async {
                final batteryController =
                    ref.read(batteryModeProvider.notifier);
                final recorder = ref.read(trackRecorderProvider);
                final navigation = ref.read(navigationEngineProvider);
                await batteryController.setMode(selected);
                await recorder.setBatteryMode(selected);
                await navigation.setBatteryMode(selected);
              },
            ),
            const SizedBox(height: 14),
            returnPointAsync.when(
              data: (returnPoint) => _BackToCarCard(
                strings: strings,
                returnPoint: returnPoint,
                busy: _locationActionBusy,
                onSave: _saveCarHere,
                onOpen: returnPoint == null
                    ? null
                    : () => _openBackToCar(returnPoint),
                onClear: returnPoint == null ? null : _clearCar,
              ),
              loading: () => const _LoadingCard(),
              error: (error, stackTrace) => _ErrorCard(message: error.toString()),
            ),
            const SizedBox(height: 14),
            FutureBuilder<SafetySnapshot>(
              future: _safetyFuture,
              builder: (context, snapshot) {
                return _SafetyCard(
                  strings: strings,
                  snapshot: snapshot.data,
                  loading: snapshot.connectionState != ConnectionState.done,
                  error: snapshot.error,
                  onRefresh: _refreshSafety,
                );
              },
            ),
            const SizedBox(height: 14),
            _ShareCard(
              strings: strings,
              busy: _locationActionBusy,
              onShare: _shareCurrentPosition,
            ),
          ],
        ),
      ),
    );
  }
}

class _BatteryModeCard extends StatelessWidget {
  const _BatteryModeCard({
    required this.strings,
    required this.mode,
    required this.loading,
    required this.onChanged,
  });

  final AppLocalizations strings;
  final BatteryMode mode;
  final bool loading;
  final ValueChanged<BatteryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _OutdoorCard(
      icon: Icons.battery_saver_rounded,
      title: strings.batteryMode,
      subtitle: _modeHint(strings, mode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<BatteryMode>(
              showSelectedIcon: false,
              segments: [
              ButtonSegment(
                value: BatteryMode.performance,
                icon: const Icon(Icons.speed_rounded),
                label: Text(strings.batteryPerformance),
              ),
              ButtonSegment(
                value: BatteryMode.balanced,
                icon: const Icon(Icons.balance_rounded),
                label: Text(strings.batteryBalanced),
              ),
              ButtonSegment(
                value: BatteryMode.saver,
                icon: const Icon(Icons.eco_outlined),
                label: Text(strings.batterySaver),
              ),
            ],
            selected: {mode},
              onSelectionChanged: loading
                  ? null
                  : (selection) {
                      if (selection.isNotEmpty) {
                        onChanged(selection.first);
                      }
                    },
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(
                Icons.gps_fixed_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _modeTechnicalLabel(strings, mode),
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

class _BackToCarCard extends StatelessWidget {
  const _BackToCarCard({
    required this.strings,
    required this.returnPoint,
    required this.busy,
    required this.onSave,
    required this.onOpen,
    required this.onClear,
  });

  final AppLocalizations strings;
  final ReturnPoint? returnPoint;
  final bool busy;
  final VoidCallback onSave;
  final VoidCallback? onOpen;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final point = returnPoint;

    return _OutdoorCard(
      icon: Icons.local_parking_rounded,
      title: strings.backToCar,
      subtitle: point == null
          ? strings.backToCarHint
          : '${strings.carSavedAt} ${_formatSavedTime(context, point.savedAt)} · '
              '±${point.accuracyMeters.round()} m',
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: busy ? null : onSave,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_location_alt_outlined),
              label: Text(
                point == null ? strings.saveCarHere : strings.updateCarPosition,
              ),
            ),
          ),
          if (point != null) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: strings.openBackToCar,
              onPressed: onOpen,
              icon: const Icon(Icons.navigation_rounded),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: strings.clearCar,
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({
    required this.strings,
    required this.snapshot,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final AppLocalizations strings;
  final SafetySnapshot? snapshot;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final data = snapshot;

    return _OutdoorCard(
      icon: Icons.health_and_safety_outlined,
      title: strings.safetyCheck,
      subtitle: strings.safetyCheckHint,
      trailing: IconButton(
        tooltip: strings.refresh,
        onPressed: loading ? null : onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: loading
          ? const LinearProgressIndicator()
          : error != null
              ? Text(
                  error.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : data == null
                  ? const SizedBox.shrink()
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          icon: Icons.battery_5_bar_rounded,
                          label: data.batteryPercent < 0
                              ? '${strings.battery}: --'
                              : '${strings.battery}: '
                                  '${data.batteryPercent}%',
                          ok: data.batteryPercent < 0 ||
                              data.batteryPercent >= 20,
                        ),
                        _StatusChip(
                          icon: Icons.location_on_outlined,
                          label: strings.locationServices,
                          ok: data.locationServiceEnabled,
                        ),
                        _StatusChip(
                          icon: Icons.admin_panel_settings_outlined,
                          label: strings.gpsPermission,
                          ok: data.hasLocationPermission,
                        ),
                        _StatusChip(
                          icon: Icons.map_outlined,
                          label: strings.offlineMap,
                          ok: data.isOfflineMapAvailable,
                        ),
                        _StatusChip(
                          icon: Icons.battery_saver_outlined,
                          label: strings.systemBatterySaver,
                          ok: !data.isPowerSaveMode,
                          warningWhenFalse: true,
                        ),
                      ],
                    ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.strings,
    required this.busy,
    required this.onShare,
  });

  final AppLocalizations strings;
  final bool busy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return _OutdoorCard(
      icon: Icons.share_location_outlined,
      title: strings.sharePosition,
      subtitle: strings.sharePositionHint,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: busy ? null : onShare,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(strings.sharePosition),
        ),
      ),
    );
  }
}

class _OutdoorCard extends StatelessWidget {
  const _OutdoorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing case final Widget trailing) trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.ok,
    this.warningWhenFalse = false,
  });

  final IconData icon;
  final String label;
  final bool ok;
  final bool warningWhenFalse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = ok
        ? scheme.primaryContainer
        : warningWhenFalse
            ? scheme.tertiaryContainer
            : scheme.errorContainer;
    final foreground = ok
        ? scheme.onPrimaryContainer
        : warningWhenFalse
            ? scheme.onTertiaryContainer
            : scheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_outline_rounded : icon,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

String _modeHint(AppLocalizations strings, BatteryMode mode) {
  return switch (mode) {
    BatteryMode.performance => strings.batteryPerformanceHint,
    BatteryMode.balanced => strings.batteryBalancedHint,
    BatteryMode.saver => strings.batterySaverHint,
  };
}

String _modeTechnicalLabel(AppLocalizations strings, BatteryMode mode) {
  final policy = batteryModePolicy(mode);
  return '${strings.gpsEvery} '
      '${policy.interval.inSeconds}s · '
      '${policy.distanceFilterMeters} m';
}

String _formatSavedTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}';
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
  );
  return '$date $time';
}

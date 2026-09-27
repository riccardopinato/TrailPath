import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/app_preferences.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/outdoor/application/battery_mode_controller.dart';
import 'package:trail_path/features/pro/application/premium_controller.dart';
import 'package:trail_path/features/pro/presentation/pro_paywall.dart';
import 'package:trail_path/features/settings/application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final preferences = ref.watch(settingsControllerProvider);
    final batteryMode = ref.watch(batteryModeProvider);
    final premium = ref.watch(premiumControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: preferences.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (prefs) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _SectionTitle(strings.appearance),
            _SettingsCard(
              child: DropdownButtonFormField<ThemePreference>(
                initialValue: prefs.theme,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: strings.theme,
                ),
                items: [
                  DropdownMenuItem(
                    value: ThemePreference.system,
                    child: Text(strings.systemTheme),
                  ),
                  DropdownMenuItem(
                    value: ThemePreference.light,
                    child: Text(strings.lightTheme),
                  ),
                  DropdownMenuItem(
                    value: ThemePreference.dark,
                    child: Text(strings.darkTheme),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    unawaited(
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setTheme(value),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(strings.routePreferences),
            _SettingsCard(
              child: Column(
                children: [
                  DropdownButtonFormField<RouteProfile>(
                    initialValue: prefs.defaultProfile,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: strings.defaultActivity,
                    ),
                    items: [
                      for (final profile in RouteProfile.values)
                        DropdownMenuItem(
                          value: profile,
                          child: Text(_profileLabel(strings, profile)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        unawaited(
                          ref
                              .read(settingsControllerProvider.notifier)
                              .setDefaultProfile(value),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  DropdownButtonFormField<DefaultMapPreference>(
                    initialValue: prefs.defaultMap,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: strings.defaultMap,
                    ),
                    items: [
                      for (final map in DefaultMapPreference.values)
                        DropdownMenuItem(
                          value: map,
                          child: Text(_mapLabel(strings, map)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        unawaited(
                          ref
                              .read(settingsControllerProvider.notifier)
                              .setDefaultMap(value),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(strings.gpsAndDownloads),
            _SettingsCard(
              child: Column(
                children: [
                  batteryMode.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) => ListTile(
                      leading: const Icon(Icons.gps_off_rounded),
                      title: Text(strings.batteryMode),
                      subtitle: Text(error.toString()),
                    ),
                    data: (mode) => DropdownButtonFormField<BatteryMode>(
                      initialValue: mode,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: strings.batteryMode,
                      ),
                      items: [
                        for (final value in BatteryMode.values)
                          DropdownMenuItem(
                            value: value,
                            child: Text(_batteryLabel(strings, value)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          unawaited(
                            ref
                                .read(batteryModeProvider.notifier)
                                .setMode(value),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.voiceGuidance),
                    subtitle: Text(strings.voiceGuidanceHint),
                    value: prefs.voiceGuidance,
                    onChanged: (value) {
                      unawaited(
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setVoiceGuidance(value),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.wifiOnlyDownloads),
                    subtitle: Text(strings.wifiOnlyDownloadsHint),
                    value: prefs.wifiOnlyDownloads,
                    onChanged: (value) {
                      unawaited(
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setWifiOnlyDownloads(value),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.autoReroute),
                    subtitle: Text(
                      premium.isPro
                          ? strings.autoRerouteHint
                          : strings.autoRerouteProHint,
                    ),
                    value: premium.isPro && prefs.autoReroute,
                    onChanged: (value) {
                      if (!premium.isPro) {
                        unawaited(showTrailPathProPaywall(context, ref));
                        return;
                      }
                      unawaited(
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setAutoReroute(value),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(strings.privacyData),
            _SettingsCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(strings.localFirst),
                subtitle: Text(strings.localFirstHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
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

String _mapLabel(AppLocalizations strings, DefaultMapPreference map) {
  return switch (map) {
    DefaultMapPreference.outdoor => strings.mapOutdoor,
    DefaultMapPreference.street => strings.mapStreet,
    DefaultMapPreference.highContrast => strings.mapHighContrast,
    DefaultMapPreference.satellite => strings.mapSatellite,
    DefaultMapPreference.hybrid => strings.mapHybrid,
  };
}

String _batteryLabel(AppLocalizations strings, BatteryMode mode) {
  return switch (mode) {
    BatteryMode.performance => strings.batteryPerformance,
    BatteryMode.balanced => strings.batteryBalanced,
    BatteryMode.saver => strings.batterySaver,
  };
}

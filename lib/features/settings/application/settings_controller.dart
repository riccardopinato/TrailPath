import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/app_preferences.dart';
import 'package:trail_path/core/domain/models.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppPreferences>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppPreferences> {
  static const _themeKey = 'preference_theme';
  static const _unitsKey = 'preference_units';
  static const _profileKey = 'preference_default_profile';
  static const _mapKey = 'preference_default_map';
  static const _voiceKey = 'preference_voice_guidance';
  static const _wifiKey = 'preference_wifi_only_downloads';

  @override
  Future<AppPreferences> build() async {
    final database = ref.read(appDatabaseProvider);
    final values = await Future.wait<String?>([
      database.getSetting(_themeKey),
      database.getSetting(_unitsKey),
      database.getSetting(_profileKey),
      database.getSetting(_mapKey),
      database.getSetting(_voiceKey),
      database.getSetting(_wifiKey),
    ]);

    return AppPreferences(
      theme: _enumByName(
        ThemePreference.values,
        values[0],
        ThemePreference.system,
      ),
      units: _enumByName(
        DistanceUnitPreference.values,
        values[1],
        DistanceUnitPreference.metric,
      ),
      defaultProfile: _enumByName(
        RouteProfile.values,
        values[2],
        RouteProfile.hiking,
      ),
      defaultMap: _enumByName(
        DefaultMapPreference.values,
        values[3],
        DefaultMapPreference.outdoor,
      ),
      voiceGuidance: _boolValue(values[4], fallback: true),
      wifiOnlyDownloads: _boolValue(values[5], fallback: false),
    );
  }

  Future<void> setTheme(ThemePreference value) =>
      _update(_themeKey, value.name, (p) => p.copyWith(theme: value));

  Future<void> setUnits(DistanceUnitPreference value) =>
      _update(_unitsKey, value.name, (p) => p.copyWith(units: value));

  Future<void> setDefaultProfile(RouteProfile value) =>
      _update(_profileKey, value.name, (p) => p.copyWith(defaultProfile: value));

  Future<void> setDefaultMap(DefaultMapPreference value) =>
      _update(_mapKey, value.name, (p) => p.copyWith(defaultMap: value));

  Future<void> setVoiceGuidance(bool value) =>
      _update(_voiceKey, value.toString(), (p) => p.copyWith(voiceGuidance: value));

  Future<void> setWifiOnlyDownloads(bool value) =>
      _update(_wifiKey, value.toString(), (p) => p.copyWith(wifiOnlyDownloads: value));

  Future<void> _update(
    String key,
    String value,
    AppPreferences Function(AppPreferences current) transform,
  ) async {
    final current = state.value ?? const AppPreferences();
    final next = transform(current);
    state = AsyncData(next);
    try {
      await ref.read(appDatabaseProvider).setSetting(key, value);
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

bool _boolValue(String? value, {required bool fallback}) {
  return switch (value) {
    'true' => true,
    'false' => false,
    _ => fallback,
  };
}
